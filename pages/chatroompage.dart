import 'dart:developer';
import 'dart:io';
import 'package:chatting/model/chatroommodel.dart';
import 'package:chatting/model/messagemodel.dart';
import 'package:chatting/model/usermodel.dart';
import 'package:chatting/pages/audioplayer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';
import 'package:record/record.dart';

class ChatRoomPage extends StatefulWidget {
  final UserModel targetUser;
  final ChatRoomModel chatroom;
  final UserModel userModel;
  final User firebaseUser;

  const ChatRoomPage({
    super.key,
    required this.targetUser,
    required this.chatroom,
    required this.userModel,
    required this.firebaseUser,
  });

  @override
  State<ChatRoomPage> createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends State<ChatRoomPage> {

  bool isRecording=false;
  Future<void> requestPermissions() async {
    var status = await Permission.microphone.status;
    if (!status.isGranted) {
      await Permission.microphone.request();
    }

    status = await Permission.storage.status;
    if (!status.isGranted) {
      await Permission.storage.request();
    }
  }

  final Record _record = Record();
  String? audioFile;
  Future<String?> startRecording() async {
    try {
      if (await _record.hasPermission()) {
        final directory = await getApplicationDocumentsDirectory();
        final filePath = '${directory.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';

        setState(() {
          isRecording = true;
        });

        print('Starting recording at: $filePath');

        await _record.start(
          path: filePath,
          encoder: AudioEncoder.wav,
          bitRate: 128000,
        );
        return filePath;
      } else {
        print('Permissions not granted');
      }
    } catch (e) {
      print('Error starting recording: $e');
    }
    return null;
  }

  Future<String?> stopRecording() async {
    try {
      setState(() {
        isRecording = false;
      });

      print('Stopping recording');
      String? filePath = await _record.stop();

      if (filePath != null) {
        print('Recording saved at: $filePath');
        setState(() {
          audioFile = filePath;
        });
      } else {
        print('Recording failed');
      }

      return filePath;
    } catch (e) {
      print('Error stopping recording: $e');
    }
    return null;
  }



  TextEditingController messageController = TextEditingController();
  File? imageFile;

  void sendMessage() async {
    String message = messageController.text.trim();
    messageController.clear();

    if (message.isNotEmpty || imageFile != null||audioFile !=null) {
      String messageId = Uuid().v1();
      MessageModel newMessage = MessageModel(
        messageId: messageId,
        sender: widget.userModel.uid,
        createdon: DateTime.now(),
        text: message,
        seen: false,
        picture: null,
        audioUrl: null
      );
      if (audioFile != null) {
        print('Uploading audio from: $audioFile');
        File audio = File(audioFile!);
        UploadTask uploadTask = FirebaseStorage.instance
            .ref("audio/${widget.chatroom.chatroomid}/$messageId")
            .putFile(audio);

        TaskSnapshot snapshot = await uploadTask;
        String audioUrl = await snapshot.ref.getDownloadURL();
        newMessage.audioUrl = audioUrl;

        setState(() {
          audioFile = null;
        });
      }

      if (imageFile != null) {
        UploadTask uploadTask = FirebaseStorage.instance
            .ref("chat_images/${widget.chatroom.chatroomid}/$messageId")
            .putFile(imageFile!);

        TaskSnapshot snapshot = await uploadTask;
        String imageUrl = await snapshot.ref.getDownloadURL();
        newMessage.picture = imageUrl;
        setState(() {
          imageFile = null;
        });
      }
      FirebaseFirestore.instance.collection("chatrooms").
      doc(widget.chatroom.chatroomid).
      collection("messages").
      doc(newMessage.messageId).
      set(newMessage.toMap());

      widget.chatroom.lastMessage = message.isNotEmpty? message:"media message";
      FirebaseFirestore.instance
          .collection("chatrooms")
          .doc(widget.chatroom.chatroomid)
          .set(widget.chatroom.toMap());
      log("Message sent");
    }
  }



  void selectImage(ImageSource source) async {
    XFile? pickedFile = await ImagePicker().pickImage(source: source);

    if (pickedFile != null) {
      cropImage(pickedFile);
    }
  }

  void cropImage(XFile file) async {
    CroppedFile? croppedImage = await ImageCropper().cropImage(
      sourcePath: file.path,
      aspectRatio: CropAspectRatio(ratioX: 1, ratioY: 1),
      compressQuality: 20,
    );

    if (croppedImage != null) {
      setState(() {
        imageFile = File(croppedImage.path);
      });
    }
  }

  void showPhotoOptions() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text("Upload a Picture"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                onTap: () {
                  Navigator.of(context).pop();
                  selectImage(ImageSource.gallery);
                },
                leading: Icon(Icons.photo_album),
                title: Text("Select From Gallery"),
              ),
              ListTile(
                onTap: () {
                  Navigator.of(context).pop();
                  selectImage(ImageSource.camera);
                },
                leading: Icon(Icons.camera_alt),
                title: Text("Take a Photo"),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueAccent,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
          color: Colors.white,
        ),
        elevation: 0,
        backgroundColor: Colors.blueAccent,
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.grey[300],
              backgroundImage: NetworkImage(widget.targetUser.profilepic.toString()),
            ),
            SizedBox(width: 10),
            Text(
              widget.targetUser.fullname.toString(),
              style: TextStyle(color: Colors.white, fontSize: 25),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
            ),
            child: Column(
              children: [
                Expanded(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: StreamBuilder(
                      stream: FirebaseFirestore.instance
                          .collection("chatrooms")
                          .doc(widget.chatroom.chatroomid)
                          .collection("messages")
                          .orderBy("createdon", descending: true)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.active) {
                          if (snapshot.hasData) {
                            QuerySnapshot dataSnapshot =
                            snapshot.data as QuerySnapshot;

                            return ListView.builder(
                              reverse: true,
                              itemCount: dataSnapshot.docs.length,
                              itemBuilder: (context, index) {
                                MessageModel currentMessage = MessageModel
                                    .fromMap(dataSnapshot.docs[index].data()
                                as Map<String, dynamic>);
                                return Row(
                                  mainAxisAlignment: (currentMessage.sender ==
                                      widget.userModel.uid)
                                      ? MainAxisAlignment.end
                                      : MainAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                          vertical: 5, horizontal: 5),
                                      margin: EdgeInsets.symmetric(vertical: 2),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(5),
                                        color: (currentMessage.sender ==
                                            widget.userModel.uid)
                                            ? Colors.grey
                                            : Colors.blueAccent,
                                      ),
                                      child: currentMessage.audioUrl != null
                                          ? AudioPlayerWidget(audioUrl: currentMessage.audioUrl!)
                                          : currentMessage.picture != null
                                          ? Image.network(
                                        currentMessage.picture!,
                                        height: 200,
                                        width: 200,
                                      )
                                          : Text(
                                        currentMessage.text ?? '',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            );
                          } else if (snapshot.hasError) {
                            return Center(
                              child: Text(
                                  "An error occurred! Please check your connection."),
                            );
                          } else {
                            return Center(
                              child: Text("Say Hi to your new friend"),
                            );
                          }
                        } else {
                          return Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                      },
                    ),
                  ),
                ),
                Container(
                  color: Colors.grey[200],
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                  child: Row(
                    children: [
                      Flexible(
                        child: TextField(
                          controller: messageController,
                          maxLines: null,
                          decoration: InputDecoration(
                            hintText: "Enter Message",
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          isRecording? stopRecording(): startRecording();

                        },
                        icon: Icon(
                          Icons.mic_rounded,
                          color: isRecording?Colors.grey:Colors.blueAccent,
                        ),
                      ),
                      IconButton(
                        onPressed: showPhotoOptions,
                        icon: Icon(
                          Icons.camera_alt_outlined,
                          color: Colors.blueAccent,
                        ),
                      ),
                      IconButton(
                        onPressed: sendMessage,
                        icon: Icon(
                          Icons.send,
                          color: Colors.blueAccent,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

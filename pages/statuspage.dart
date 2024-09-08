import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:chatting/pages/mystory.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:chatting/model/statusmodel.dart';
import 'package:chatting/model/usermodel.dart';
import 'package:chatting/pages/storyviewpage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:collection/collection.dart';

class StoryPage extends StatefulWidget {
  final UserModel userModel;
  final User firebaseuser;

  const StoryPage({super.key, required this.userModel, required this.firebaseuser});

  @override
  State<StoryPage> createState() => _StaticsPage1State();
}

class _StaticsPage1State extends State<StoryPage> with TickerProviderStateMixin {
  File? imageFile;
  final Uuid uuid = Uuid();

  // Fetch statuses from Firestore
  Stream<List<StatusModel>> getStatuses() {
    return FirebaseFirestore.instance
        .collectionGroup('status') // Fetch statuses from all users
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return StatusModel.fromMap(doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }

  // Select image from source and crop
  void selectImage(ImageSource source) async {
    XFile? pickedFile = await ImagePicker().pickImage(source: source);
    if (pickedFile != null) {
      cropImage(pickedFile);
    }
  }

  // Crop image
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
      uploadStatusToFirebase();
    }
  }

  Future<void> uploadStatusToFirebase() async {
    if (imageFile != null) {
      String statusId = uuid.v1();
      String? userId = widget.userModel.uid;
      String? userName = widget.userModel.fullname;

      StatusModel statusModel = StatusModel(
        senderId: userId,
        userName: userName,
        seen: null,
        picture: null,
        createdon: DateTime.now(),
        statusId: statusId
      );

      UploadTask uploadTask = FirebaseStorage.instance
          .ref('statusdata/$userId$statusId')
          .putFile(imageFile!);

      TaskSnapshot taskSnapshot = await uploadTask;
      String downloadUrl = await taskSnapshot.ref.getDownloadURL();
      statusModel.picture = downloadUrl;

      await FirebaseFirestore.instance
          .collection('storage')
          .doc(userId)
          .collection('status')
          .doc(statusId)
          .set(statusModel.toMap());

      Timer(Duration(hours: 24), () {
        deleteStatus(statusId, userId!);
      });

      setState(() {
        imageFile = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Status uploaded')),
      );
    }
  }

  Future<void> deleteStatus(String statusId, String userId) async {
    try {
      await FirebaseFirestore.instance
          .collection('storage')
          .doc(userId)
          .collection('status')
          .doc(statusId)
          .delete();
      print('Status deleted successfully after 5 minutes');
    } catch (e) {
      print('Error deleting status: $e');
    }
  }

  List<String> viewers = [];


  Future<StatusModel?> getStatusModel(String senderId, String statusId) async {
    try {
      DocumentReference statusRef =
      FirebaseFirestore.instance
          .collection('storage')
          .doc(senderId)
          .collection('status')
          .doc(statusId);

      // Fetch the document snapshot
      DocumentSnapshot snapshot = await statusRef.get();

      if (snapshot.exists) {
        // Convert the snapshot data to a map
        Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;

        // Create and return a StatusModel instance from the map
        return StatusModel.fromMap(data);
      } else {
        print('No status found with id: $statusId');
        print('Fetching status from: ${statusRef.path}');

        return null;
      }
    } catch (e) {
      print('Error fetching status: $e');
      return null;
    }
  }
  Future<void> updateSeenList(String statusOwnerId, String statusId, String currentUserName) async {
    try {
      DocumentReference statusRef = FirebaseFirestore.instance
          .collection('storage')
          .doc(statusOwnerId)
          .collection('status')
          .doc(statusId);

      DocumentSnapshot statusSnapshot = await statusRef.get();
      if (statusSnapshot.exists) {
        List<dynamic> seenBy = statusSnapshot.get('seen') ?? [];
        if (!seenBy.contains(currentUserName)) {
          await statusRef.update({
            'seen': FieldValue.arrayUnion([currentUserName]) // Add the user's name
          });
        }
      }
    } catch (e) {
      print('Error updating seen list: $e');
    }
  }

  void onViewStatus(String statusOwnerId, String statusId) {
    String currentUserName = widget.userModel.fullname ?? '';
    updateSeenList(statusOwnerId, statusId, currentUserName);
  }





  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            automaticallyImplyLeading: false,
            backgroundColor: Colors.blueAccent,
            title: Text("Update",style: TextStyle(color: Colors.white,
            fontWeight: FontWeight.bold,fontSize: 25),)
          ),
          SliverToBoxAdapter(
            child: StreamBuilder<List<StatusModel>>(
              stream: getStatuses(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                var statuses = snapshot.data!;
                var myStatus = statuses.firstWhereOrNull(
                      (status) => status.senderId == widget.userModel.uid,
                );

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 20, top: 15),
                      child: Text(
                        'Status',
                        style: TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                          child: Container(
                            height: 80,
                            decoration: BoxDecoration(
                              color: Colors.grey.withOpacity(0.5),
                              boxShadow: [
                                BoxShadow(
                                  offset: Offset(0, 1),
                                  color: Colors.black12,
                                  spreadRadius: 1,
                                  blurRadius: 5,
                                ),
                              ],
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(0),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.only(bottom: 10),
                                      child: GestureDetector(
                                        onTap: (){
                                          myStatus?.picture != null?
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => Mystory(url: myStatus!.picture.toString(),statusModel: myStatus,
                                              userModel: widget.userModel,firebaseuser: widget.firebaseuser,),
                                            ),
                                          ):{};
                                        },
                                        child: ListTile(
                                          leading: CircleAvatar(
                                            backgroundImage: myStatus?.picture != null
                                                ? NetworkImage(myStatus!.picture!)
                                                : null,
                                            radius: 30,
                                          ),
                                          title: Text(
                                            widget.userModel.fullname.toString(),
                                            style: TextStyle(color: Colors.white,fontSize: 20),
                                          ),
                                          subtitle: Text(
                                            'Your status',
                                            style: TextStyle(color: Colors.white),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 10),
                                  Row(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.only(left: 0, right: 10),
                                        child: Container(
                                          height: 40,
                                          width: 40,
                                          decoration: BoxDecoration(
                                            color: Colors.black12,
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: IconButton(
                                            onPressed: () {
                                              selectImage(ImageSource.camera);
                                            },
                                            icon: Icon(Icons.camera_alt, color: Colors.white),
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.only(left: 0, right: 10),
                                        child: Container(
                                          height: 40,
                                          width: 40,
                                          decoration: BoxDecoration(
                                            color: Colors.black12,
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Icon(Icons.edit, color: Colors.white, size: 20),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 20, top: 15),
                      child: Text(
                        'Recent updates',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: ListView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: statuses.length,
                        itemBuilder: (context, index) {
                          var status = statuses[index];
                          if (status.senderId == widget.userModel.uid) {
                            return Container();
                          }
                          return GestureDetector(
                            onTap: (){
                              onViewStatus(status.senderId.toString(),
                                  status.statusId.toString());
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => StoryViewerPage(
                                    url: status.picture.toString(),
                                    statusModel: status,
                                    userModel: widget.userModel,
                                    firebaseuser: widget.firebaseuser,
                                  ),
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                                  child: Container(
                                    height: 80,
                                    decoration: BoxDecoration(
                                      color: Colors.grey.withOpacity(0.5),
                                      boxShadow: [
                                        BoxShadow(
                                          offset: Offset(0, 1),
                                          color: Colors.black12,
                                          spreadRadius: 1,
                                          blurRadius: 5,
                                        ),
                                      ],
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        backgroundImage: status.picture != null
                                            ? NetworkImage(status.picture!)
                                            : null,
                                        radius: 30,
                                      ),
                                      title: Text(
                                        status.userName!,
                                        style: TextStyle(color: Colors.black87),
                                      ),
                                      subtitle: Text(timeago.format(status.createdon!),),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

import 'dart:developer';
import 'package:chatting/main.dart';
import 'package:chatting/model/chatroommodel.dart';
import 'package:chatting/model/usermodel.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'chatroompage.dart';

class SearchPage extends StatefulWidget {
  final UserModel userModel;
  final User firebaseUser;

  const SearchPage({super.key, required this.userModel, required this.firebaseUser});


  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  TextEditingController searchController =TextEditingController();

  Future<ChatRoomModel?> getChatRoomModel(UserModel targetUser) async {
    ChatRoomModel? chatRoom;

    QuerySnapshot snapshot = await FirebaseFirestore.instance.collection("chatrooms").
    where("participants.${widget.userModel.uid}",isEqualTo: true).
    where("participants.${targetUser.uid}",isEqualTo: true).get();

    if(snapshot.docs.length>0){
      var docData = snapshot.docs[0].data();
      ChatRoomModel existingChatroom = ChatRoomModel.
      fromMap(docData as Map<String,dynamic>);

      chatRoom = existingChatroom;
    }else{
      ChatRoomModel newChatroom = ChatRoomModel(
        chatroomid: uuid.v1(),
        lastMessage: "",
        participants: {
          widget.userModel.uid.toString(): true,
          targetUser.uid.toString(): true,
        }
      );
      await FirebaseFirestore.instance.collection("chatrooms").doc(
        newChatroom.chatroomid).set(newChatroom.toMap());

      chatRoom = newChatroom;

      log("new chatroom created");
    }
    return chatRoom;
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
          color: Colors.white,
        ),
        title: Text("Search",style: TextStyle
          (color: Colors.white,fontWeight: FontWeight.normal,fontSize: 25),),
        backgroundColor: Colors.blueAccent,
      ),
      body: SafeArea(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 20,vertical: 10),
          child: Column(
            children: [
            TextField(
            controller: searchController,
            decoration: InputDecoration(
              labelText: "E-mail Address",
              fillColor: Colors.grey[200],
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide(color: Colors.grey, width: 1.0),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide(color: Colors.grey, width: 1.0),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide(color: Colors.blue, width: 2.0),
              ),
            ),
        ),
              SizedBox(
                height: 20,
              ),
              CupertinoButton(
                color: Colors.blueAccent,
                  child: Text("Search"),
                  onPressed: (){
                  setState(() {

                  });
                  }),

              SizedBox(
                height: 20,
              ),
              StreamBuilder(
                stream: FirebaseFirestore.instance.collection("users").
                where("fullname", isEqualTo: searchController.text).
                where("fullname",isNotEqualTo: widget.userModel.fullname).snapshots(),
                builder: (context,snapshot){
                  if(snapshot.connectionState == ConnectionState.active){
                    if(snapshot.hasData){
                      QuerySnapshot dataSnapshot = snapshot.data as
                      QuerySnapshot;

                      if(dataSnapshot.docs.length > 0){
                        Map<String,dynamic> userMap = dataSnapshot.docs[0].
                        data() as Map<String,dynamic>;

                        UserModel searchedUser = UserModel.fromMap(userMap);

                        return ListTile(
                          onTap: () async {
                            ChatRoomModel? chatRoomModel =
                            await getChatRoomModel(searchedUser);

                            if(chatRoomModel != null){
                              Navigator.of(context).pop();
                              Navigator.of(context).
                              push(MaterialPageRoute(builder: (context)=>ChatRoomPage(
                                targetUser: searchedUser,
                                firebaseUser: widget.firebaseUser,
                                userModel: widget.userModel,
                                chatroom: chatRoomModel,
                              )));
                            }

                          },
                          leading: CircleAvatar(
                            backgroundImage: NetworkImage(searchedUser.profilepic!),
                          ),
                          title: Text(searchedUser.fullname!),
                          subtitle: Text(searchedUser.email!),
                          trailing: Icon(Icons.arrow_forward_ios,color: Colors.grey[400],),
                        );
                      }else{
                        return Text("No results Found!");

                      }
                    }
                    else if(snapshot.hasError){
                      return Text("An error has ocuured!");
                    }
                    else{
                      return Text("No results Found!");
                    }
                  }
                  else{
                    return CircularProgressIndicator();
                  }
                },
              )
            ],
          ),
        ),
      ),
    );
  }
}

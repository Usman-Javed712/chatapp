import 'package:chatting/model/chatroommodel.dart';
import 'package:chatting/model/firebasehelper.dart';
import 'package:chatting/model/usermodel.dart';
import 'package:chatting/pages/chatbot.dart';
import 'package:chatting/pages/chatroompage.dart';
import 'package:chatting/pages/searchpage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  final UserModel userModel;
  final User firebaseUser;

  const HomePage({super.key, required this.userModel, required this.firebaseUser,});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {


  void deleteChatRoom(String chatRoomId) async {
    await FirebaseFirestore.instance.collection('chatrooms').doc(chatRoomId).delete();
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueAccent,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              height: 180,
              width: double.infinity,
               color: Colors.blueAccent,
              child: Stack(
                alignment: Alignment.topRight,
                children: [
                  Container(
                    height: double.infinity,
                    width: double.infinity,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Center(
                          child: Text("CHAT APP",style: TextStyle(color: Colors.white,
                              fontSize: 35,fontWeight: FontWeight.bold,),),
                        ),
                        Text("Your tagline goes here",style: TextStyle(color: Colors.grey[200]),),
                        SizedBox(
                          height: 20,
                        ),
                        GestureDetector(
                          onTap: (){
                            Navigator.of(context).push
                              (MaterialPageRoute(builder: (context)=>ChatBot()));
                          },
                          child: Container(
                            padding: EdgeInsets.only(top: 8,bottom: 8,left: 13),
                            height: 40,
                            width: 300,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(25),
                              color: Colors.white
                            ),
                            child: Text("Ask to Chat Bot",style: TextStyle(
                              color: Colors.grey,
                              fontSize: 17
                            ),),
                          ),
                        )
                      ],
                    ),
                  ),
                ],
              )
              ),
            Expanded(
              child: Container(
                padding: EdgeInsets.only(top: 10),
                decoration: BoxDecoration(
                    color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(35),
                    topLeft: Radius.circular(35),
                  ),
                ),
                child: StreamBuilder(
                  stream: FirebaseFirestore.instance.collection("chatrooms").
                    where("participants.${widget.userModel.uid}",isEqualTo: true).
                    snapshots(),
                  builder: (context,snapshot){
                    if(snapshot.connectionState == ConnectionState.active){
                      if(snapshot.hasData){
                        QuerySnapshot chatRoomSnapshot = snapshot.data as
                        QuerySnapshot;

                        return ListView.builder(
                          itemCount: chatRoomSnapshot.docs.length,
                            itemBuilder: (context,index){
                            ChatRoomModel chatRoomModel = ChatRoomModel.
                            fromMap(chatRoomSnapshot.docs[index].data() as
                            Map<String,dynamic>);

                            Map<String,dynamic> participants =
                            chatRoomModel.participants!;

                            List<String> participantsksys = participants.keys.toList();
                            participantsksys.remove(widget.userModel.uid);

                            return FutureBuilder(
                                future: FirebaseHelper.getUserModelById(
                                  participantsksys[0]),
                                builder: (context,userData){
                                  if(userData.connectionState ==ConnectionState.
                                  done){
                                    if(userData.data != null){
                                      UserModel targetUser = userData.data as UserModel;

                                      return Padding(
                                        padding: const EdgeInsets.only(top: 10,left: 10,right: 10),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(15),
                                              border: Border.all(
                                              width: 0.5,
                                              color: Colors.grey
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.1),
                                                spreadRadius: 0.5,
                                                blurRadius: 2,
                                                offset: Offset(0, 3),
                                              ),
                                            ],
                                          ),
                                          child: ListTile(
                                            onTap:(){ Navigator.of(context).push(MaterialPageRoute
                                              (builder: (context)=>ChatRoomPage
                                              (
                                                targetUser: targetUser,
                                                chatroom: chatRoomModel,
                                                userModel: widget.userModel,
                                                firebaseUser: widget.firebaseUser,
                                               )));},
                                            leading: CircleAvatar(
                                              backgroundImage: NetworkImage(targetUser.profilepic.toString()),
                                            ),
                                            title: Text(targetUser.fullname.toString()),
                                            subtitle: (chatRoomModel.lastMessage != "")? Text(chatRoomModel.
                                            lastMessage.toString()): Text("Say hi to your friend!",
                                              style: TextStyle(color: Colors.blueAccent),),
                                            trailing: IconButton(
                                              icon: Icon(Icons.delete, color: Colors.black87),
                                              onPressed: () {
                                                deleteChatRoom(chatRoomModel.chatroomid!);
                                              },
                                            ),
                                          ),
                                        ),
                                      );
                                    }
                                    else{
                                      return Container();
                                    }
                                  }else{
                                    return Container();
                                  }
                                });
                            });
                      }
                      else if(snapshot.hasError){
                        return Center(
                          child: Text(snapshot.error.toString(),
                            style: TextStyle(color: Colors.black87,fontSize: 25),),
                        );
                      }
                      else{
                        return Center(
                          child: Text("No Chats",
                            style: TextStyle(color: Colors.black87,fontSize: 25),),
                        );
                      }
                    }else{
                      return Center(
                        child: CircularProgressIndicator(),
                      );
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Container(
        height: 70,
        width: 70,
        child: FloatingActionButton(
          shape: CircleBorder(),
          backgroundColor: Colors.blueAccent,
          onPressed: (){
            Navigator.of(context).push(MaterialPageRoute
              (builder: (context)=>
                SearchPage(userModel:
                widget.userModel,
                    firebaseUser: widget.firebaseUser,
                  )));
          },
          child: Icon(Icons.search,color: Colors.white,),
        ),
      ),
    );
  }
}

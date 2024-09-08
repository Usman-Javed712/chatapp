import 'dart:async';
import 'package:chatting/model/statusmodel.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../model/usermodel.dart';

class Mystory extends StatefulWidget {
  final StatusModel statusModel;
  final String url;
  final UserModel userModel;
  final User firebaseuser;

  Mystory({
    Key? key,
    required this.url,
    required this.statusModel,
    required this.userModel,
    required this.firebaseuser,
  }) : super(key: key);

  @override
  _StoryViewerPageState createState() => _StoryViewerPageState();
}

class _StoryViewerPageState extends State<Mystory> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  Timer? _autoCloseTimer;

  @override
  void initState() {
    super.initState();

    // Initialize AnimationController
    _controller = AnimationController(
      duration: Duration(seconds: 10),
      vsync: this,
    )..forward();

    // Initialize Animation
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);

    // Start auto-close timer
    _autoCloseTimer = Timer(Duration(seconds: 10), () {
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _autoCloseTimer?.cancel();
    super.dispose();
  }

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


  void _showBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          height: 400,
          width: double.infinity,
          color: Colors.white,
          child: Column(
            children: [
              Container(
                height: 70,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.blueAccent,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 15,
                      horizontal: 10),
                      child: Text("Your viewers",style: TextStyle(color: Colors.white,fontSize: 25,),),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 15,
                          horizontal: 10),
                      child: Icon(Icons.remove_red_eye_outlined,color: Colors.white,),
                    )
                  ],
                ),
              ),
              Expanded(
                child: StreamBuilder(
                  stream: getStatuses(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    var statuses = snapshot.data!;
                    var myStatus = statuses.firstWhereOrNull(
                          (status) => status.senderId == widget.userModel.uid,
                    );

                    if (myStatus?.seen == null || myStatus!.seen!.isEmpty) {
                      return Center(
                        child: Text(
                          "No viewers yet",
                          style: TextStyle(color: Colors.white),
                        ),
                      );
                    }

                    return Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: ListView.builder(
                        itemCount: myStatus.seen!.length,
                        itemBuilder: (context, index) {
                          String viewerName = myStatus.seen!.elementAt(index);
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 5,left: 10,right: 10),
                            child: Container(
                              color: Colors.grey[300],
                              child: ListTile(
                                title: Text(viewerName),
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }


  Future<void> _showDeleteDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Status'),
          content: Text('Are you sure you want to delete this status?'),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Delete'),
              onPressed: () {
                deleteStatus(widget.statusModel.statusId.toString(),widget.statusModel.senderId.toString());
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
  Future<void> deleteStatus(String statusId, String userId) async {
    try {
      await FirebaseFirestore.instance
          .collection('storage')
          .doc(userId)
          .collection('status')
          .doc(statusId)
          .delete();
      print('Status deleted');
    } catch (e) {
      print('Error deleting status: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () {
        _controller.stop();
        _autoCloseTimer?.cancel();
      },
      onLongPressUp: () {
        _controller.forward();
        _autoCloseTimer = Timer(Duration(seconds: 10), () {
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          }
        });
      },
      onTap: () {
        Navigator.of(context).pop();
      },
      child: SafeArea(
        child: Scaffold(
          backgroundColor: Colors.white,
          body: Stack(
            alignment: Alignment.topCenter,
            children: [
              PageView.builder(
                itemCount: widget.url.length,
                  itemBuilder: (context,index){
                    return Center(
                      child: Image.network(widget.url.toString()),
                    );
                  }),
              Positioned(
                top: 5,
                left: 0,
                right: 0,
                child: AnimatedBuilder(
                  animation: _animation,
                  builder: (context, child) {
                    return LinearProgressIndicator(
                      value: _animation.value,
                      backgroundColor: Colors.black.withOpacity(0.2),
                      color: Colors.blue,
                      minHeight: 5,
                    );
                  },
                ),
              ),
              Positioned(
                top: 30,
                left: 0,
                right: 0,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 25,
                        backgroundImage: NetworkImage(widget.userModel.profilepic ?? ''),
                        backgroundColor: Colors.grey,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          widget.statusModel.userName.toString(),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: _showDeleteDialog,
                        child: Container(
                          height: 40,
                          width: 40,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(100),
                            color: Colors.grey[200],
                          ),
                          child: Icon(Icons.more_horiz),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: 20,
                left: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _showBottomSheet,
                  child: RotatedBox(
                    quarterTurns: 1,
                    child: Icon(
                      Icons.arrow_back_ios_rounded,
                      size: 30,
                      color: Colors.black54,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

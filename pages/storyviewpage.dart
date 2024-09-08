import 'dart:async';
import 'package:chatting/model/statusmodel.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../model/usermodel.dart';

class StoryViewerPage extends StatefulWidget {
  final StatusModel statusModel;
  final String url;
  final UserModel userModel;
  final User firebaseuser;

   StoryViewerPage({
    Key? key,
    required this.url,
    required this.statusModel,
    required this.userModel,
    required this.firebaseuser,
  }) : super(key: key);

  @override
  _StoryViewerPageState createState() => _StoryViewerPageState();
}

class _StoryViewerPageState extends State<StoryViewerPage> with SingleTickerProviderStateMixin {
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



  Future<void> _showDeleteDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Mute'),
          content: Text('Are you sure you want to mute this status?'),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Mute'),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
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
              Center(
                child: Image.network(widget.url.toString()),
              ),
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
            ],
          ),
        ),
      ),
    );
  }
}

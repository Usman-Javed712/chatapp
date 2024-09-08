import 'package:chatting/model/usermodel.dart';
import 'package:chatting/pages/calls.dart';
import 'package:chatting/pages/homepage.dart';
import 'package:chatting/pages/profilepage.dart';
import 'package:chatting/pages/statuspage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';

class NavPage extends StatefulWidget {
  final UserModel userModel;
  final User firebaseUser;

  const NavPage({super.key, required this.userModel, required this.firebaseUser});

  @override
  State<NavPage> createState() => _NavPageState();
}

class _NavPageState extends State<NavPage> {
  int myCurrentIndex = 2; // Default selected page

  late List<Widget> pages;

  @override
  void initState() {
    super.initState();
    pages = [
      StoryPage(userModel: widget.userModel, firebaseuser: widget.firebaseUser,),
      CallsPage(),
      HomePage(userModel: widget.userModel, firebaseUser: widget.firebaseUser,),
      ProfilePage(userModel: widget.userModel, firebaseUser: widget.firebaseUser),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: pages[myCurrentIndex],
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 5),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.grey,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(50),
            color: Colors.transparent,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(50),
            child: GNav(
              selectedIndex: myCurrentIndex,
              onTabChange: (index) {
                setState(() {
                  myCurrentIndex = index;
                });
              },
              backgroundColor: Colors.transparent,
              color: Colors.black,
              activeColor: Colors.white,
              tabBackgroundColor: Colors.blueAccent,
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
              tabs: const [
                GButton(
                  icon: Icons.history_toggle_off_sharp,
                ),
                GButton(
                  icon: Icons.call,
                ),
                GButton(
                  icon: Icons.chat_bubble,
                ),
                GButton(
                  icon: Icons.person_3,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

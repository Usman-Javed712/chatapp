import 'package:chatting/model/uihelper.dart';
import 'package:chatting/model/usermodel.dart';
import 'package:chatting/pages/bottombar.dart';
import 'package:chatting/pages/forgotpassword.dart';
import 'package:chatting/pages/signuppage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class LoginPage extends StatefulWidget {
  LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formkey = GlobalKey<FormState>();
  bool _obscureText = true;
  TextEditingController emailcontroller = TextEditingController();
  TextEditingController passwordcontroller = TextEditingController();

  void checkValue(){
    String email = emailcontroller.text.trim();
    String password = passwordcontroller.text.trim();

    if(email == ""|| password == ""){
      return null;
    }else{
      logIn(email, password);
    }
  }

  void logIn(String email,String password) async {
    UserCredential? credential;
    
    UIHelper.showLoadingDialog(context, "Logging in ...");

    try{
      credential = await FirebaseAuth.
      instance.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch(e){
      Navigator.of(context).pop();

      UIHelper.showAlertDialog
        (context, "An error Occured", e.message.toString());
      print(e.message.toString());
    }
    if(credential != null){
      String uid = credential.user!.uid;
      DocumentSnapshot userData = await FirebaseFirestore.
      instance.collection("users").doc(uid).get();
      UserModel userModel = UserModel.
      fromMap(userData.data() as Map<String,dynamic>);

      print("Log in Successfull");
      Navigator.of(context).
      pushReplacement(MaterialPageRoute(builder: (context)=>
          NavPage(userModel: userModel, firebaseUser: credential!.user!)));
    }
  }
  
  String? validateEmail(String? email){
    RegExp emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    final isEmailValid = emailRegex.hasMatch(email ?? '');
    if(!isEmailValid){
      return "Please enter a valid email";
    }
    return null;
  }
  void _togglePasswordVisibility() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 30),
          child: Center(
            child: SingleChildScrollView(
              child: Form(
                key: _formkey,
                child: Column(
                  children: [
                    SizedBox(
                      width: 90, // Specify the width you want
                      height: 90, // Specify the height you want
                      child: Image.asset("assets/images/logo.png"),
                    ),
                    SizedBox(height: 10,),
                    Text("Chat APP",style: TextStyle(color: Colors.blueAccent,
                    fontSize: 35,fontWeight: FontWeight.bold),),

                    SizedBox(
                      height: 30,
                    ),

                    TextFormField(
                      controller: emailcontroller,
                      decoration: InputDecoration(
                        labelText: "Email Address"
                      ),
                      validator: validateEmail,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                    ),
                    SizedBox(
                      height: 10,
                    ),
                    TextFormField(
                      controller: passwordcontroller,
                      obscureText: _obscureText,
                      decoration: InputDecoration(
                        labelText: "Password",
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureText ? Icons.visibility_off : Icons.visibility,
                          ),
                          onPressed: () {
                            _togglePasswordVisibility();
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Please enter a password";
                        }
                        return null;
                      },
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                    ),


                    Align(
                      alignment: Alignment.topRight,
                      child: CupertinoButton
                        (onPressed: () {
                          Navigator.of(context).push(MaterialPageRoute(builder: (context)=>ForgotPassword()));
                          },
                        child: Text("Forgot Password?",style: TextStyle(color: Colors.blueAccent),)),
                    ),
                    CupertinoButton(
                      color: Colors.blueAccent,
                        child: Text("Log In"),
                        onPressed: (){
                        _formkey.currentState!.validate();
                        checkValue();
                        })
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Don't Have an Account",style: TextStyle(fontSize: 16),),

            CupertinoButton(
                child: Text("Sign up",style: TextStyle(color: Colors.blueAccent),),
                onPressed: (){
                  Navigator.of(context).push(MaterialPageRoute
                    (builder: (context)=>SignUpPage()));
                })
          ],
        ),
      ),
    );
  }
}

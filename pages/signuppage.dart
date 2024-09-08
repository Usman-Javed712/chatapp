import 'package:chatting/model/uihelper.dart';
import 'package:chatting/model/usermodel.dart';
import 'package:chatting/pages/completeprofilepage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formkey = GlobalKey<FormState>();


  TextEditingController emailcontroller = TextEditingController();
  TextEditingController passwordcontroller = TextEditingController();
  TextEditingController cpasswordcontroller = TextEditingController();

  void checkValue(){
    String email = emailcontroller.text.trim();
    String password = passwordcontroller.text.trim();
    String cpassword = cpasswordcontroller.text.trim();

    if(email == ""|| password == "" || cpassword == ""){
      return null;
    }else if(password != cpassword){
      UIHelper.showAlertDialog(context, "Password Mistmatch",
          "The password you entered didn't match");
    }else{
      signUp(email, password);
    }

  }

  void signUp(String email,String password) async {
    UserCredential? credential;

    UIHelper.showLoadingDialog(context,"Creating New Account");
    try{
      credential = await FirebaseAuth.instance.
      createUserWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch(e){
      Navigator.of(context).pop();
      UIHelper.showAlertDialog(context,
          "An error occured",
          e.message.toString());
    }
    if(credential != null){
      String uid = credential.user!.uid;
      UserModel newUser = UserModel(uid: uid,
          email: email,
          fullname: "",
          profilepic: "");
      await FirebaseFirestore.instance.collection("users").doc(uid).
      set(newUser.toMap()).then((value){
        print("New User Created");
        Navigator.of(context).
        pushReplacement(MaterialPageRoute(builder: (context)=>
            CompleteProfile(userModel: newUser, firebaseUser: credential!.user!)));
      });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Form(
          key: _formkey,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 30),
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    SizedBox(
                      width: 90,
                      height: 90,
                      child: Image.asset("assets/images/logo.png"),
                    ),
                    SizedBox(height: 10,),
                    Text("Chat APP",style: TextStyle(color: Colors.blueAccent,
                        fontSize: 35,fontWeight: FontWeight.bold),),

                    SizedBox(
                      height: 10,
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
                      obscureText: true,
                      decoration: InputDecoration(
                          labelText: "Password"
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Please enter a password";
                        }
                        return null;
                      },
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                    ),

                    SizedBox(
                      height: 10,
                    ),
                    TextFormField(
                      controller: cpasswordcontroller,
                      obscureText: true,
                      decoration: InputDecoration(
                          labelText: "Confirm Password"
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Please enter a password";
                        }
                        return null;
                      },
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                    ),

                    SizedBox(
                      height: 30,
                    ),

                    CupertinoButton(
                        color: Colors.blueAccent,
                        child: Text("Sign Up"),
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
            Text("Already Have an Account",style: TextStyle(fontSize: 16),),

            CupertinoButton(
                child: Text("Log In",style: TextStyle(color: Colors.blueAccent),),
                onPressed: (){
                  Navigator.of(context).pop();
                })
          ],
        ),
      ),
    );
  }
}

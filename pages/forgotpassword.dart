import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ForgotPassword extends StatefulWidget {
  const ForgotPassword({super.key});

  @override
  State<ForgotPassword> createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends State<ForgotPassword> {
  final _formkey = GlobalKey<FormState>();
  TextEditingController emailcontroller = TextEditingController();


  String? validateEmail(String? email){
    RegExp emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    final isEmailValid = emailRegex.hasMatch(email ?? '');
    if(!isEmailValid){
      return "Please enter a valid email";
    }
    return null;
  }
  @override
  void dispose() {
    emailcontroller.dispose();
    super.dispose();
  }

  Future passwordReset() async {
    try{
      await FirebaseAuth.instance.
      sendPasswordResetEmail(email: emailcontroller.text.trim());
      showDialog(context: context, builder: (context){
        return AlertDialog(
          backgroundColor: Colors.white,
          content: Text("Password reset link send check your e-mail"),
        );
      });
    }on FirebaseAuthException catch (e){
      print(e.code);
      showDialog(context: context, builder: (context){
        return AlertDialog(
          backgroundColor: Colors.white,
          content: Text(e.message.toString()),
        );
      });
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.blueAccent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
          color: Colors.white,
        ),
        title: Text("Forgot Password",
          style: TextStyle(fontSize: 25,fontWeight: FontWeight.bold,color: Colors.white),),
      ),
      body: Form(
        key: _formkey,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 25),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                height: 60,
              ),
              Text("Enter your E-mail",
                style: TextStyle(color: Colors.blueAccent,fontSize: 30,fontWeight: FontWeight.bold),),
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
                height: 20,
              ),
              CupertinoButton(
                color: Colors.blueAccent,
                  child: Text("Continue"),
                  onPressed: (){
                  passwordReset();
                  Navigator.of(context).pop();
                })
            ],
          ),
        ),
      ),
    );
  }
}

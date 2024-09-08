import 'dart:io';
import 'package:chatting/model/uihelper.dart';
import 'package:chatting/model/usermodel.dart';
import 'package:chatting/pages/bottombar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

class CompleteProfile extends StatefulWidget {
  final UserModel userModel;
  final User firebaseUser;

  CompleteProfile({super.key,required this.userModel,required this.firebaseUser});

  @override
  State<CompleteProfile> createState() => _CompleteProfileState();
}


class _CompleteProfileState extends State<CompleteProfile> {

  File? imageFile;
  TextEditingController fullnamecontroller = TextEditingController();
  final _formkey = GlobalKey<FormState>();


  void selectImage(ImageSource source) async {
    XFile? pickedFile = await ImagePicker().pickImage(source: source);

    if(pickedFile != null){
      cropImage(pickedFile);
    }
  }

  void cropImage(XFile file) async {
    CroppedFile? croppedImage = await ImageCropper().
    cropImage(sourcePath: file.path,
    aspectRatio: CropAspectRatio(ratioX: 1, ratioY: 1),
    compressQuality: 20
    );

    if (croppedImage != null) {
      setState(() {
        imageFile = File(croppedImage.path);
      });
    }
  }


  void showPhotoOptions(){
    showDialog(context: context, builder: (context){
      return AlertDialog(
        backgroundColor: Colors.white,
        title: Text("Upload Profile Picture"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              onTap: (){
                Navigator.of(context).pop();
                selectImage(ImageSource.gallery);
              },
              leading: Icon(Icons.photo_album),
              title: Text("Select From Gallery"),
            ),
            ListTile(
              onTap: (){
                Navigator.of(context).pop();
                selectImage(ImageSource.camera);
              },
              leading: Icon(Icons.camera_alt),
              title: Text("Take a Photo"),
            )
          ],
        ),
      );
    });
  }

  void checkValues(){
    String fullname = fullnamecontroller.text.trim();

    if(fullname == ""|| imageFile == null){
      return null;
    }else{
      uploadData();
    }
  }


  void uploadData() async {

    UIHelper.showLoadingDialog(context, "Uploading Image");
    UploadTask uploadTask = FirebaseStorage.instance.ref("profilepictures").
    child(widget.userModel.uid.toString()).putFile(imageFile!);

    TaskSnapshot snapshot = await uploadTask;

    String imageUrl = await snapshot.ref.getDownloadURL();
    String fullname = fullnamecontroller.text.trim();

    widget.userModel.fullname = fullname;
    widget.userModel.profilepic = imageUrl;
    
    await FirebaseFirestore.instance.collection("users").
    doc(widget.userModel.uid).set(widget.userModel.toMap()).then((value){
      print("Data Uploaded");
      Navigator.of(context).
      pushReplacement(MaterialPageRoute(builder: (context)=>
          NavPage(userModel: widget.userModel, firebaseUser: widget.firebaseUser)));
    });
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
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.blueAccent,
        title: Text("Complete Profile",style:
        TextStyle(color: Colors.white,fontWeight: FontWeight.normal),),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 30),
          child: ListView(
            children: [
              SizedBox(
                height: 20,
              ),
              CupertinoButton(
                onPressed: (){
                  showPhotoOptions();
                },
                padding: EdgeInsets.all(0),
                child: Center(
                  child: CircleAvatar(
                    radius: 60,
                    backgroundImage: (imageFile != null) ?
                    FileImage(imageFile!) : null,
                    child: (imageFile == null)?
                  Icon(Icons.person,size: 50,color: Colors.white,): null
                  ),
                ),
              ),

              SizedBox(
                height: 40,
              ),

              TextFormField(
                controller: fullnamecontroller,
                decoration: InputDecoration(
                  labelText: "Full Name"
                ),
                validator: validateEmail,
              ),

              SizedBox(
                height: 20,
              ),

              CupertinoButton(
                  color: Colors.blueAccent,
                  child: Text("Submit"),
                  onPressed: (){
                    _formkey.currentState!.validate();
                    checkValues();
                  })
            ],
          ),
        ),
      ),
    );
  }
}

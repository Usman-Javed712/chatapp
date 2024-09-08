import 'package:flutter/material.dart';

class UIHelper{
  static void showLoadingDialog(BuildContext context, String title){
    AlertDialog loadingDialog = AlertDialog(
      backgroundColor: Colors.white,
      content: Container(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Colors.blueAccent,),
        
            SizedBox(
              height: 20,
            ),
        
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Text(title,style: TextStyle(fontSize: 17),),
            ),
          ],
        ),
      ),
    );
    
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context){
      return loadingDialog;
    });
  }

  static void showAlertDialog(BuildContext context,
      String title,
      String content){
    AlertDialog alertDialog = AlertDialog(
      backgroundColor: Colors.white,
      title: Text(title),
      content: Text(content),
      actions: [
        TextButton(onPressed: (){
          Navigator.of(context).pop();
        },
            child: Text("Ok"))
      ],
    );
    showDialog(context: context,builder: (context){
      return alertDialog;
    });
  }
}
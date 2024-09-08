import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel{
  String? messageId;
  String? sender;
  String? text;
  bool? seen;
  DateTime? createdon;
  String? picture;
  String? audioUrl;

  MessageModel({this.messageId,
    this.sender,
    this.text,
    this.seen,
    this.createdon,
    this.picture,
  required this.audioUrl});

  MessageModel.fromMap(Map<String,dynamic> map){
    messageId = map["messageId"];
    sender = map["sender"];
    text = map["text"];
    seen = map["seen"];
    createdon = map["createdon"] != null ? (map["createdon"] as Timestamp).toDate() : null;
    picture = map["picture"];
    audioUrl = map["audioUrl"];
  }

  Map<String,dynamic> toMap(){
    return {
      "messageId" : messageId,
        "sender" : sender,
        "text" : text,
        "seen" : seen,
      "createdon": createdon != null ? Timestamp.fromDate(createdon!) : null,
      "picture": picture,
      "audioUrl": audioUrl,

    };
  }
}
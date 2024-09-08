class StatusModel {
  String? senderId;
  List<dynamic>? seen;
  DateTime? createdon;
  String? statusId;
  String? picture;
  String? userName;


  StatusModel({this.senderId, this.seen, this.createdon, this.statusId,this.picture,this.userName});

  StatusModel.fromMap(Map<String, dynamic> map) {
    statusId = map['statusId'];
    senderId = map['sender'];
    seen = map['seen'];
    picture=map['picture'];
    createdon = map['createdon']?.toDate();
    userName=map['userName'];
  }
  Map<String, dynamic> toMap() {
    return {
      'statusId': statusId,
      'sender': senderId,
      'seen': seen,
      'createdon': createdon,
      'picture':picture,
      'userName':userName,
    };
  }
}
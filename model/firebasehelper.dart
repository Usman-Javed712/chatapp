import 'package:chatting/model/usermodel.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseHelper {
  static Future<UserModel?> getUserModelById(String uid) async {
    UserModel? userModel;

    try {
      DocumentSnapshot docSnap = await FirebaseFirestore.instance.collection("users").doc(uid).get();

      if (docSnap.exists && docSnap.data() != null) {
        userModel = UserModel.fromMap(docSnap.data() as Map<String, dynamic>);
      }
    } catch (e) {
      print("Error fetching user model: $e");
      // Handle the error as appropriate, e.g., show a message to the user or retry the operation
    }

    return userModel;
  }
}

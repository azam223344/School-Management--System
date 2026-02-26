import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  FirestoreService._();

  static final FirebaseFirestore instance = FirebaseFirestore.instance;

  static CollectionReference<Map<String, dynamic>> usersRef() {
    return instance.collection('users');
  }
}

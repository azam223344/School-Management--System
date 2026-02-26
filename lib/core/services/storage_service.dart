import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  StorageService._();

  static final FirebaseStorage instance = FirebaseStorage.instance;
}

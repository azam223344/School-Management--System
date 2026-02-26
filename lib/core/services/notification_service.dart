import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationService {
  NotificationService._();

  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  static Future<void> initialize() async {
    await _messaging.requestPermission();
    await _messaging.getToken();
  }
}

import 'package:firebase_core/firebase_core.dart';

import 'notification_service.dart';
import '../../firebase_options.dart';

class FirebaseService {
  static Future<void> initialize() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    try {
      await NotificationService.initialize();
    } catch (_) {
      // Notification setup is optional during early development.
    }
  }
}

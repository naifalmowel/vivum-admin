import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ConfigService {
  static Future<void> init() async {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyBjFpqGTr1XPq9fEbMo7T1e6yWh640lsQ0",
        authDomain: "vivum-d2907.firebaseapp.com",
        projectId: "vivum-d2907",
        storageBucket: "vivum-d2907.firebasestorage.app",
        messagingSenderId: "899371078453",
        appId: "1:899371078453:web:f96fb357e3603473f1727c",
        measurementId: "G-E7C1ZV11L7",
      ),
    );

    await Supabase.initialize(
      url: 'https://gosqrnkrebpdqvhazugw.supabase.co',
      publishableKey: 'sb_publishable_N0iUuNR5DD-yKtgCqcXglg_K2ySU9pj',
      debug: false,
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:the_wall/firebase_options.dart';

import 'package:the_wall/sandbox.dart';
import 'package:the_wall/settings.dart';
import 'package:the_wall/theme.dart';
import 'auth/auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const Main());
}

class Main extends StatefulWidget {
  static const String name = 'Main';

  const Main({super.key});

  @override
  State<Main> createState() => _MainState();
}

class _MainState extends State<Main> {
  @override
  Widget build(BuildContext context) {
    if (sandboxEnabled) {
      return MaterialApp(
        theme: darkTheme,
        home: const Sandbox(),
      );
    }

    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection('User Settings')
          .doc(FirebaseAuth.instance.currentUser?.email)
          .snapshots(),
      builder: (context, snapshot) {
        ThemeMode themeMode() {
          if (snapshot.hasData && snapshot.data!.data() != null) {
            if (snapshot.data!.data()!['darkMode'] == null) return ThemeMode.system;
            return snapshot.data!.data()!['darkMode'] ? ThemeMode.dark : ThemeMode.light;
          } else {
            return UserConfig().darkMode ? ThemeMode.dark : ThemeMode.light;
          }
        }

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: themeMode(),
          home: const AuthPage(),
        );
      },
    );
  }
}

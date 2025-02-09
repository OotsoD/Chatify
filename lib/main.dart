import 'package:flutter/material.dart';
import 'package:cb/pages/signup.dart';
import 'package:cb/pages/login.dart';
import 'package:cb/pages/userlist.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chatify',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      initialRoute: 'signin',
      routes: {
        'signup': (context) => RegistrationPage(),
        'signin': (context) => LoginPage(),
        'userlist': (context) => UserListScreen(),
      },
      debugShowCheckedModeBanner: false,
      home: AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          User? user = snapshot.data;
          if (user == null) {
            return LoginPage(); // Navigate to login screen if not authenticated
          } else {
            return UserListScreen(); // Navigate to user list screen if authenticated
          }
        } else {
          return CircularProgressIndicator(); // Show loading indicator while waiting for auth state
        }
      },
    );
  }
}

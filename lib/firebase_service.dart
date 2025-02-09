import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

   Future<User?> signUp(String name, String email, String password, String mobile) async {
    try {
      print('Starting signup process...');
      
      // Check for existing mobile number without ordering by name
      print('Checking for existing mobile number: $mobile');
      var existing = await _firestore
          .collection('users')
          .where('mobile', isEqualTo: mobile)
          .get();

      if (existing.docs.isNotEmpty) {
        print('Mobile number already exists');
        throw Exception('Mobile number already exists');
      }

      // Create auth user first
      print('Creating auth user with email: $email');
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      User? user = userCredential.user;
      print('Auth user created with UID: ${user?.uid}');
      
      if (user != null) {
        print('Creating Firestore document for user ${user.uid}');
        
        // Create the user document
        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'name': name,
          'email': email,
          'mobile': mobile,
          'createdAt': FieldValue.serverTimestamp(),
        });
        
        print('Firestore document created successfully');
        return user;
      }
      return null;
    } on FirebaseAuthException catch (e) {
      print('FirebaseAuthException: ${e.code} - ${e.message}');
      switch (e.code) {
        case 'email-already-in-use':
          throw Exception('This email is already registered');
        case 'weak-password':
          throw Exception('Password should be at least 6 characters');
        case 'invalid-email':
          throw Exception('The email address is invalid');
        default:
          throw Exception(e.message ?? 'An error occurred during registration');
      }
    } catch (e) {
      print('Error in signUp process: $e');
      throw Exception(e.toString());
    }
  }


  Future<User?> signIn(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Verify that the user document exists in Firestore
      var userDoc = await _firestore.collection('users').doc(userCredential.user?.uid).get();
      if (!userDoc.exists) {
        // Create the user document if it doesn't exist
        await _firestore.collection('users').doc(userCredential.user?.uid).set({
          'uid': userCredential.user?.uid,
          'email': email,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          throw Exception('No user found with this email.');
        case 'wrong-password':
          throw Exception('Wrong password.');
        case 'user-disabled':
          throw Exception('This account has been disabled.');
        case 'invalid-email':
          throw Exception('Invalid email address.');
        default:
          throw Exception(e.message ?? 'Login failed. Please try again.');
      }
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<User?> getCurrentUser() async {
    return _auth.currentUser;
  }

  bool isAuthenticated() {
    return _auth.currentUser != null;
  }

  Future<void> sendMessage(String messageContent, String receiverUID) async {
    final User? user = _auth.currentUser;
    if (user != null && messageContent.isNotEmpty) {
      final senderUID = user.uid;
      final chatDocID = senderUID.compareTo(receiverUID) > 0
          ? '${senderUID}_${receiverUID}'
          : '${receiverUID}_$senderUID';
      final timestamp = Timestamp.now();

      await _firestore
          .collection('chats')
          .doc(chatDocID)
          .collection('messages')
          .add({
        'senderUID': senderUID,
        'receiverUID': receiverUID,
        'timestamp': timestamp,
        'messageContent': messageContent,
      });
    }
  }
}
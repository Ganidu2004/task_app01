import 'package:firebase_auth/firebase_auth.dart';
import 'package:task_app/database_services.dart';
import 'package:task_app/modles/user_modle.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseService _databaseService = DatabaseService();

  Future<UserCredential> registerUser({
    required String fullName,
    required String email,
    required String password,
    required String phoneNumber,
    String? profileImageUrl,
  }) async {
    UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    User? user = userCredential.user;

    if (user != null) {
      await user.updateDisplayName(fullName);

      UserModel newUser = UserModel(
        uid: user.uid,
        profileImageUrl: profileImageUrl,
        fullName: fullName,
        email: email,
        phoneNumber: phoneNumber,
        createdAt: DateTime.now(),
      );

      await _databaseService.saveUserData(newUser);
    }

    return userCredential;
  }

  Future<UserCredential> loginUser({
    required String email,
    required String password,
  }) async {
    UserCredential userCredential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return userCredential;
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }
}

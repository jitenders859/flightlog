import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../constants/app_constants.dart';
import '../models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _error;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _auth.currentUser != null;
  String? get userId => _auth.currentUser?.uid;

  AuthService() {
    _init();
  }

  Future<void> _init() async {
    //here start
    await FirebaseAuth.instance.currentUser?.getIdToken(true);
    //here end
    // _auth.authStateChanges().listen((User? user) async {
    //   if (user != null) {
    //     await _loadUserData(user.uid);
    //   } else {
    //     _currentUser = null;
    //     notifyListeners();
    //   }
    // });
    _auth.idTokenChanges().listen((User? user) async {
      if (user != null) {
        await _loadUserData(user.uid);
      } else {
        _currentUser = null;
        notifyListeners();
      }
    });
  }

  Future<void> _loadUserData(String userId) async {
    try {
      _isLoading = true;
      notifyListeners();

      DocumentSnapshot doc =
          await _firestore
              .collection(AppConstants.usersCollection)
              .doc(userId)
              .get();

      if (doc.exists) {
        _currentUser = UserModel.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
        await _updateFCMToken();

        // Save user info to shared preferences for quick access
        SharedPreferences prefs = await SharedPreferences.getInstance();
        prefs.setString(AppConstants.prefsUserId, _currentUser!.id);
        prefs.setString(AppConstants.prefsUserRole, _currentUser!.role);
        prefs.setString(AppConstants.prefsUserName, _currentUser!.fullName);
      }

      _isLoading = false;
      _error = null;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> _updateFCMToken() async {
    if (_currentUser == null) return;

    try {
      String? token = await _messaging.getToken();
      if (token != null && _currentUser!.fcmToken != token) {
        await _firestore
            .collection(AppConstants.usersCollection)
            .doc(_currentUser!.id)
            .update({
              'fcmToken': token,
              'updatedAt': DateTime.now().millisecondsSinceEpoch,
            });
      }
    } catch (e) {
      print('Error updating FCM token: $e');
    }
  }

  Future<UserModel?> signIn(String email, String password) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      if (userCredential.user != null) {
        await _loadUserData(userCredential.user!.uid);
        return _currentUser;
      }

      _isLoading = false;
      notifyListeners();
      return null;
    } catch (e) {
      _isLoading = false;
      _error = _getReadableAuthError(e);
      notifyListeners();
      return null;
    }
  }

  Future<UserModel?> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String role,
    String? phoneNumber,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Create user with Firebase Auth
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      if (userCredential.user != null) {
        // Get FCM token for notifications
        String? fcmToken = await _messaging.getToken();

        // Create user document in Firestore
        UserModel user = UserModel(
          id: userCredential.user!.uid,
          email: email,
          firstName: firstName,
          lastName: lastName,
          role: role,
          phoneNumber: phoneNumber,
          profileImageUrl: null,
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          fcmToken: fcmToken,
        );

        await _firestore
            .collection(AppConstants.usersCollection)
            .doc(user.id)
            .set(user.toMap());

        // Save user info to shared preferences
        SharedPreferences prefs = await SharedPreferences.getInstance();
        prefs.setString(AppConstants.prefsUserId, user.id);
        prefs.setString(AppConstants.prefsUserRole, user.role);
        prefs.setString(AppConstants.prefsUserName, user.fullName);

        _currentUser = user;
        _isLoading = false;
        notifyListeners();
        return user;
      }

      _isLoading = false;
      notifyListeners();
      return null;
    } catch (e) {
      _isLoading = false;
      _error = _getReadableAuthError(e);
      notifyListeners();
      return null;
    }
  }

  Future<void> signOut() async {
    try {
      _isLoading = true;
      notifyListeners();

      // Clear FCM token
      if (_currentUser != null) {
        await _firestore
            .collection(AppConstants.usersCollection)
            .doc(_currentUser!.id)
            .update({
              'fcmToken': null,
              'updatedAt': DateTime.now().millisecondsSinceEpoch,
            });
      }

      // Clear shared preferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.remove(AppConstants.prefsUserId);
      prefs.remove(AppConstants.prefsUserRole);
      prefs.remove(AppConstants.prefsUserName);

      // Sign out from Firebase Auth
      await _auth.signOut();

      _currentUser = null;
      _isLoading = false;
      _error = null;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<bool> resetPassword(String email) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _auth.sendPasswordResetEmail(email: email);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = _getReadableAuthError(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateProfile({
    required String firstName,
    required String lastName,
    String? phoneNumber,
  }) async {
    if (_currentUser == null) return false;

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      UserModel updatedUser = _currentUser!.copyWith(
        firstName: firstName,
        lastName: lastName,
        phoneNumber: phoneNumber,
      );

      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(_currentUser!.id)
          .update({
            'firstName': firstName,
            'lastName': lastName,
            'phoneNumber': phoneNumber,
            'updatedAt': DateTime.now().millisecondsSinceEpoch,
          });

      _currentUser = updatedUser;

      // Update shared preferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.setString(AppConstants.prefsUserName, _currentUser!.fullName);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  String _getReadableAuthError(dynamic error) {
    String errorMessage = 'An error occurred. Please try again.';

    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
          errorMessage = 'No user found with this email.';
          break;
        case 'wrong-password':
          errorMessage = 'Incorrect password.';
          break;
        case 'email-already-in-use':
          errorMessage = 'Email is already in use.';
          break;
        case 'weak-password':
          errorMessage = 'Password is too weak.';
          break;
        case 'invalid-email':
          errorMessage = 'Invalid email address.';
          break;
        default:
          errorMessage = error.message ?? errorMessage;
      }
    } else {
      errorMessage = error.toString();
    }

    return errorMessage;
  }
}

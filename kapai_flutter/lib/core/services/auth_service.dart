import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/staff_model.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ── Staff login (email + password) ──────────────────────────────────────────

  Future<StaffModel?> signInStaff(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    if (cred.user == null) return null;
    final doc = await _db.collection('staff').doc(cred.user!.uid).get();
    if (!doc.exists) {
      await _auth.signOut();
      throw Exception('No staff record found for this account.');
    }
    final staff = StaffModel.fromFirestore(doc);
    if (!staff.isActive) {
      await _auth.signOut();
      throw Exception('This account has been deactivated.');
    }
    return staff;
  }

  Future<void> createStaffAccount({
    required String email,
    required String password,
    required String name,
    required StaffRole role,
    List<String> assignedCategories = const [],
    StaffPermissions permissions = StaffPermissions.none,
    required String createdBy,
  }) async {
    // Create auth account
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    // Write staff document
    final staff = StaffModel(
      id: cred.user!.uid,
      name: name,
      email: email.trim(),
      role: role,
      assignedCategories: assignedCategories,
      permissions: permissions,
      createdBy: createdBy,
      createdAt: DateTime.now(),
    );
    await _db.collection('staff').doc(cred.user!.uid).set(staff.toFirestore());
  }

  // ── Customer phone auth ──────────────────────────────────────────────────────

  Future<void> sendOtp(String phone, {
    required Function(PhoneAuthCredential) onAutoVerified,
    required Function(String verificationId, int? resendToken) onCodeSent,
    required Function(FirebaseAuthException) onFailed,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phone,
      verificationCompleted: onAutoVerified,
      verificationFailed: onFailed,
      codeSent: (verificationId, resendToken) =>
          onCodeSent(verificationId, resendToken),
      codeAutoRetrievalTimeout: (_) {},
    );
  }

  Future<UserModel?> verifyOtp(String verificationId, String smsCode) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    final cred = await _auth.signInWithCredential(credential);
    if (cred.user == null) return null;

    final doc = await _db.collection('users').doc(cred.user!.uid).get();
    if (doc.exists) {
      return UserModel.fromFirestore(doc);
    }

    // New customer — create profile
    final user = UserModel(
      id: cred.user!.uid,
      name: '',
      phone: cred.user!.phoneNumber ?? '',
      beans: 0,
      tier: LoyaltyTier.sprout,
      totalSpent: 0,
      createdAt: DateTime.now(),
    );
    await _db.collection('users').doc(cred.user!.uid).set(user.toFirestore());
    return user;
  }

  Future<StaffModel?> getStaffProfile(String uid) async {
    final doc = await _db.collection('staff').doc(uid).get();
    if (!doc.exists) return null;
    return StaffModel.fromFirestore(doc);
  }

  Future<UserModel?> getUserProfile(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }

  Future<void> signOut() => _auth.signOut();
}

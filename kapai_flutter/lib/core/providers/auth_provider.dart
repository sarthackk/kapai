import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/staff_model.dart';
import '../models/user_model.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());
final firestoreServiceProvider = Provider<FirestoreService>((ref) => FirestoreService());

// Raw Firebase auth state stream
final firebaseAuthProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

// Staff profile — null when not a staff member (e.g. customer logged in via phone)
final staffProfileProvider = FutureProvider<StaffModel?>((ref) async {
  final auth = await ref.watch(firebaseAuthProvider.future);
  if (auth == null) return null;
  return ref.read(authServiceProvider).getStaffProfile(auth.uid);
});

// Current customer profile — null when not logged in or is a staff member
final currentUserProvider = StreamProvider<UserModel?>((ref) {
  final auth = ref.watch(firebaseAuthProvider);
  final uid = auth.valueOrNull?.uid;
  if (uid == null) return Stream.value(null);
  return ref.watch(firestoreServiceProvider).watchUser(uid);
});

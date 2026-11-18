import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provides the [FirebaseAuth] instance.
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

/// Provides the [FirebaseDatabase] instance.
final firebaseDatabaseProvider = Provider<FirebaseDatabase>((ref) {
  final db = FirebaseDatabase.instance;
  // Enable offline persistence on mobile
  return db;
});

/// Stream of auth state changes from Firebase Auth.
final authStateStreamProvider = StreamProvider<User?>((ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges();
});

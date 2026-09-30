import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

import '../models/app_user.dart';
import '../models/complaint.dart';
import '../models/system_log.dart';
import '../models/user_role.dart';
import 'repository.dart';

class FirebaseRepository implements AppRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final Uuid _uuid = const Uuid();

  @override
  Future<AppUser?> login(String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    return _userFromUid(credential.user!.uid);
  }

  @override
  Future<void> signOut() => _auth.signOut();

  Future<AppUser?> _userFromUid(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return AppUser.fromMap({...doc.data()!, 'id': uid});
  }

  @override
  Future<AppUser> signup({
    required String fullName,
    required String email,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = AppUser(
      id: credential.user!.uid,
      fullName: fullName,
      email: email.trim(),
      password: '',
      role: UserRole.citizen,
      createdAt: DateTime.now(),
    );
    await _db.collection('users').doc(user.id).set(user.toMap());
    return user;
  }

  @override
  Future<List<AppUser>> getUsers() async {
    final snap = await _db.collection('users').get();
    return snap.docs
        .map((d) => AppUser.fromMap({...d.data(), 'id': d.id}))
        .toList();
  }

  @override
  Future<List<Complaint>> getComplaints() async {
    final snap = await _db
        .collection('complaints')
        .orderBy('createdAt', descending: true)
        .get();
    return snap.docs
        .map((d) => Complaint.fromMap({...d.data(), 'id': d.id}))
        .toList();
  }

  @override
  Future<List<SystemLog>> getLogs() async {
    final snap = await _db
        .collection('logs')
        .orderBy('timestamp', descending: true)
        .limit(100)
        .get();
    return snap.docs
        .map((d) => SystemLog.fromMap({...d.data(), 'id': d.id}))
        .toList();
  }

  @override
  Future<void> saveUser(AppUser user) async {
    await _db.collection('users').doc(user.id).set(user.toMap());
  }

  @override
  Future<void> saveComplaint(Complaint complaint) async {
    await _db.collection('complaints').doc(complaint.id).set(complaint.toMap());
  }

  @override
  Future<void> saveLog(SystemLog log) async {
    await _db.collection('logs').doc(log.id).set(log.toMap());
  }

  @override
  Future<String?> uploadMedia(File file, String folder) async {
    final isVideo = file.path.toLowerCase().endsWith('.mp4');
    final contentType = isVideo ? 'video/mp4' : 'application/octet-stream';
    try {
      final ref = _storage.ref().child('$folder/${_uuid.v4()}');
      final meta = SettableMetadata(contentType: contentType);
      await ref.putFile(file, meta);
      return ref.getDownloadURL();
    } catch (_) {
      // Cloud Storage needs a paid plan since 2026-02-03, so keep photos
      // inside the Firestore document and skip videos rather than failing
      // the whole submission.
      if (isVideo) return null;
      return _embedAsDataUri(file);
    }
  }

  @override
  Future<String?> uploadImage(File file, String folder) async {
    try {
      final ref = _storage.ref().child('$folder/${_uuid.v4()}');
      await ref.putFile(file);
      return ref.getDownloadURL();
    } catch (_) {
      return _embedAsDataUri(file);
    }
  }

  Future<String> _embedAsDataUri(File file) async {
    final bytes = await file.readAsBytes();
    final mime = file.path.toLowerCase().endsWith('.png')
        ? 'image/png'
        : 'image/jpeg';
    return 'data:$mime;base64,${base64Encode(bytes)}';
  }

  String newId() => _uuid.v4();
}

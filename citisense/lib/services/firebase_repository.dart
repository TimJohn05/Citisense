import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;
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

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

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
    final uid = _auth.currentUser?.uid;
    if (uid == null) return [];
    final isStaff = await _isStaff(uid);
    final collection = _db.collection('complaints');
    final snap = await (isStaff
            ? collection.orderBy('createdAt', descending: true)
            : collection.where('citizenId', isEqualTo: uid))
        .get();
    final complaints = snap.docs
        .map((d) => Complaint.fromMap({...d.data(), 'id': d.id}))
        .toList();
    if (isStaff) return complaints;
    complaints.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return complaints;
  }

  Future<bool> _isStaff(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    final role = doc.data()?['role'];
    return role == 'officer' || role == 'admin';
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

  // Cloudinary config — set via --dart-define or replace the defaults.
  // Free tier: 25 GB storage, 25 GB bandwidth/month, no credit card needed.
  // Create an account at cloudinary.com, then set:
  //   --dart-define=CLOUDINARY_CLOUD_NAME=your_cloud_name
  //   --dart-define=CLOUDINARY_UPLOAD_PRESET=your_unsigned_preset
  static const _cloudinaryCloudName =
      String.fromEnvironment('CLOUDINARY_CLOUD_NAME', defaultValue: '');
  static const _cloudinaryUploadPreset =
      String.fromEnvironment('CLOUDINARY_UPLOAD_PRESET', defaultValue: '');

  @override
  Future<String?> uploadMedia(File file, String folder) async {
    final isVideo = file.path.toLowerCase().endsWith('.mp4');
    if (isVideo) {
      // Try Cloudinary first (free tier, supports video).
      if (_cloudinaryCloudName.isNotEmpty &&
          _cloudinaryUploadPreset.isNotEmpty) {
        try {
          final url = await _uploadToCloudinary(file);
          if (url != null) return url;
        } catch (_) {}
      }
      // Fall back to Firebase Storage (Blaze plan only).
      try {
        final ref = _storage.ref().child('$folder/${_uuid.v4()}');
        final meta = SettableMetadata(contentType: 'video/mp4');
        await ref.putFile(file, meta);
        return ref.getDownloadURL();
      } catch (_) {
        // No storage available — skip video rather than failing the submit.
        return null;
      }
    }
    // Photos: try Firebase Storage, then base64 fallback.
    try {
      final ref = _storage.ref().child('$folder/${_uuid.v4()}');
      await ref.putFile(file);
      return ref.getDownloadURL();
    } catch (_) {
      return _embedAsDataUri(file);
    }
  }

  Future<String?> _uploadToCloudinary(File file) async {
    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/$_cloudinaryCloudName/video/upload',
    );
    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = _cloudinaryUploadPreset
      ..files.add(await http.MultipartFile.fromPath('file', file.path));
    final response = await request.send();
    if (response.statusCode == 200) {
      final body = await response.stream.bytesToString();
      final json = jsonDecode(body) as Map<String, dynamic>;
      return json['secure_url'] as String?;
    }
    return null;
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

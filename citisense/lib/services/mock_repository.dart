import 'dart:async';
import 'dart:io';

import '../models/app_user.dart';
import '../models/complaint.dart';
import '../models/enums.dart';
import '../models/media_item.dart';
import '../models/system_log.dart';
import '../models/user_role.dart';
import 'repository.dart';

class MockRepository implements AppRepository {
  final List<AppUser> _users = [];
  final List<Complaint> _complaints = [];
  final List<SystemLog> _logs = [];

  final _usersController = StreamController<List<AppUser>>.broadcast();
  final _complaintsController = StreamController<List<Complaint>>.broadcast();
  final _logsController = StreamController<List<SystemLog>>.broadcast();

  MockRepository() {
    _seedUsers();
    _seedComplaints();
    _seedLogs();
    _notifyAll();
  }

  void _notifyAll() {
    _usersController.add(List.of(_users));
    final sortedComplaints = List.of(_complaints)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    _complaintsController.add(sortedComplaints);
    final sortedLogs = List.of(_logs)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    _logsController.add(sortedLogs);
  }

  void _seedUsers() {
    _users.addAll([
      AppUser(
        id: 'u1',
        fullName: 'Juan Dela Cruz',
        email: 'citizen@citisense.com',
        password: 'password',
        role: UserRole.citizen,
        barangay: 'Barangay 1',
        createdAt: DateTime(2026, 1, 5),
      ),
      AppUser(
        id: 'u2',
        fullName: 'Officer Juan',
        email: 'officer@citisense.com',
        password: 'password',
        role: UserRole.officer,
        barangay: 'Barangay 1',
        createdAt: DateTime(2026, 1, 5),
      ),
      AppUser(
        id: 'u3',
        fullName: 'Admin User',
        email: 'admin@citisense.com',
        password: 'password',
        role: UserRole.admin,
        barangay: 'Barangay 1',
        createdAt: DateTime(2026, 1, 5),
      ),
    ]);
  }

  void _seedComplaints() {
    _complaints.addAll([
      Complaint(
        id: 'c1',
        citizenId: 'u1',
        citizenName: 'Juan Dela Cruz',
        category: ComplaintCategory.waste,
        description: 'Basura tambak sa kanto',
        sentiment: Sentiment.negative,
        recommendation: 'Schedule a cleanup operation for the reported area',
        status: ComplaintStatus.resolved,
        latitude: 14.1956,
        longitude: 121.1469,
        createdAt: DateTime(2026, 7, 1, 10, 0),
        evidencePhotos: ['data:image/png;base64,...'],
      ),
      Complaint(
        id: 'c2',
        citizenId: 'u1',
        citizenName: 'Juan Dela Cruz',
        category: ComplaintCategory.lighting,
        description: 'Walang ilaw sa kalsada',
        sentiment: Sentiment.negative,
        recommendation: 'Inspect and repair the street lighting circuit',
        status: ComplaintStatus.inReview,
        latitude: 14.2,
        longitude: 121.15,
        createdAt: DateTime(2026, 7, 2, 14, 30),
        evidencePhotos: ['data:image/png;base64,...'],
      ),
      Complaint(
        id: 'c3',
        citizenId: 'u1',
        citizenName: 'Juan Dela Cruz',
        category: ComplaintCategory.water,
        description: 'Walang tubig sa bahay',
        sentiment: Sentiment.negative,
        recommendation: 'Check for pipe leaks or water contamination',
        status: ComplaintStatus.pending,
        latitude: 14.21,
        longitude: 121.16,
        createdAt: DateTime(2026, 7, 3, 9, 15),
        evidencePhotos: ['data:image/png;base64,...'],
      ),
    ]);
  }

  void _seedLogs() {
    _logs.addAll([
      SystemLog(
        id: 'l1',
        timestamp: DateTime(2026, 8, 1, 8, 30),
        action: 'System Init',
        detail: 'CitiSense services started successfully.',
      ),
      SystemLog(
        id: 'l2',
        timestamp: DateTime(2026, 8, 1, 8, 31),
        action: 'Login',
        detail: 'officer@citisense.com signed in.',
      ),
      SystemLog(
        id: 'l3',
        timestamp: DateTime(2026, 8, 1, 9, 0),
        action: 'Complaint Filed',
        detail: 'New complaint c4 filed by maria@citisense.com.',
      ),
    ]);
  }

  @override
  Future<AppUser?> login(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final user = _users.where((u) => u.isActive).toList().where(
          (u) => u.email.toLowerCase() == email.toLowerCase() &&
              u.password == password,
        );
    return user.isEmpty ? null : user.first;
  }

  @override
  Future<AppUser> signup({
    required String fullName,
    required String email,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));
    if (_users.any((u) => u.email.toLowerCase() == email.toLowerCase())) {
      throw Exception('Email already registered');
    }
    final user = AppUser(
      id: 'u${_users.length + 1}',
      fullName: fullName,
      email: email,
      password: password,
      role: UserRole.citizen,
      barangay: 'Barangay 1',
      createdAt: DateTime.now(),
    );
    _users.add(user);
    _notifyAll();
    return user;
  }

  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 100));
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    await Future.delayed(const Duration(milliseconds: 400));
  }

  Future<Complaint> submitComplaint({
    required ComplaintCategory category,
    required String description,
    required double? latitude,
    required double? longitude,
    required List<MediaItem> evidence,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final user = _users.firstWhere((u) => u.email == 'citizen@citisense.com');
    final complaint = Complaint(
      id: 'c${_complaints.length + 1}',
      citizenId: user.id,
      citizenName: user.fullName,
      category: category,
      description: description,
      sentiment: Sentiment.negative,
      recommendation: 'Schedule a cleanup operation for the reported area',
      status: ComplaintStatus.pending,
      latitude: latitude,
      longitude: longitude,
      createdAt: DateTime.now(),
      evidencePhotos: evidence.isNotEmpty ? [evidence.first.displayPath ?? ''] : [],
    );
    _complaints.add(complaint);
    _notifyAll();
    return complaint;
  }

  Future<void> acknowledgeComplaint(String complaintId, String officerId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _complaints.indexWhere((c) => c.id == complaintId);
    if (index >= 0) {
      _complaints[index] = _complaints[index].copyWith(status: ComplaintStatus.inReview);
      _notifyAll();
    }
  }

  Future<void> resolveComplaint(String complaintId, String officerId, {required String resolutionNotes, required File proofImage}) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _complaints.indexWhere((c) => c.id == complaintId);
    if (index >= 0) {
      _complaints[index] = _complaints[index].copyWith(
        status: ComplaintStatus.resolved,
        officerNotes: resolutionNotes,
        proofPhotos: [proofImage.path],
        resolvedAt: DateTime.now(),
      );
      _notifyAll();
    }
  }

  Future<void> rejectComplaint(String complaintId, String officerId, String reason) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _complaints.indexWhere((c) => c.id == complaintId);
    if (index >= 0) {
      _complaints[index] = _complaints[index].copyWith(
        status: ComplaintStatus.rejected,
        officerNotes: reason,
        resolvedAt: DateTime.now(),
      );
      _notifyAll();
    }
  }

  @override
  Future<List<AppUser>> getUsers() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return List.of(_users);
  }

  Future<AppUser?> getUser(String userId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _users.firstWhere((u) => u.id == userId);
  }

  @override
  Future<void> saveUser(AppUser user) async {
    final index = _users.indexWhere((u) => u.id == user.id);
    if (index >= 0) {
      _users[index] = user;
    } else {
      _users.add(user);
    }
    _notifyAll();
  }

  @override
  Future<List<Complaint>> getComplaints() async {
    await Future.delayed(const Duration(milliseconds: 200));
    final sorted = List.of(_complaints)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted;
  }

  @override
  Future<void> signOut() async {
    await Future.delayed(const Duration(milliseconds: 100));
  }

  Future<Complaint?> getComplaint(String complaintId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _complaints
        .where((c) => c.id == complaintId)
        .cast<Complaint?>()
        .firstOrNull;
  }

  @override
  Future<void> saveComplaint(Complaint complaint) async {
    final index = _complaints.indexWhere((c) => c.id == complaint.id);
    if (index >= 0) {
      _complaints[index] = complaint;
    } else {
      _complaints.add(complaint);
    }
    _notifyAll();
  }

  Future<void> removeComplaint(String complaintId) async {
    _complaints.removeWhere((c) => c.id == complaintId);
    _notifyAll();
  }

  Future<List<Complaint>> getComplaintsByUser(String userId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _complaints.where((c) => c.citizenId == userId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<List<SystemLog>> getLogs() async {
    await Future.delayed(const Duration(milliseconds: 200));
    final sorted = List.of(_logs)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return sorted;
  }

  @override
  Future<void> saveLog(SystemLog log) async {
    _logs.insert(0, log);
    _notifyAll();
  }

  @override
  Future<String?> uploadMedia(File file, String folder) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return file.path;
  }

  @override
  Future<String?> uploadImage(File file, String folder) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return file.path;
  }

  @override
  Stream<List<AppUser>> watchUsers() => _usersController.stream;

  @override
  Stream<List<Complaint>> watchComplaints() => _complaintsController.stream;

@override
  Stream<List<SystemLog>> watchLogs() {
    final currentLogs = List.of(_logs)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return Stream<List<SystemLog>>.multi((controller) {
      controller.add(currentLogs);
      _logsController.stream.listen(controller.add);
    });
  }
}
import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';

import '../models/app_user.dart';
import '../models/complaint.dart';
import '../models/enums.dart';
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
        fullName: 'Maria Clara Santos',
        email: 'maria@citisense.com',
        password: 'password',
        role: UserRole.citizen,
        barangay: 'Barangay Halang',
        createdAt: DateTime(2026, 1, 12),
      ),
      AppUser(
        id: 'u3',
        fullName: 'Hon. Jose Santos',
        email: 'officer@citisense.com',
        password: 'password',
        role: UserRole.officer,
        barangay: 'Barangay Real',
        createdAt: DateTime(2025, 12, 1),
      ),
      AppUser(
        id: 'u4',
        fullName: 'Kagawad Liza Reyes',
        email: 'liza@citisense.com',
        password: 'password',
        role: UserRole.officer,
        barangay: 'Barangay Canlubang',
        createdAt: DateTime(2025, 12, 10),
      ),
      AppUser(
        id: 'u5',
        fullName: 'Chief System Admin',
        email: 'admin@citisense.com',
        password: 'password',
        role: UserRole.admin,
        createdAt: DateTime(2025, 11, 20),
      ),
    ]);
  }

  void _seedComplaints() {
    final now = DateTime.now();
    _complaints.addAll([
      Complaint(
        id: 'c1',
        citizenId: 'u1',
        citizenName: 'Juan Dela Cruz',
        category: ComplaintCategory.waste,
        description:
            'Garbage pile at Block 5 near the main road is blocking the drainage and causing a severe odor in the area.',
        sentiment: Sentiment.negative,
        recommendation:
            'Schedule a cleanup operation for the reported area',
        status: ComplaintStatus.pending,
        latitude: 14.1956,
        longitude: 121.1469,
        barangay: 'Barangay 1',
        evidencePhotos: const ['https://placehold.co/600x400?text=Garbage+Pile'],
        evidenceVideos: const [
          'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4',
        ],
        createdAt: now.subtract(const Duration(hours: 3)),
      ),
      Complaint(
        id: 'c2',
        citizenId: 'u2',
        citizenName: 'Maria Clara Santos',
        category: ComplaintCategory.road,
        description:
            'Massive pothole at the public intersection is causing damage to vehicle alignment and is a hazard at night.',
        sentiment: Sentiment.negative,
        recommendation:
            'Dispatch the maintenance crew for immediate repair',
        status: ComplaintStatus.inReview,
        officerNotes: 'Crew scheduled to inspect the intersection on Friday.',
        latitude: 14.2042,
        longitude: 121.1547,
        barangay: 'Parian',
        createdAt: now.subtract(const Duration(days: 1, hours: 2)),
      ),
      Complaint(
        id: 'c3',
        citizenId: 'u1',
        citizenName: 'Juan Dela Cruz',
        category: ComplaintCategory.water,
        description:
            'The clean running water service is back after the public filter replacement. Great work!',
        sentiment: Sentiment.positive,
        recommendation: 'Acknowledge the stable water service',
        status: ComplaintStatus.resolved,
        officerNotes: 'Filter unit replaced and pressure restored to normal.',
        proofPhotos: ['https://placehold.co/600x400?text=Water+Restored'],
        resolvedBy: 'Hon. Jose Santos',
        resolvedAt: now.subtract(const Duration(days: 1, hours: 6)),
        latitude: 14.1865,
        longitude: 121.1390,
        barangay: 'Halang',
        createdAt: now.subtract(const Duration(days: 2, hours: 4)),
      ),
      Complaint(
        id: 'c4',
        citizenId: 'u2',
        citizenName: 'Maria Clara Santos',
        category: ComplaintCategory.lighting,
        description:
            'Street lamp posts along Mabini Street have not been replaced since last month. The street is dark and unsafe to walk at night.',
        sentiment: Sentiment.negative,
        recommendation: 'Inspect and repair the street lighting circuit',
        status: ComplaintStatus.pending,
        latitude: 14.2110,
        longitude: 121.1300,
        barangay: 'Barangay 1',
        createdAt: now.subtract(const Duration(days: 3, hours: 1)),
      ),
      Complaint(
        id: 'c5',
        citizenId: 'u1',
        citizenName: 'Juan Dela Cruz',
        category: ComplaintCategory.peaceOrder,
        description:
            'Loud videoke and drinking session at Purok 4 past midnight. Residents with early shifts cannot sleep.',
        sentiment: Sentiment.negative,
        recommendation: 'Deploy tanod patrol to address the disturbance',
        status: ComplaintStatus.pending,
        latitude: 14.1980,
        longitude: 121.1510,
        barangay: 'Canlubang',
        createdAt: now.subtract(const Duration(days: 4, hours: 6)),
      ),
      Complaint(
        id: 'c6',
        citizenId: 'u2',
        citizenName: 'Maria Clara Santos',
        category: ComplaintCategory.trafficObstruction,
        description:
            'Illegally parked delivery truck blocking the intersection near the public market since yesterday afternoon.',
        sentiment: Sentiment.negative,
        recommendation: 'Clear the obstruction and issue a violation notice',
        status: ComplaintStatus.inReview,
        officerNotes: 'Tanod dispatched to locate the vehicle owner.',
        latitude: 14.2015,
        longitude: 121.1485,
        barangay: 'Parian',
        createdAt: now.subtract(const Duration(days: 5, hours: 2)),
      ),
      Complaint(
        id: 'c7',
        citizenId: 'u1',
        citizenName: 'Juan Dela Cruz',
        category: ComplaintCategory.floodDrainage,
        description:
            'Clogged drainage canal along Pansol causing knee-deep flooding even with light rain. Dirty water entering homes.',
        sentiment: Sentiment.negative,
        recommendation:
            'Inspect and declog the drainage system in the area',
        status: ComplaintStatus.pending,
        latitude: 14.1890,
        longitude: 121.1420,
        barangay: 'Pansol',
        createdAt: now.subtract(const Duration(days: 6, hours: 5)),
      ),
      Complaint(
        id: 'c8',
        citizenId: 'u2',
        citizenName: 'Maria Clara Santos',
        category: ComplaintCategory.healthSanitation,
        description:
            'Open burning of tires and plastic waste near the daycare center. Thick black smoke is hazardous to children.',
        sentiment: Sentiment.negative,
        recommendation:
            'Coordinate with health workers for sanitation response',
        status: ComplaintStatus.inReview,
        officerNotes: 'CENRO notified; inspection scheduled.',
        latitude: 14.2060,
        longitude: 121.1350,
        barangay: 'Canlubang',
        createdAt: now.subtract(const Duration(days: 8, hours: 1)),
      ),
      Complaint(
        id: 'c9',
        citizenId: 'u1',
        citizenName: 'Juan Dela Cruz',
        category: ComplaintCategory.electricalHazard,
        description:
            'Exposed live wire dangling from a leaning utility pole at the corner of Barangay Real. Sparks visible at night.',
        sentiment: Sentiment.negative,
        recommendation: 'Cordon the area and report to Meralco immediately',
        status: ComplaintStatus.pending,
        latitude: 14.2095,
        longitude: 121.1525,
        barangay: 'Real',
        createdAt: now.subtract(const Duration(days: 12, hours: 3)),
      ),
      Complaint(
        id: 'c10',
        citizenId: 'u2',
        citizenName: 'Maria Clara Santos',
        category: ComplaintCategory.publicFacilities,
        description:
            'Broken basketball ring and cracked flooring at the covered court in Barangay Halang. Unsafe for players.',
        sentiment: Sentiment.negative,
        recommendation: 'Schedule facility repair and post safety notice',
        status: ComplaintStatus.resolved,
        officerNotes: 'Ring replaced and floor patched by maintenance crew.',
        proofPhotos: ['https://placehold.co/600x400?text=Court+Repaired'],
        resolvedBy: 'Hon. Jose Santos',
        resolvedAt: now.subtract(const Duration(days: 10, hours: 2)),
        latitude: 14.1920,
        longitude: 121.1380,
        barangay: 'Halang',
        createdAt: now.subtract(const Duration(days: 15, hours: 7)),
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
  Future<void> signOut() async {}

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    // Simulate a network delay, then succeed for any seeded email.
    await Future.delayed(const Duration(milliseconds: 300));
    final exists = _users.any(
      (u) => u.email.toLowerCase() == email.trim().toLowerCase(),
    );
    if (!exists) {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'No user record for that email.',
      );
    }
  }

  @override
  Future<AppUser> signup({
    required String fullName,
    required String email,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final user = AppUser(
      id: 'u${DateTime.now().millisecondsSinceEpoch}',
      fullName: fullName,
      email: email,
      password: password,
      role: UserRole.citizen,
      barangay: 'Barangay 1',
      createdAt: DateTime.now(),
    );
    _users.add(user);
    return user;
  }

  @override
  Future<List<AppUser>> getUsers() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return List.of(_users);
  }

  @override
  Future<List<Complaint>> getComplaints() async {
    await Future.delayed(const Duration(milliseconds: 200));
    final sorted = List.of(_complaints)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted;
  }

  @override
  Future<List<SystemLog>> getLogs() async {
    await Future.delayed(const Duration(milliseconds: 200));
    final sorted = List.of(_logs)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return sorted;
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
  Future<void> saveComplaint(Complaint complaint) async {
    final index = _complaints.indexWhere((c) => c.id == complaint.id);
    if (index >= 0) {
      _complaints[index] = complaint;
    } else {
      _complaints.add(complaint);
    }
    _notifyAll();
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
  Stream<List<SystemLog>> watchLogs() => _logsController.stream;
}

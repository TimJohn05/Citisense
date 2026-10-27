import 'dart:io';

import '../models/app_user.dart';
import '../models/complaint.dart';
import '../models/system_log.dart';

abstract class AppRepository {
  Future<AppUser?> login(String email, String password);

  Future<void> sendPasswordResetEmail(String email);

  Future<void> signOut();

  Future<AppUser> signup({
    required String fullName,
    required String email,
    required String password,
  });

  Future<List<AppUser>> getUsers();

  Future<List<Complaint>> getComplaints();

  Future<List<SystemLog>> getLogs();

  Stream<List<AppUser>> watchUsers();

  Stream<List<Complaint>> watchComplaints();

  Stream<List<SystemLog>> watchLogs();

  Future<void> saveUser(AppUser user);

  Future<void> saveComplaint(Complaint complaint);

  Future<void> saveLog(SystemLog log);

  Future<String?> uploadImage(File file, String folder);

  Future<String?> uploadMedia(File file, String folder);
}

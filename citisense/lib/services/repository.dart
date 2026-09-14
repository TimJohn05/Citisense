import 'dart:io';

import '../models/app_user.dart';
import '../models/complaint.dart';
import '../models/system_log.dart';

abstract class AppRepository {
  Future<AppUser?> login(String email, String password);

  Future<void> signOut();

  Future<AppUser> signup({
    required String fullName,
    required String email,
    required String password,
  });

  Future<List<AppUser>> getUsers();

  Future<List<Complaint>> getComplaints();

  Future<List<SystemLog>> getLogs();

  Future<void> saveUser(AppUser user);

  Future<void> saveComplaint(Complaint complaint);

  Future<void> saveLog(SystemLog log);

  Future<String?> uploadImage(File file, String folder);

  Future<String?> uploadMedia(File file, String folder);
}

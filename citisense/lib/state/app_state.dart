import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/theme/app_theme.dart';
import '../models/app_user.dart';
import '../models/complaint.dart';
import '../models/enums.dart';
import '../models/media_item.dart';
import '../models/system_log.dart';
import '../models/user_role.dart';
import '../services/auth_error_messages.dart';
import '../services/repository.dart';
import '../services/sentiment_engine.dart';

class AppState extends ChangeNotifier with WidgetsBindingObserver {
  final AppRepository repository;

  AppUser? _user;
  List<Complaint> _complaints = [];
  List<AppUser> _users = [];
  List<SystemLog> _logs = [];

  bool _isLoading = false;
  bool _restoringSession = true;
  String? _error;

  ThemeStyle _themeStyle = ThemeStyle.system;
  bool _highContrast = false;

  static const _kThemeStyle = 'settings.theme_style';
  static const _kHighContrast = 'settings.high_contrast';
  static const _kSession = 'session.user';
  static const _kSessionSavedAt = 'session.saved_at';

  static const _backgroundSessionTimeout = Duration(hours: 2);
  Timer? _backgroundTimer;

  AppState({required this.repository}) {
    WidgetsBinding.instance.addObserver(this);
    _loadSettings();
    _restoreSession();
  }

  @override
  void dispose() {
    _backgroundTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _backgroundTimer?.cancel();
        _backgroundTimer = null;
        break;
      case AppLifecycleState.detached:
        _backgroundTimer?.cancel();
        _backgroundTimer = null;
        _secureSessionEnd();
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        _backgroundTimer ??= Timer(_backgroundSessionTimeout, _secureSessionEnd);
        break;
    }
  }

  bool get isRestoringSession => _restoringSession;

  ThemeStyle get themeStyle => _themeStyle;
  bool get highContrast => _highContrast;

  ThemeMode get themeMode {
    switch (_themeStyle) {
      case ThemeStyle.system:
        return ThemeMode.system;
      case ThemeStyle.light:
        return ThemeMode.light;
      case ThemeStyle.dark:
        return ThemeMode.dark;
    }
  }

  void setThemeStyle(ThemeStyle style) {
    _themeStyle = style;
    notifyListeners();
    _persistSettings();
  }

  void setHighContrast(bool value) {
    _highContrast = value;
    notifyListeners();
    _persistSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedStyle = prefs.getString(_kThemeStyle);
      _themeStyle = ThemeStyle.values.asNameMap()[savedStyle] ?? ThemeStyle.system;
      _highContrast = prefs.getBool(_kHighContrast) ?? false;
    } catch (_) {
      // SharedPreferences unavailable (e.g. tests) — use defaults.
    }
    notifyListeners();
  }

  Future<void> _persistSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kThemeStyle, _themeStyle.name);
      await prefs.setBool(_kHighContrast, _highContrast);
    } catch (_) {
      // Best-effort persistence only.
    }
  }

  AppUser? get user => _user;
  List<Complaint> get complaints => _complaints;
  List<AppUser> get users => _users;
  List<SystemLog> get logs => _logs;
  bool get isLoading => _isLoading;
  String? get error => _error;

  bool get isLoggedIn => _user != null;

  List<Complaint> get myComplaints => _user == null
      ? []
      : _complaints
          .where((c) => c.citizenId == _user!.id)
          .toList();

  List<Complaint> complaintsByCategory(ComplaintCategory category) =>
      _complaints.where((c) => c.category == category).toList();

  List<Complaint> complaintsByStatus(ComplaintStatus status) =>
      _complaints.where((c) => c.status == status).toList();

  int get totalComplaints => _complaints.length;
  int get pendingCount =>
      complaintsByStatus(ComplaintStatus.pending).length;
  int get inReviewCount =>
      complaintsByStatus(ComplaintStatus.inReview).length;
  int get resolvedCount =>
      complaintsByStatus(ComplaintStatus.resolved).length;
  int get rejectedCount =>
      complaintsByStatus(ComplaintStatus.rejected).length;
  int get negativeCount =>
      _complaints.where((c) => c.sentiment == Sentiment.negative).length;
  int get positiveCount =>
      _complaints.where((c) => c.sentiment == Sentiment.positive).length;
  int get neutralCount =>
      _complaints.where((c) => c.sentiment == Sentiment.neutral).length;

  double get resolutionRate =>
      totalComplaints == 0 ? 0 : (resolvedCount / totalComplaints * 100);

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _error = null;
    try {
      final user = await repository.login(email, password);
      if (user == null) {
        _error = 'Invalid email or password. Please try again.';
        _setLoading(false);
        return false;
      }
      _user = user;
      await _persistSession(user);
      await _loadData();
      await _addLog(
        'Login',
        '${user.fullName} signed in as ${user.role.label}.',
      );
      _setLoading(false);
      return true;
    } catch (e) {
      _error = friendlyAuthMessage(e);
      _setLoading(false);
      return false;
    }
  }

  Future<bool> signup({
    required String fullName,
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _error = null;
    try {
      final user = await repository.signup(
        fullName: fullName,
        email: email,
        password: password,
      );
      // Deliberately no auto-login: a new account must confirm through the
      // sign-in flow. Creating the account is enough here.
      await _addLog(
        'Signup',
        'New citizen account created for ${user.fullName}.',
      );
      _setLoading(false);
      return true;
    } catch (e) {
      _error = friendlyAuthMessage(e, signingUp: true);
      _setLoading(false);
      return false;
    }
  }

  Future<void> logout() async {
    final name = _user?.fullName;
    _user = null;
    _complaints = [];
    _users = [];
    _logs = [];
    notifyListeners();
    await _clearSession();
    try {
      await repository.signOut();
    } catch (_) {
      // Repository may be offline — logout must still complete.
    }
    try {
      await _addLog('Logout', '$name signed out.');
    } catch (_) {
      // Best-effort logging only.
    }
  }

  Future<void> _secureSessionEnd() async {
    if (_user == null) return;
    final name = _user?.fullName;
    _user = null;
    _complaints = [];
    _users = [];
    _logs = [];
    notifyListeners();
    try {
      await _clearSession();
    } catch (_) {
      // Best-effort persistence only.
    }
    try {
      await repository.signOut();
    } catch (_) {
      // Repository may be offline — session end must still complete.
    }
    try {
      await _addLog('Logout', '$name session ended by app closure.');
    } catch (_) {
      // Best-effort logging only.
    }
  }

  Future<void> _restoreSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kSession);
      if (raw == null) return;
      final data = jsonDecode(raw) as Map<String, dynamic>;

      final savedAt = prefs.getInt(_kSessionSavedAt);
      final expired = savedAt == null ||
          DateTime.now()
                  .difference(DateTime.fromMillisecondsSinceEpoch(savedAt))
                  .inMilliseconds >
              _backgroundSessionTimeout.inMilliseconds;
      if (expired) {
        await prefs.remove(_kSession);
        await prefs.remove(_kSessionSavedAt);
        return;
      }

      final sessionUser = AppUser.fromMap(data);
      try {
        await _loadData();
      } catch (_) {
        // Repository unavailable (e.g. Firebase unreachable) — keep session.
      }
      final matches = _users.where((u) => u.id == sessionUser.id).toList();
      if (_users.isNotEmpty && matches.isEmpty) {
        await prefs.remove(_kSession);
        await prefs.remove(_kSessionSavedAt);
        return;
      }
      _user = matches.isNotEmpty ? matches.first : sessionUser;
    } catch (_) {
      // Best-effort restore — fall back to the login screen.
    } finally {
      _restoringSession = false;
      notifyListeners();
    }
  }

  Future<void> _persistSession(AppUser user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = user.toMap()..['password'] = '';
      await prefs.setString(_kSession, jsonEncode(data));
      await prefs.setInt(_kSessionSavedAt, DateTime.now().millisecondsSinceEpoch);
    } catch (_) {
      // Best-effort persistence only.
    }
  }

  Future<void> _clearSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kSession);
      await prefs.remove(_kSessionSavedAt);
    } catch (_) {
      // Best-effort persistence only.
    }
  }

  Future<void> _loadData() async {
    _complaints = await repository.getComplaints();
    if (_user?.role == UserRole.citizen) return;
    final results = await Future.wait([
      repository.getUsers(),
      repository.getLogs(),
    ]);
    _users = results[0] as List<AppUser>;
    _logs = results[1] as List<SystemLog>;
  }

  Future<Complaint> submitComplaint({
    required ComplaintCategory category,
    required String description,
    required double? latitude,
    required double? longitude,
    required List<MediaItem> evidence,
  }) async {
    _setLoading(true);
    try {
      final analysis = SentimentEngine.analyze(description, category);
      final complaint = Complaint(
        id: 'c${DateTime.now().millisecondsSinceEpoch}',
        citizenId: _user!.id,
        citizenName: _user!.fullName,
        category: category,
        description: description,
        sentiment: analysis.sentiment,
        recommendation: analysis.recommendation,
        status: ComplaintStatus.pending,
        latitude: latitude,
        longitude: longitude,
        createdAt: DateTime.now(),
      );

      final photos = <String>[];
      final videos = <String>[];
      for (final item in evidence) {
        final uri = await _uploadMedia(
          item,
          'complaints/${complaint.id}/evidence',
        );
        if (uri == null) continue;
        if (item.isVideo) {
          videos.add(uri);
        } else {
          photos.add(uri);
        }
      }

      final saved = complaint.copyWith(
        evidencePhotos: photos,
        evidenceVideos: videos,
      );
      await repository.saveComplaint(saved);
      _complaints.insert(0, saved);
      await _addLog(
        'Complaint Filed',
        '${_user!.fullName} filed a ${category.label} report classified as ${analysis.sentiment.label}.',
      );
      _setLoading(false);
      return saved;
    } catch (e) {
      _setLoading(false);
      rethrow;
    }
  }

  Future<String?> _uploadMedia(MediaItem item, String folder) async {
    if (item.url != null && item.url!.isNotEmpty) {
      return item.url;
    }
    if (item.file != null) {
      return repository.uploadMedia(item.file!, folder);
    }
    return null;
  }

  Future<void> acknowledgeComplaint(
    Complaint complaint,
    String notes,
  ) async {
    final updated = complaint.copyWith(
      status: ComplaintStatus.inReview,
      officerNotes: notes,
    );
    await _persistComplaint(updated, 'Acknowledged by ${_user!.fullName}.');
  }

  Future<void> resolveComplaint(
    Complaint complaint, {
    required String notes,
    required List<MediaItem> proof,
  }) async {
    final photos = <String>[];
    final videos = <String>[];
    for (final item in proof) {
      final uri = await _uploadMedia(
        item,
        'complaints/${complaint.id}/proof',
      );
      if (uri == null) continue;
      if (item.isVideo) {
        videos.add(uri);
      } else {
        photos.add(uri);
      }
    }
    final updated = complaint.copyWith(
      status: ComplaintStatus.resolved,
      officerNotes: notes,
      proofPhotos: photos,
      proofVideos: videos,
      resolvedBy: _user!.fullName,
      resolvedAt: DateTime.now(),
    );
    await _persistComplaint(
      updated,
      'Resolved by ${_user!.fullName} with photo and video proof.',
    );
  }

  Future<void> rejectComplaint(
    Complaint complaint,
    String reason,
  ) async {
    final updated = complaint.copyWith(
      status: ComplaintStatus.rejected,
      rejectReason: reason,
      resolvedBy: _user!.fullName,
      resolvedAt: DateTime.now(),
    );
    await _persistComplaint(
      updated,
      'Rejected by ${_user!.fullName}: $reason',
    );
  }

  Future<void> addOfficer({
    required String fullName,
    required String email,
    required String password,
    required String barangay,
  }) async {
    final user = AppUser(
      id: 'u${DateTime.now().millisecondsSinceEpoch}',
      fullName: fullName,
      email: email,
      password: password,
      role: UserRole.officer,
      barangay: barangay,
      createdAt: DateTime.now(),
    );
    await repository.saveUser(user);
    _users.add(user);
    await _addLog(
      'Officer Created',
      'Admin registered new barangay official: $fullName.',
    );
  }

  Future<void> toggleUserActive(AppUser user) async {
    final updated = user.copyWith(isActive: !user.isActive);
    await repository.saveUser(updated);
    final index = _users.indexWhere((u) => u.id == user.id);
    if (index >= 0) _users[index] = updated;
    await _addLog(
      updated.isActive ? 'Access Restored' : 'Access Revoked',
      '${user.fullName} access ${updated.isActive ? 'restored' : 'revoked'}.',
    );
  }

  Future<void> deleteComplaint(Complaint complaint) async {
    _complaints.removeWhere((c) => c.id == complaint.id);
    notifyListeners();
    await _addLog(
      'Complaint Removed',
      'Admin removed complaint ${complaint.id}.',
    );
  }

  Future<void> _persistComplaint(Complaint updated, String logDetail) async {
    final index = _complaints.indexWhere((c) => c.id == updated.id);
    if (index >= 0) {
      _complaints[index] = updated;
    }
    notifyListeners();
    await repository.saveComplaint(updated);
    await _addLog('Complaint Updated', logDetail);
  }

  Future<void> _addLog(String action, String detail) async {
    final log = SystemLog(
      id: 'l${DateTime.now().millisecondsSinceEpoch}',
      timestamp: DateTime.now(),
      action: action,
      detail: detail,
    );
    _logs.insert(0, log);
    notifyListeners();
    await repository.saveLog(log);
  }

  Future<void> refresh() async {
    await _loadData();
    notifyListeners();
  }
}

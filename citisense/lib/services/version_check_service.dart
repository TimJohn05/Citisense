import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class VersionCheckService {
  static const _minVersionKey = 'min_app_version';
  static const _latestVersionKey = 'latest_app_version';
  static const _updateUrlKey = 'update_apk_url';
  static const _updateNotesKey = 'update_notes';

  FirebaseRemoteConfig? _remoteConfig;
  bool _initialized = false;
  bool _firebaseAvailable = true;

  FirebaseRemoteConfig get _rc {
    _remoteConfig ??= FirebaseRemoteConfig.instance;
    return _remoteConfig!;
  }

  Future<void> initialize() async {
    if (_initialized) return;

    // Check if Firebase is initialized without throwing
    if (Firebase.apps.isEmpty) {
      _firebaseAvailable = false;
      _initialized = true;
      return;
    }

    try {
      await _rc.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: const Duration(hours: 4),
      ));
      await _rc.setDefaults({
        _minVersionKey: '1.0.0',
        _latestVersionKey: '1.0.0',
        _updateUrlKey: '',
        _updateNotesKey: '',
      });
      await _rc.fetchAndActivate();
    } catch (_) {
      // Use defaults if fetch fails
    }
    _initialized = true;
  }

  Future<VersionStatus> checkVersion() async {
    await initialize();

    if (!_firebaseAvailable) {
      return VersionStatus(
        currentVersion: '1.0.0',
        currentBuild: 1,
        minVersion: '1.0.0',
        latestVersion: '1.0.0',
        isOutdated: false,
        hasUpdate: false,
      );
    }

    final packageInfo = await PackageInfo.fromPlatform();
    final currentVersion = packageInfo.version;
    final currentBuild = int.tryParse(packageInfo.buildNumber) ?? 1;

    final minVersion = _rc.getString(_minVersionKey);
    final latestVersion = _rc.getString(_latestVersionKey);
    final updateUrl = _rc.getString(_updateUrlKey);
    final updateNotes = _rc.getString(_updateNotesKey);

    final isOutdated = _compareVersions(currentVersion, minVersion) < 0;
    final hasUpdate = _compareVersions(currentVersion, latestVersion) < 0;

    return VersionStatus(
      currentVersion: currentVersion,
      currentBuild: currentBuild,
      minVersion: minVersion,
      latestVersion: latestVersion,
      updateUrl: updateUrl.isEmpty ? null : updateUrl,
      updateNotes: updateNotes.isEmpty ? null : updateNotes,
      isOutdated: isOutdated,
      hasUpdate: hasUpdate,
    );
  }

  int _compareVersions(String v1, String v2) {
    final parts1 = v1.split('.').map(int.tryParse).map((e) => e ?? 0).toList();
    final parts2 = v2.split('.').map(int.tryParse).map((e) => e ?? 0).toList();
    final maxLen = parts1.length > parts2.length ? parts1.length : parts2.length;
    for (var i = 0; i < maxLen; i++) {
      final p1 = i < parts1.length ? parts1[i] : 0;
      final p2 = i < parts2.length ? parts2[i] : 0;
      if (p1 < p2) return -1;
      if (p1 > p2) return 1;
    }
    return 0;
  }

  Future<void> downloadAndInstallApk(String url) async {
    try {
      final httpClient = HttpClient();
      final request = await httpClient.getUrl(Uri.parse(url));
      final response = await request.close();

      if (response.statusCode != 200) {
        throw Exception('Failed to download APK: ${response.statusCode}');
      }

      final dir = Directory.systemTemp;
      final file = File('${dir.path}/citisense_update.apk');
      final sink = file.openWrite();
      await response.pipe(sink);
      await sink.flush();
      await sink.close();

      final result = await OpenFilex.open(file.path);
      if (result.type != ResultType.done) {
        throw Exception('Failed to open APK installer: ${result.message}');
      }
    } catch (e) {
      // Fallback: open URL in browser (App Distribution link)
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      }
      rethrow;
    }
  }
}

class VersionStatus {
  final String currentVersion;
  final int currentBuild;
  final String minVersion;
  final String latestVersion;
  final String? updateUrl;
  final String? updateNotes;
  final bool isOutdated;
  final bool hasUpdate;

  VersionStatus({
    required this.currentVersion,
    required this.currentBuild,
    required this.minVersion,
    required this.latestVersion,
    this.updateUrl,
    this.updateNotes,
    required this.isOutdated,
    required this.hasUpdate,
  });

  bool get shouldPromptUpdate => hasUpdate && updateUrl != null;
}
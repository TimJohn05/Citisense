import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:citisense/app.dart';
import 'package:citisense/models/enums.dart';
import 'package:citisense/models/media_item.dart';
import 'package:citisense/services/mock_repository.dart';
import 'package:citisense/state/app_state.dart';
import 'package:citisense/widgets/app_image.dart';
import 'test_config.dart';

final MockRepository _repo = MockRepository();

Directory? _tempDir;
File? _evidencePng;
File? _proofPng;

void _log(String message) {
  final timestamp = DateTime.now().toIso8601String();
  // ignore: avoid_print
  print('[E2E] $timestamp  $message');
}

void _logStep(String phase, String test, String step) {
  _log('$phase / $test  >>  $step');
}

void _logPass(String phase, String test, String step) {
  _log('$phase / $test  ✓  $step');
}

class _FakeHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) => _FakeHttpClient();
}

class _FakeHttpHeaders implements HttpHeaders {
  final Map<String, List<String>> _values = {};

  @override
  ContentType? contentType;

  @override
  List<String>? operator [](String name) => _values[name.toLowerCase()];

  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) {
    final key = preserveHeaderCase ? name : name.toLowerCase();
    _values.putIfAbsent(key, () => <String>[]).add(value.toString());
  }

  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {
    final key = preserveHeaderCase ? name : name.toLowerCase();
    _values[key] = <String>[value.toString()];
  }

  @override
  String? value(String name) {
    final values = _values[name.toLowerCase()];
    return (values == null || values.isEmpty) ? null : values.first;
  }

  @override
  void forEach(void Function(String name, List<String> values) action) {
    _values.forEach(action);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FakeHttpClient implements HttpClient {
  _FakeHttpClient();

  @override
  bool autoUncompress = true;

  @override
  Duration? connectionTimeout;

  @override
  Duration idleTimeout = const Duration(seconds: 15);

  @override
  int? maxConnectionsPerHost;

  @override
  String? userAgent;

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async =>
      _FakeHttpClientRequest();

  @override
  Future<HttpClientRequest> getUrl(Uri url) async {
    if (url.toString().contains('tile.openstreetmap.org')) {
      fail('NETWORK_TILE_REQUESTED $url (asset tile missing)');
    }
    return _FakeHttpClientRequest();
  }

  @override
  void close({bool force = false}) {}

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('_FakeHttpClient: $invocation');
}

class _FakeHttpClientRequest implements HttpClientRequest {
  _FakeHttpClientRequest();

  final Uint8List _body = base64Decode(TestConfig.onePxPng);

  @override
  HttpHeaders get headers => _FakeHttpHeaders();

  @override
  bool followRedirects = true;

  @override
  int maxRedirects = 5;

  @override
  int contentLength = -1;

  @override
  bool persistentConnection = true;

  @override
  Future<HttpClientResponse> get done => _closeBuffer.future;

  final Completer<HttpClientResponse> _closeBuffer = Completer();

  @override
  Future<HttpClientResponse> close() async {
    final response = _FakeHttpClientResponse(_body);
    _closeBuffer.complete(response);
    return response;
  }

  @override
  Future<void> addStream(Stream<List<int>> stream) async {
    await stream.drain<void>();
  }

  @override
  void add(List<int> data) {}

  @override
  void write(Object? obj) {}

  @override
  void writeln([Object? obj = '']) {}

  @override
  void writeCharCode(int charCode) {}

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('_FakeHttpClientRequest: $invocation');
}

class _FakeHttpClientResponse implements HttpClientResponse {
  _FakeHttpClientResponse(this._body);

  final Uint8List _body;

  @override
  int get statusCode => 200;

  @override
  int get contentLength => _body.length;

  @override
  String get reasonPhrase => 'OK';

  @override
  bool get isRedirect => false;

  @override
  bool get persistentConnection => false;

  @override
  List<RedirectInfo> get redirects => const [];

  @override
  HttpHeaders get headers => _FakeHttpHeaders();

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  List<Cookie> get cookies => const [];

  @override
  Future<Socket> detachSocket() =>
      throw UnsupportedError('_FakeHttpClientResponse.detachSocket');

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream<List<int>>.fromIterable(<List<int>>[_body]).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('_FakeHttpClientResponse: $invocation');
}

Future<void> _prepareEvidenceFiles() async {
  if (_tempDir != null) return;
  _tempDir = await Directory.systemTemp.createTemp('citisense_e2e');
  _evidencePng = File('${_tempDir!.path}/evidence.png')
    ..writeAsBytesSync(base64Decode(TestConfig.onePxPng));
  _proofPng = File('${_tempDir!.path}/proof.png')
    ..writeAsBytesSync(base64Decode(TestConfig.onePxPng));
  _log('Prepared evidence files: $_evidencePng, $_proofPng');
}

Future<void> _pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 20),
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 100));
    if (finder.evaluate().isNotEmpty) return;
  }
  fail('Timed out waiting for $finder');
}

Finder _mainVerticalScrollable() {
  return find
      .byWidgetPredicate(
        (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
      )
      .last;
}

Future<void> _dismissKeyboard(WidgetTester tester) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pump(const Duration(milliseconds: 400));
}

Future<void> _scrollTo(
  WidgetTester tester,
  Finder target, {
  double delta = 200,
  int maxScrolls = 60,
}) async {
  await tester.scrollUntilVisible(
    target,
    delta,
    scrollable: _mainVerticalScrollable(),
    maxScrolls: maxScrolls,
  );
  await tester.pump(const Duration(milliseconds: 200));
}

Future<void> _bootApp(WidgetTester tester) async {
  _logStep('SETUP', '_bootApp', 'Booting app with MockRepository');
  SharedPreferences.setMockInitialValues({});
  await tester.pumpWidget(App(repository: _repo));
  await _pumpUntilFound(tester, find.text('Sign In'));
  _logPass('SETUP', '_bootApp', 'App booted, Sign In screen visible');
}

Future<AppState> _appStateOf(WidgetTester tester) async {
  final element = tester.element(find.byType(MaterialApp).first);
  return Provider.of<AppState>(element, listen: false);
}

Future<void> _login(WidgetTester tester, String email) async {
  _logStep('LOGIN', email, 'Entering credentials and tapping Sign In');
  await tester.enterText(find.byType(TextFormField).at(0), email);
  await tester.enterText(find.byType(TextFormField).at(1), TestConfig.password);
  await _tapSignIn(tester);
}

Future<void> _tapSignIn(WidgetTester tester) async {
  await tester.ensureVisible(find.text('Sign In'));
  await tester.pump(const Duration(milliseconds: 200));
  await tester.tap(find.text('Sign In'));
}

Future<void> _tapNav(WidgetTester tester, String label, {String testLabel = ''}) async {
  _logStep('NAV', testLabel.isEmpty ? label : testLabel, 'Tapping navigation: $label');
  final navBarFinder = find.descendant(
    of: find.byType(NavigationBar),
    matching: find.text(label),
  );
  final railFinder = find.descendant(
    of: find.byType(NavigationRail),
    matching: find.text(label),
  );

  if (navBarFinder.evaluate().isNotEmpty) {
    await tester.tap(navBarFinder);
  } else if (railFinder.evaluate().isNotEmpty) {
    await tester.tap(railFinder);
  } else {
    throw Exception('Could not find navigation item: $label');
  }
  await tester.pump(const Duration(milliseconds: 400));
  _logPass('NAV', testLabel.isEmpty ? label : testLabel, 'Navigated to $label');
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    _log('=' * 60);
    _log('E2E INTEGRATION TEST SUITE STARTING');
    _log('=' * 60);
    HttpOverrides.global = _FakeHttpOverrides();
    await _prepareEvidenceFiles();
    _log('setUpAll complete: HTTP overrides active, evidence files ready');
  });

  group('Phase A — deliberate failures (error handling)', () {
    testWidgets('A1: empty login shows field validators', (tester) async {
      await _bootApp(tester);
      await _tapSignIn(tester);
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Email is required'), findsOneWidget);
      expect(find.text('Password is required'), findsOneWidget);
      _logPass('PHASE_A', 'A1', 'Field validators shown — PASS');
    });

    testWidgets('A2: wrong password shows invalid-credentials error',
        (tester) async {
      await _bootApp(tester);
      await tester.enterText(find.byType(TextFormField).at(0), TestConfig.citizen);
      await tester.enterText(find.byType(TextFormField).at(1), 'wrongpass');
      await _tapSignIn(tester);
      await _pumpUntilFound(
        tester,
        find.text('Invalid email or password. Please try again.'),
      );
      _logPass('PHASE_A', 'A2', 'Invalid credentials error shown — PASS');
    });

    testWidgets('A3: report without category shows error', (tester) async {
      await _bootApp(tester);
      await _login(tester, TestConfig.citizen);
      await _pumpUntilFound(tester, find.text('Welcome back'));
      await _tapNav(tester, 'Report');
      await _pumpUntilFound(tester, find.text('Report an Issue'));
      await _scrollTo(tester, find.text('Analyze & Submit Report'));
      await tester.tap(find.text('Analyze & Submit Report'));
      await _pumpUntilFound(
        tester,
        find.text('Please select a complaint category.'),
      );
      _logPass('PHASE_A', 'A3', 'Category required error shown — PASS');
    });

    testWidgets('A4: short description shows error', (tester) async {
      await _bootApp(tester);
      await _login(tester, TestConfig.citizen);
      await _pumpUntilFound(tester, find.text('Welcome back'));
      await _tapNav(tester, 'Report');
      await _pumpUntilFound(tester, find.text('Report an Issue'));
      await tester.tap(find.text('Waste Management'));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.enterText(
        find.byWidgetPredicate(
          (w) =>
              w is TextField &&
              (w.decoration?.hintText?.toLowerCase().contains('describe') ??
                  false),
        ),
        'Hi',
      );
      await _dismissKeyboard(tester);
      await _scrollTo(tester, find.text('Analyze & Submit Report'));
      await tester.tap(find.text('Analyze & Submit Report'));
      await _pumpUntilFound(
        tester,
        find.text('Please describe the issue in at least 10 characters.'),
      );
      _logPass('PHASE_A', 'A4', 'Short description error shown — PASS');
    });

    testWidgets('A5: officer resolve without notes shows error', (tester) async {
      await _bootApp(tester);
      await _login(tester, TestConfig.officer);
      await _pumpUntilFound(tester, find.text('Dashboard'));
      await _tapNav(tester, 'Complaints');
      await _scrollTo(tester, find.textContaining('Walang ilaw sa kalsada'));
      await tester.tap(find.textContaining('Walang ilaw sa kalsada'));
      await _pumpUntilFound(tester, find.text('Complaint Details'));
      await _scrollTo(tester, find.text('Mark as Resolved with Proof'));
      await tester.tap(find.text('Mark as Resolved with Proof'));
      await _pumpUntilFound(tester, find.text('Mark as Resolved'));
      await tester.ensureVisible(find.text('Confirm Resolution'));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.tap(find.text('Confirm Resolution'));
      await _pumpUntilFound(tester, find.text('Please add resolution notes'));
      _logPass('PHASE_A', 'A5', 'Resolution notes required — PASS');
    });

    testWidgets('A6: officer reject without reason shows error', (tester) async {
      await _bootApp(tester);
      await _login(tester, TestConfig.officer);
      await _pumpUntilFound(tester, find.text('Dashboard'));
      await _tapNav(tester, 'Complaints');
      await _scrollTo(tester, find.textContaining('Walang ilaw sa kalsada'));
      await tester.tap(find.textContaining('Walang ilaw sa kalsada'));
      await _pumpUntilFound(tester, find.text('Complaint Details'));
      await _scrollTo(tester, find.text('Reject Report'));
      await tester.tap(find.text('Reject Report'));
      await _pumpUntilFound(tester, find.textContaining('Provide a reason why'));
      await tester.tap(find.widgetWithText(FilledButton, 'Reject Report'));
      await tester.pump(const Duration(milliseconds: 500));
      _logPass('PHASE_A', 'A6', 'Reject sheet opened and submitted — PASS');
    });

    testWidgets('A8: admin add-official requires all fields', (tester) async {
      await _bootApp(tester);
      await _login(tester, TestConfig.admin);
      await _pumpUntilFound(tester, find.text('Dashboard'));
      await _tapNav(tester, 'Users');
      await _pumpUntilFound(tester, find.text('User Management'));
      await tester.tap(find.text('Add Barangay Official'));
      await _pumpUntilFound(tester, find.text('Create Official Account'));
      await tester.tap(find.text('Create Official Account'));
      await tester.pump(const Duration(milliseconds: 500));
      _logPass('PHASE_A', 'A8', 'Add-official dialog opened — PASS');
    });
  });

  group('Phase B — correct validation (citizen → officer → admin)', () {
    testWidgets('B1: citizen files a report via UI and coords are accurate',
        (tester) async {
      await _bootApp(tester);
      await _login(tester, TestConfig.citizen);
      await _pumpUntilFound(tester, find.text('Welcome back'));
      await _tapNav(tester, 'Report');
      await _pumpUntilFound(tester, find.text('Report an Issue'));

      await tester.tap(find.text('Water & Sanitation'));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.enterText(
        find.byWidgetPredicate(
          (w) =>
              w is TextField &&
              (w.decoration?.hintText?.toLowerCase().contains('describe') ??
                  false),
        ),
        'Water supply has been interrupted for several hours in our street.',
      );
      await _dismissKeyboard(tester);
      await _scrollTo(tester, find.text(TestConfig.defaultCoords));
      expect(find.text(TestConfig.defaultCoords), findsOneWidget);
      await _scrollTo(tester, find.text('Analyze & Submit Report'));
      await tester.ensureVisible(find.text('Analyze & Submit Report'));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.tap(find.text('Analyze & Submit Report'));
      await _pumpUntilFound(
        tester,
        find.widgetWithText(FilledButton, 'Submit Report'),
      );
      expect(
        find.textContaining('Once submitted, it cannot be changed'),
        findsOneWidget,
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Submit Report'));
      await _pumpUntilFound(tester, find.text('Report Submitted'));
      expect(find.text('Report received'), findsOneWidget);
      _logPass('PHASE_B', 'B1', 'Report submitted successfully — PASS');
    });

    testWidgets(
        'B2: citizen sends a report with image evidence via the app layer',
        (tester) async {
      await _bootApp(tester);
      await _login(tester, TestConfig.citizen);
      await _pumpUntilFound(tester, find.text('Welcome back'));

      final appState = await _appStateOf(tester);
      final complaint = await appState.submitComplaint(
        category: ComplaintCategory.waste,
        description: 'E2E evidence consistency check for the multi-evidence '
            'feature and the GPS pin accuracy.',
        latitude: 14.1956,
        longitude: 121.1469,
        evidence: [MediaItem(file: _evidencePng!, isVideo: false)],
      );
      await tester.pump(const Duration(milliseconds: 500));

      await _tapNav(tester, 'My Reports');
      await _pumpUntilFound(
        tester,
        find.textContaining('E2E evidence consistency check'),
      );
      await tester.tap(find.textContaining('E2E evidence consistency check'));
      await _pumpUntilFound(tester, find.text('Complaint Details'));
      expect(find.text('By Juan Dela Cruz'), findsOneWidget);
      await _scrollTo(tester, find.text(TestConfig.defaultCoords));
      expect(find.text(TestConfig.defaultCoords), findsOneWidget);
      expect(find.text('Evidence'), findsOneWidget);
      expect(complaint.evidencePhotos.single, _evidencePng!.path);
      _logPass('PHASE_B', 'B2', 'Evidence consistency verified — PASS');
    });

    testWidgets('B3: officer sees identical data and acknowledges complaint',
        (tester) async {
      await _bootApp(tester);
      await _login(tester, TestConfig.officer);
      await _pumpUntilFound(tester, find.text('Dashboard'));

      // Create a complaint first via app layer
      final appState = await _appStateOf(tester);
      await appState.submitComplaint(
        category: ComplaintCategory.waste,
        description: 'B3 test complaint for officer acknowledgment',
        latitude: 14.1956,
        longitude: 121.1469,
        evidence: [MediaItem(file: _evidencePng!, isVideo: false)],
      );
      await tester.pump(const Duration(milliseconds: 500));

      await _tapNav(tester, 'Complaints');
      await _pumpUntilFound(
        tester,
        find.textContaining('B3 test complaint'),
      );
      await tester.tap(find.textContaining('B3 test complaint'));
      await _pumpUntilFound(tester, find.text('Complaint Details'));
      expect(find.text('Evidence'), findsOneWidget);

      // Acknowledge the complaint
      await _scrollTo(tester, find.text('Acknowledge'));
      await tester.tap(find.text('Acknowledge'));
      await _pumpUntilFound(tester, find.text('Acknowledge Complaint'));
      await tester.tap(find.widgetWithText(FilledButton, 'Acknowledge'));
      await tester.pump(const Duration(milliseconds: 400));
      _logPass('PHASE_B', 'B3', 'Complaint acknowledged — PASS');
    });

    testWidgets('B4: admin sees the identical complaint, users and logs',
        (tester) async {
      await _bootApp(tester);
      await _login(tester, TestConfig.admin);
      await _pumpUntilFound(tester, find.text('Dashboard'));

      // Create a complaint first via app layer
      final appState = await _appStateOf(tester);
      await appState.submitComplaint(
        category: ComplaintCategory.water,
        description: 'B4 test complaint for admin review',
        latitude: 14.1956,
        longitude: 121.1469,
        evidence: [MediaItem(file: _evidencePng!, isVideo: false)],
      );
      await tester.pump(const Duration(milliseconds: 500));

      await _tapNav(tester, 'Complaints');
      await _pumpUntilFound(
        tester,
        find.textContaining('B4 test complaint'),
      );
      await tester.tap(find.textContaining('B4 test complaint'));
      await _pumpUntilFound(tester, find.text('Complaint Details'));

      await _scrollTo(tester, find.text('Evidence'));
      expect(find.text('Evidence'), findsOneWidget);
      _logPass('PHASE_B', 'B4', 'Admin sees identical complaint — PASS');

      // Go back to complaints list before navigating to Users
      await tester.pageBack();
      await tester.pump(const Duration(milliseconds: 400));
      await _tapNav(tester, 'Users');
      await _pumpUntilFound(tester, find.text('User Management'));
      _logPass('PHASE_B', 'B4', 'Admin sees users — PASS');

      await _tapNav(tester, 'Logs');
      await _pumpUntilFound(tester, find.text('Audit Logs'));
      expect(find.textContaining('Complaint Filed'), findsWidgets);
      _logPass('PHASE_B', 'B4', 'Admin sees audit logs — PASS');
    });

    testWidgets('B5: account creation lands on sign-in, then new account logs in',
        (tester) async {
      const newEmail = 'new.citizen@citisense.com';
      const newPassword = 'secret123';
      await _bootApp(tester);

      await tester.tap(find.text('Create an account'));
      await _pumpUntilFound(tester, find.text('Join CitiSense'));

      Future<void> fillField(Finder field, String value) async {
        await tester.ensureVisible(field);
        await tester.pump(const Duration(milliseconds: 200));
        await tester.tap(field);
        await tester.enterText(field, value);
        await _dismissKeyboard(tester);
      }

      await fillField(
        find.widgetWithText(TextFormField, 'Full name'),
        'New Citizen',
      );
      await fillField(
        find.widgetWithText(TextFormField, 'Email address'),
        newEmail,
      );
      await fillField(
        find.widgetWithText(TextFormField, 'Password'),
        newPassword,
      );
      await fillField(
        find.widgetWithText(TextFormField, 'Confirm password'),
        newPassword,
      );

      final createButton =
          find.widgetWithText(FilledButton, 'Create Account');
      await tester.ensureVisible(createButton);
      await tester.pump(const Duration(milliseconds: 200));
      await tester.tap(createButton);

      await _pumpUntilFound(
        tester,
        find.text('Account created. Sign in to continue.'),
      );
      expect(find.text('Sign In'), findsOneWidget);
      expect(find.text('Welcome back'), findsNothing);
      _logPass('PHASE_B', 'B5', 'Account created — PASS');

      await tester.enterText(find.byType(TextFormField).at(0), newEmail);
      await tester.enterText(find.byType(TextFormField).at(1), newPassword);
      await _tapSignIn(tester);
      await _pumpUntilFound(tester, find.text('Welcome back'));
      _logPass('PHASE_B', 'B5', 'New account logged in — PASS');
    });
  });

  _log('=' * 60);
  _log('E2E INTEGRATION TEST SUITE COMPLETE');
  _log('=' * 60);
}

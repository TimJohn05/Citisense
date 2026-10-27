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

class _FakeHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) => _FakeHttpClient();
}

class _FakeHttpHeaders implements HttpHeaders {
  final Map<String, List<String>> _values = {};

  @override
  ContentType? contentType;

  @override
  List<String>? operator [](String name) =>
      _values[name.toLowerCase()];

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

Future<void> _scrollDownUntilFound(
  WidgetTester tester,
  Finder target, {
  int maxDrags = 30,
}) async {
  final scrollable = _mainVerticalScrollable();
  for (var i = 0; i < maxDrags; i++) {
    await tester.pump(const Duration(milliseconds: 100));
    if (target.evaluate().isNotEmpty) {
      await tester.ensureVisible(target.first);
      await tester.pump(const Duration(milliseconds: 200));
      return;
    }
    await tester.drag(scrollable, const Offset(0, -200));
  }
  fail('Timed out scrolling for $target after $maxDrags drags');
}

Future<void> _scrollToTop(WidgetTester tester) async {
  await tester.scrollUntilVisible(
    find.text('Submitted'),
    -200,
    scrollable: _mainVerticalScrollable(),
    maxScrolls: 60,
  );
  await tester.pump(const Duration(milliseconds: 200));
}

Future<void> _bootApp(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  await tester.pumpWidget(App(repository: _repo));
  await _pumpUntilFound(tester, find.text('Sign In'));
}

Future<AppState> _appStateOf(WidgetTester tester) async {
  final element = tester.element(find.byType(MaterialApp).first);
  return Provider.of<AppState>(element, listen: false);
}

Future<void> _login(WidgetTester tester, String email) async {
  await tester.enterText(find.byType(TextFormField).at(0), email);
  await tester.enterText(find.byType(TextFormField).at(1), TestConfig.password);
  await _tapSignIn(tester);
}

Future<void> _tapSignIn(WidgetTester tester) async {
  await tester.ensureVisible(find.text('Sign In'));
  await tester.pump(const Duration(milliseconds: 200));
  await tester.tap(find.text('Sign In'));
}

Future<void> _logout(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Sign out'));
  await _pumpUntilFound(tester, find.widgetWithText(FilledButton, 'Sign out'));
  await tester.tap(find.widgetWithText(FilledButton, 'Sign out'));
  await _pumpUntilFound(tester, find.text('Sign In'));
}

Future<void> _tapNav(WidgetTester tester, String label) async {
  // Try NavigationBar first (narrow screens), then NavigationRail (wide screens)
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
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    HttpOverrides.global = _FakeHttpOverrides();
    await _prepareEvidenceFiles();
  });

  group('Phase A — deliberate failures (error handling)', () {
    testWidgets('A1: empty login shows field validators', (tester) async {
      await _bootApp(tester);
      await _tapSignIn(tester);
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Email is required'), findsOneWidget);
      expect(find.text('Password is required'), findsOneWidget);
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
      expect(find.text('Incorrect'), findsNothing);
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
    });

    testWidgets(
        'A5-A7: officer resolve/reject guards (notes, proof, reject reason)',
        (tester) async {
      await _bootApp(tester);
      await _login(tester, TestConfig.officer);
      await _pumpUntilFound(tester, find.text('Dashboard'));
      await _tapNav(tester, 'Complaints');
      await _scrollTo(tester, find.textContaining('Garbage pile'));
      await tester.tap(find.textContaining('Garbage pile'));
      await _pumpUntilFound(tester, find.text('Complaint Details'));

      await _scrollTo(tester, find.text('Mark as Resolved with Proof'));
      await tester.tap(find.text('Mark as Resolved with Proof'));
      await _pumpUntilFound(tester, find.text('Mark as Resolved'));
      await tester.ensureVisible(find.text('Confirm Resolution'));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.tap(find.text('Confirm Resolution'));
      await _pumpUntilFound(tester, find.text('Please add resolution notes'));

      await tester.enterText(
        find.byWidgetPredicate(
          (w) =>
              w is TextField &&
              (w.decoration?.labelText == 'Resolution notes'),
        ),
        'Cleanup crew cleared the pile.',
      );
      await tester.tap(find.text('Confirm Resolution'));
      await _pumpUntilFound(
        tester,
        find.textContaining(
          'At least one proof photo or video is required to resolve',
        ),
      );

      await tester.tapAt(const Offset(20, 60));
      await tester.pump(const Duration(milliseconds: 600));

      await tester.pump(const Duration(seconds: 5));
      await tester.ensureVisible(
        find.widgetWithText(OutlinedButton, 'Reject Report'),
      );
      await tester.pump(const Duration(milliseconds: 200));
      await tester.tap(find.widgetWithText(OutlinedButton, 'Reject Report'));
      await _pumpUntilFound(
        tester,
        find.textContaining('Provide a reason why'),
      );
      await tester.ensureVisible(find.widgetWithText(FilledButton, 'Reject Report'));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.tap(find.widgetWithText(FilledButton, 'Reject Report'));
      await _pumpUntilFound(
        tester,
        find.text('Please provide a rejection reason'),
      );

      await tester.tapAt(const Offset(20, 60));
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pageBack();
      await _pumpUntilFound(tester, find.textContaining('Garbage pile'));
      await _logout(tester);
    });

    testWidgets('A8: admin add-official requires all fields', (tester) async {
      await _bootApp(tester);
      await _login(tester, TestConfig.admin);
      await _pumpUntilFound(tester, find.text('Dashboard'));
      await _tapNav(tester, 'Users');
      await _pumpUntilFound(tester, find.text('User Management'));
      await tester.tap(find.text('Add Barangay Official'));
      await _pumpUntilFound(tester, find.text('Create Official Account'));
      await tester.ensureVisible(find.text('Create Official Account'));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.tap(find.text('Create Official Account'));
      await _pumpUntilFound(tester, find.text('All fields are required'));
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

      await tester.tap(find.text('Back to Home'));
      await _pumpUntilFound(tester, find.text('Welcome back'));
      await _tapNav(tester, 'My Reports');
      await _pumpUntilFound(
        tester,
        find.textContaining('Water supply has been interrupted'),
      );
      await tester.tap(
        find.textContaining('Water supply has been interrupted'),
      );
      await _pumpUntilFound(tester, find.text('Complaint Details'));
      expect(find.text('By Juan Dela Cruz'), findsOneWidget);
      await _scrollTo(tester, find.text(TestConfig.defaultCoords));
      expect(find.text(TestConfig.defaultCoords), findsOneWidget);
    });

    testWidgets(
        'B2: citizen sends a report with image evidence via the app layer '
        '— the SAME complaint must be identical for officer and admin',
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
      expect(find.byType(TapToZoomImage), findsWidgets);
      expect(complaint.evidencePhotos.single, _evidencePng!.path);
    });

    testWidgets('B3: officer sees identical data, ack + resolves with proof',
        (tester) async {
      await _bootApp(tester);
      await _login(tester, TestConfig.officer);
      await _pumpUntilFound(tester, find.text('Dashboard'));
      await _tapNav(tester, 'Complaints');
      await _pumpUntilFound(
        tester,
        find.textContaining('E2E evidence consistency check'),
      );
      await tester.tap(find.textContaining('E2E evidence consistency check'));
      await _pumpUntilFound(tester, find.text('Complaint Details'));
      await _scrollToTop(tester);

      expect(find.text('By Juan Dela Cruz'), findsOneWidget);
      expect(find.text(TestConfig.defaultCoords), findsOneWidget);
      expect(find.text('Evidence'), findsOneWidget);
      expect(find.byType(TapToZoomImage), findsOneWidget);

      await _scrollTo(tester, find.text('Acknowledge & Under Review'));
      await tester.ensureVisible(find.text('Acknowledge & Under Review'));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.tap(find.text('Acknowledge & Under Review'));
      await _pumpUntilFound(tester, find.text('Acknowledge Complaint'));
      await tester.ensureVisible(find.text('Acknowledge'));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.tap(find.text('Acknowledge'));
      await tester.pump(const Duration(milliseconds: 400));

      final appState = await _appStateOf(tester);
      final target = appState.complaints
          .firstWhere((c) =>
              c.description.startsWith('E2E evidence consistency check'));
      await appState.resolveComplaint(
        target,
        notes: 'Cleanup crew cleared the reported area.',
        proof: [MediaItem(file: _proofPng!, isVideo: false)],
      );
      await tester.pump(const Duration(milliseconds: 500));

      await tester.pageBack();
      await _pumpUntilFound(
        tester,
        find.textContaining('E2E evidence consistency check'),
      );
      await tester.tap(find.textContaining('E2E evidence consistency check').first);
      await _pumpUntilFound(tester, find.text('Complaint Details'));
      await _scrollDownUntilFound(tester, find.text('Resolution proof'));
      expect(find.text('Resolution proof'), findsOneWidget);
      expect(
        find.textContaining('Resolved by Hon. Jose Santos'),
        findsOneWidget,
      );
      expect(find.byType(TapToZoomImage), findsWidgets);
    });

    testWidgets('B4: admin sees the identical complaint, users and logs',
        (tester) async {
      await _bootApp(tester);
      await _login(tester, TestConfig.admin);
      await _pumpUntilFound(tester, find.text('Dashboard'));

      await _tapNav(tester, 'Complaints');
      await _pumpUntilFound(
        tester,
        find.textContaining('E2E evidence consistency check'),
      );
      await tester.tap(find.textContaining('E2E evidence consistency check'));
      await _pumpUntilFound(tester, find.text('Complaint Details'));

      expect(find.text('By Juan Dela Cruz'), findsOneWidget);
      await _scrollTo(tester, find.text('Evidence'));
      expect(find.text('Evidence'), findsOneWidget);
      expect(find.byType(TapToZoomImage), findsWidgets);
      await _scrollTo(tester, find.text(TestConfig.defaultCoords));
      expect(find.text(TestConfig.defaultCoords), findsOneWidget);
      await _scrollDownUntilFound(tester, find.text('Resolution proof'));
      expect(find.text('Resolution proof'), findsOneWidget);
      expect(find.byType(TapToZoomImage), findsWidgets);
      expect(
        find.textContaining('Resolved by Hon. Jose Santos'),
        findsOneWidget,
      );

      await tester.pageBack();
      await _pumpUntilFound(
        tester,
        find.textContaining('E2E evidence consistency check'),
      );
      await _tapNav(tester, 'Users');
      await _pumpUntilFound(tester, find.text('User Management'));
      expect(find.text('Juan Dela Cruz'), findsOneWidget);
      expect(find.text('Hon. Jose Santos'), findsOneWidget);

      await _tapNav(tester, 'Logs');
      await _pumpUntilFound(tester, find.text('Audit Logs'));
      expect(find.textContaining('Complaint Filed'), findsWidgets);
      expect(find.textContaining('Complaint Updated'), findsWidgets);
      expect(find.textContaining('E2E evidence consistency check'),
          findsNothing);
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

      // Success indicator, back on the sign-in screen — not auto-logged-in.
      await _pumpUntilFound(
        tester,
        find.text('Account created. Sign in to continue.'),
      );
      expect(find.text('Sign In'), findsOneWidget);
      expect(find.text('Welcome back'), findsNothing);

      // The freshly created account can sign in.
      await tester.enterText(find.byType(TextFormField).at(0), newEmail);
      await tester.enterText(find.byType(TextFormField).at(1), newPassword);
      await _tapSignIn(tester);
      await _pumpUntilFound(tester, find.text('Welcome back'));
      await _logout(tester);
    });
  });
}
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:citisense/widgets/app_image.dart';

void main() {
  const transparentPngDataUri =
      'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAA'
      'AADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==';

  testWidgets('renders an embedded data-URI image', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: AppImage(path: transparentPngDataUri)),
    );
    await tester.pump();
    expect(find.byType(Image), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('falls back to placeholder when a network image fails',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AppImage(path: 'https://example.invalid/nope.jpg'),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byIcon(Icons.image_outlined), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows placeholder when path is null', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AppImage(path: null)));
    expect(find.byIcon(Icons.image_outlined), findsOneWidget);
  });
}
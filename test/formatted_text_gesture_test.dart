import 'package:convetchat/core/di/locator.dart';
import 'package:convetchat/core/widgets/formatted_text.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:talker_flutter/talker_flutter.dart';

void main() {
  setUp(() {
    if (!getIt.isRegistered<Talker>()) {
      getIt.registerSingleton<Talker>(Talker());
    }
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/url_launcher'),
          (call) async => true,
        );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/url_launcher'),
          null,
        );
    if (getIt.isRegistered<Talker>()) {
      getIt.unregister<Talker>();
    }
  });

  Future<void> pumpLink(
    WidgetTester tester,
    String html, {
    required List<String> fired,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => fired.add('outer'),
            onDoubleTap: () => fired.add('outer-double'),
            onLongPress: () => fired.add('outer-long'),
            child: FormattedText(
              html: html,
              style: const TextStyle(fontSize: 15, color: Color(0xFF000000)),
              onLinkTap: () => fired.add('inner'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byType(RichText));
    await tester.pump(const Duration(milliseconds: 800));
  }

  testWidgets('tap on nested html link fires link, not bubble', (tester) async {
    final fired = <String>[];
    await pumpLink(
      tester,
      '<a href="https://example.com/"><b>go</b> here</a>',
      fired: fired,
    );
    expect(fired, contains('inner'));
    expect(fired, isNot(contains('outer')));
  });

  testWidgets('tap on plain mention pill fires link, not bubble', (
    tester,
  ) async {
    final fired = <String>[];
    await pumpLink(
      tester,
      '<a href="https://matrix.to/#/@alice:example.org">Alice</a>',
      fired: fired,
    );
    expect(fired, contains('inner'));
    expect(fired, isNot(contains('outer')));
  });

  testWidgets('tap on plain-text url fires link, not bubble', (tester) async {
    final fired = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => fired.add('outer'),
            onDoubleTap: () => fired.add('outer-double'),
            onLongPress: () => fired.add('outer-long'),
            child: FormattedText.plain(
              'see https://example.com/ now',
              style: const TextStyle(fontSize: 15, color: Color(0xFF000000)),
              onLinkTap: () => fired.add('inner'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byType(RichText));
    await tester.pump(const Duration(milliseconds: 800));
    expect(fired, contains('inner'));
    expect(fired, isNot(contains('outer')));
  });

  testWidgets('tap on plain text fires bubble', (tester) async {
    final fired = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => fired.add('outer'),
            onDoubleTap: () => fired.add('outer-double'),
            onLongPress: () => fired.add('outer-long'),
            child: FormattedText.plain(
              'just text',
              style: const TextStyle(fontSize: 15, color: Color(0xFF000000)),
              onLinkTap: () => fired.add('inner'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byType(RichText));
    await tester.pump(const Duration(milliseconds: 800));
    expect(fired, isNot(contains('inner')));
    expect(fired, contains('outer'));
  });
}

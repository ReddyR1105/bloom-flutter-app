import 'dart:async';
import 'package:bloom/integration/bloom_gateway.dart';
import 'package:bloom/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'ui_flows_test.dart' show UiTestGateway;

void main() {
  testWidgets('opens repository once and closes it with app disposal', (
    tester,
  ) async {
    final repository = UiTestGateway();
    var calls = 0;
    await tester.pumpWidget(
      BloomBootstrap(
        open: () async {
          calls++;
          return repository;
        },
      ),
    );
    await tester.pumpAndSettle();
    expect(calls, 1);
    expect(find.textContaining('No habits here yet'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    expect(repository.closed, true);
  });
  testWidgets(
    'startup error preserves records and explicit retry can recover',
    (tester) async {
      final repository = UiTestGateway();
      repository.addHabit();
      var attempts = 0;
      await tester.pumpWidget(
        BloomBootstrap(
          open: () async {
            if (++attempts == 1) throw StateError('Database unavailable.');
            return repository;
          },
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('have not been deleted'), findsOneWidget);
      expect(find.textContaining('Database unavailable'), findsOneWidget);
      await tester.tap(find.text('Retry opening Bloom'));
      await tester.pumpAndSettle();
      expect(attempts, 2);
      expect(find.text('Read'), findsOneWidget);
    },
  );
  testWidgets('opening completed after disposal closes orphaned repository', (
    tester,
  ) async {
    final pending = Completer<BloomGateway>();
    final repository = UiTestGateway();
    await tester.pumpWidget(BloomBootstrap(open: () => pending.future));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    pending.complete(repository);
    await tester.pump();
    expect(repository.closed, true);
    expect(tester.takeException(), isNull);
  });
}

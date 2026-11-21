import 'package:arrowpathpuzzle/app/core/constants/storage_keys.dart';
import 'package:arrowpathpuzzle/app/core/utils/day.dart';
import 'package:arrowpathpuzzle/app/data/services/progress_service.dart';
import 'package:arrowpathpuzzle/app/routes/app_routes.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'helpers/test_app.dart';

/// Regression: Home showed a GetX "improper use" error box in the Daily
/// card once today's daily puzzle was solved.
void main() {
  tearDown(Get.reset);

  Future<void> pumpFor(WidgetTester t, Duration d) async {
    for (var i = 0; i < d.inMilliseconds ~/ 100; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> cleanUp(WidgetTester t) async {
    await t.pumpWidget(const SizedBox());
    await pumpFor(t, const Duration(seconds: 3));
  }

  testWidgets('home renders when today is already solved', (t) async {
    await setupServices(
      tweak: (s) => s.m[StorageKeys.dailySolved] = [Day.todayKey()],
    );
    await t.pumpWidget(app(Routes.shell));
    await pumpFor(t, const Duration(seconds: 1));
    expect(t.takeException(), isNull);
    expect(find.text('Solved today. See you tomorrow!'), findsOneWidget);
    await cleanUp(t);
  });

  testWidgets('daily card updates live after solving', (t) async {
    await setupServices(
      tweak: (s) => s.m[StorageKeys.dailySolved] = <String>[],
    );
    await t.pumpWidget(app(Routes.shell));
    await pumpFor(t, const Duration(seconds: 1));
    expect(find.textContaining('Resets in'), findsOneWidget);

    await Get.find<ProgressService>().recordDailySolve(DateTime.now());
    await pumpFor(t, const Duration(milliseconds: 500));

    expect(t.takeException(), isNull);
    expect(find.text('Solved today. See you tomorrow!'), findsOneWidget);
    await cleanUp(t);
  });
}

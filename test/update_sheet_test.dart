import 'dart:async';

import 'package:arrowpathpuzzle/app/modules/update/update_sheets.dart';
import 'package:arrowpathpuzzle/app/routes/app_routes.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'helpers/test_app.dart';

void main() {
  tearDown(Get.reset);

  Future<void> pumpFor(WidgetTester t, Duration d) async {
    for (var i = 0; i < d.inMilliseconds ~/ 100; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }
  }

  Future<bool?> open(WidgetTester t, Future<bool?> Function() show) async {
    await setupServices();
    await t.pumpWidget(app(Routes.shell));
    await pumpFor(t, const Duration(seconds: 1));
    expect(UpdateSheets.canShowNow, isTrue);
    bool? result;
    unawaited(show().then((v) => result = v));
    await pumpFor(t, const Duration(milliseconds: 600));
    return result;
  }

  testWidgets('"Update now" accepts, "Later" declines', (t) async {
    await open(t, UpdateSheets.updateAvailable);
    expect(find.text('New update available'), findsOneWidget);
    expect(t.takeException(), isNull);

    bool? result;
    await t.tap(find.text('Update now'));
    await pumpFor(t, const Duration(milliseconds: 600));
    expect(find.text('New update available'), findsNothing);

    unawaited(UpdateSheets.updateAvailable().then((v) => result = v));
    await pumpFor(t, const Duration(milliseconds: 600));
    await t.tap(find.text('Later'));
    await pumpFor(t, const Duration(milliseconds: 600));
    expect(result, isFalse);

    await t.pumpWidget(const SizedBox());
    await pumpFor(t, const Duration(seconds: 3));
  });

  testWidgets('"Update ready" offers a restart', (t) async {
    await open(t, UpdateSheets.updateReady);
    expect(find.text('Update ready'), findsOneWidget);
    expect(find.text('Restart now'), findsOneWidget);
    expect(t.takeException(), isNull);
    await t.pumpWidget(const SizedBox());
    await pumpFor(t, const Duration(seconds: 3));
  });
}

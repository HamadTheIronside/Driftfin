import 'package:flutter_test/flutter_test.dart';

import 'package:driftfin/jellyfin/jellyfin_open_api.enums.swagger.dart';
import 'package:driftfin/util/extensions/task_trigger_type_extensions.dart';

void main() {
  group('TaskTriggerTypeExtensions.isUnknown', () {
    test('is true only for swaggerGeneratedUnknown', () {
      expect(TaskTriggerInfoType.swaggerGeneratedUnknown.isUnknown, isTrue);
      expect(TaskTriggerInfoType.intervaltrigger.isUnknown, isFalse);
      expect(TaskTriggerInfoType.dailytrigger.isUnknown, isFalse);
      expect(TaskTriggerInfoType.weeklytrigger.isUnknown, isFalse);
      expect(TaskTriggerInfoType.startuptrigger.isUnknown, isFalse);
    });
  });

  // label() requires a BuildContext with localization set up, which pulls in
  // the widget tree/localization delegates. That is covered indirectly by
  // widget tests elsewhere; here we only test the pure isUnknown logic.
}

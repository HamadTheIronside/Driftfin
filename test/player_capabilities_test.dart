// Verifies the BasePlayer capability matrix (issue #47): every backend must
// report an explicit PlayerCapabilities value, and UI-relevant capabilities
// must be honest about what each engine can actually do.
import 'package:flutter_test/flutter_test.dart';

import 'package:driftfin/stubs/web/lib_mdk_web.dart' as web_stub;
import 'package:driftfin/wrappers/players/lib_mdk.dart';
import 'package:driftfin/wrappers/players/lib_mpv.dart';
import 'package:driftfin/wrappers/players/native_player.dart';
import 'package:driftfin/wrappers/players/player_capabilities.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BasePlayer capability matrix', () {
    test('LibMPV (the default, real mpv engine) supports the full feature set', () {
      final capabilities = LibMPV().capabilities;
      expect(capabilities.screenshots, isTrue);
      expect(capabilities.audioDsp, isTrue);
      expect(capabilities.ambientGlow, isTrue);
      expect(capabilities.errorReporting, isTrue);
      expect(capabilities.subtitleDelay, isTrue);
      expect(capabilities.crossfade, isTrue);
    });

    test('LibMDK (FVP/mdk) supports screenshots and subtitle delay only', () {
      final capabilities = LibMDK().capabilities;
      expect(capabilities.screenshots, isTrue);
      expect(capabilities.subtitleDelay, isTrue);
      expect(capabilities.audioDsp, isFalse);
      expect(capabilities.ambientGlow, isFalse);
      expect(capabilities.errorReporting, isFalse);
      expect(capabilities.crossfade, isFalse);
    });

    test('NativePlayer (Android-TV ExoPlayer) gray-zones audio DSP and screenshots', () {
      final capabilities = NativePlayer().capabilities;
      expect(capabilities.subtitleDelay, isTrue);
      expect(capabilities.screenshots, isFalse);
      expect(capabilities.audioDsp, isFalse);
      expect(capabilities.ambientGlow, isFalse);
      expect(capabilities.errorReporting, isFalse);
      expect(capabilities.crossfade, isFalse);
    });

    test('web stub reports no optional capabilities', () {
      expect(web_stub.LibMDK().capabilities, PlayerCapabilities.none);
    });

    test('no capability is silently true-by-default', () {
      expect(const PlayerCapabilities(), PlayerCapabilities.none);
      expect(PlayerCapabilities.none.screenshots, isFalse);
      expect(PlayerCapabilities.none.audioDsp, isFalse);
      expect(PlayerCapabilities.none.ambientGlow, isFalse);
      expect(PlayerCapabilities.none.perTitleZoomPan, isFalse);
      expect(PlayerCapabilities.none.errorReporting, isFalse);
      expect(PlayerCapabilities.none.subtitleDelay, isFalse);
      expect(PlayerCapabilities.none.crossfade, isFalse);
    });
  });
}

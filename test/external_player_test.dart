import 'package:flutter_test/flutter_test.dart';

import 'package:driftfin/providers/external_player_provider.dart';

void main() {
  group('buildExternalPlayerArgs', () {
    const url = 'http://host/Items/1/Download?api_key=k';

    test('default/empty template passes just the url', () {
      expect(buildExternalPlayerArgs('', url: url, positionSeconds: 0), [url]);
      expect(buildExternalPlayerArgs('{url}', url: url, positionSeconds: 90), [url]);
    });

    test('substitutes {url} and {position} and splits on whitespace', () {
      expect(
        buildExternalPlayerArgs('--start={position} {url}', url: url, positionSeconds: 90),
        ['--start=90', url],
      );
      expect(
        buildExternalPlayerArgs('/seek={position} {url}', url: url, positionSeconds: 12),
        ['/seek=12', url],
      );
    });

    test('drops empty tokens from extra spacing', () {
      expect(
        buildExternalPlayerArgs('  --fullscreen   {url}  ', url: url, positionSeconds: 0),
        ['--fullscreen', url],
      );
    });
  });

  group('ExternalPlayerSettings', () {
    test('isConfigured needs enabled + path', () {
      expect(const ExternalPlayerSettings(enabled: true, path: 'mpv').isConfigured, isTrue);
      expect(const ExternalPlayerSettings(enabled: false, path: 'mpv').isConfigured, isFalse);
      expect(const ExternalPlayerSettings(enabled: true, path: '').isConfigured, isFalse);
    });

    test('json round-trip', () {
      const s = ExternalPlayerSettings(enabled: true, path: 'C:/mpv.exe', argsTemplate: '--start={position} {url}');
      final r = ExternalPlayerSettings.fromJson(s.toJson());
      expect(r.enabled, isTrue);
      expect(r.path, 'C:/mpv.exe');
      expect(r.argsTemplate, '--start={position} {url}');
    });
  });
}

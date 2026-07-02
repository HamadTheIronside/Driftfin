import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:driftfin/util/update_checker.dart';

Map<String, dynamic> _release(String tag, {bool prerelease = false}) => {
      'tag_name': tag,
      'body': 'changelog for $tag',
      'html_url': 'https://example.com/$tag',
      'prerelease': prerelease,
      'assets': <dynamic>[],
    };

void main() {
  setUpAll(() {
    PackageInfo.setMockInitialValues(
      appName: 'Driftfin',
      packageName: 'io.github.hamadtheironside.driftfin',
      version: '0.10.5',
      buildNumber: '1',
      buildSignature: '',
    );
  });

  group('compareVersions', () {
    test('compares stable dotted versions', () {
      expect(compareVersions('0.10.5', '0.10.4'), greaterThan(0));
      expect(compareVersions('0.10.4', '0.10.5'), lessThan(0));
      expect(compareVersions('0.10.5', '0.10.5'), 0);
    });

    test('nightly suffixes make a version compare newer than its base', () {
      expect(compareVersions('0.10.5-nightly.20260702.3', '0.10.5'), greaterThan(0));
    });
  });

  group('UpdateChecker.fetchRecentReleases', () {
    test('filters out prereleases (nightlies) even when they are most recent', () async {
      // Regression test: this repo tags nightlies several times a day, so the
      // most-recent-releases page is normally dominated by them. A stable
      // 0.10.5 user must not be nagged to "update" to 0.10.5-nightly.*, since
      // nightly suffixes always compareVersions() as newer than the same base
      // stable version — that notification would never clear on its own.
      final client = MockClient((request) async {
        return http.Response(
          jsonEncode([
            _release('v0.10.6-nightly.20260703.1', prerelease: true),
            _release('v0.10.6-nightly.20260702.2', prerelease: true),
            _release('v0.10.5', prerelease: false),
            _release('v0.10.4', prerelease: false),
          ]),
          200,
        );
      });

      final releases = await UpdateChecker(client: client).fetchRecentReleases(count: 5);

      expect(releases.map((r) => r.version), ['0.10.5', '0.10.4']);
      expect(releases.every((r) => !r.isNewerThanCurrent), isTrue,
          reason: 'the running version is 0.10.5, so neither stable release in the fixture is newer');
    });

    test('a genuinely newer stable release is reported as an update', () async {
      final client = MockClient((request) async {
        return http.Response(
          jsonEncode([
            _release('v0.11.0-nightly.20260703.1', prerelease: true),
            _release('v0.11.0', prerelease: false),
          ]),
          200,
        );
      });

      final releases = await UpdateChecker(client: client).fetchRecentReleases(count: 5);

      expect(releases, hasLength(1));
      expect(releases.single.version, '0.11.0');
      expect(releases.single.isNewerThanCurrent, isTrue);
    });

    test('non-200 response returns an empty list', () async {
      final client = MockClient((request) async => http.Response('', 500));
      final releases = await UpdateChecker(client: client).fetchRecentReleases();
      expect(releases, isEmpty);
    });
  });
}

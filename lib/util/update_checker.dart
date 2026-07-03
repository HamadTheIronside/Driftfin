import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

class ReleaseInfo {
  final String version;
  final String changelog;
  final String url;
  final bool isNewerThanCurrent;
  final bool isPrerelease;
  final Map<String, String> downloads;

  ReleaseInfo({
    required this.version,
    required this.changelog,
    required this.url,
    required this.isNewerThanCurrent,
    required this.downloads,
    this.isPrerelease = false,
  });

  String? downloadUrlFor(String platform) => downloads[platform];

  Map<String, String> get preferredDownloads {
    final group = _platformGroup();
    final entries = downloads.entries.where((e) => e.key.contains(group));
    return Map.fromEntries(entries);
  }

  Map<String, String> get otherDownloads {
    final group = _platformGroup();
    final entries = downloads.entries.where((e) => !e.key.contains(group));
    return Map.fromEntries(entries);
  }

  String _platformGroup() {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.iOS:
        return 'ios';
      case TargetPlatform.windows:
        return 'windows';
      case TargetPlatform.macOS:
        return 'macos';
      case TargetPlatform.linux:
        return 'linux';
      default:
        return '';
    }
  }
}

extension DownloadLabelFormatter on String {
  String prettifyKey() {
    final parts = split('_');
    if (parts.isEmpty) return this;

    final base = parts.first.capitalize();
    if (parts.length == 1) return base;

    final variant = parts.sublist(1).join(' ').capitalize();
    return '$base ($variant)';
  }

  String capitalize() => isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
}

class UpdateChecker {
  UpdateChecker({http.Client? client}) : _client = client ?? http.Client();

  final String owner = 'HamadTheIronside';
  final String repo = 'Driftfin';
  final http.Client _client;

  Future<List<ReleaseInfo>> fetchRecentReleases({int count = 10}) async {
    final info = await PackageInfo.fromPlatform();
    final currentVersion = info.version;

    final url = Uri.parse('https://api.github.com/repos/$owner/$repo/releases?per_page=$count');
    final response = await _client.get(url);

    if (response.statusCode != 200) {
      print('Failed to fetch releases: ${response.statusCode}');
      return [];
    }

    final List<dynamic> releases = jsonDecode(response.body);
    return releases.map((json) {
      final tag = (json['tag_name'] as String?)?.replaceFirst(RegExp(r'^v'), '');
      final changelog = json['body'] as String? ?? '';
      final htmlUrl = json['html_url'] as String? ?? '';
      final isPrerelease = json['prerelease'] == true;
      final assets = json['assets'] as List<dynamic>? ?? [];

      final Map<String, String> downloads = {};
      for (final asset in assets) {
        final name = asset['name'] as String? ?? '';
        final downloadUrl = asset['browser_download_url'] as String? ?? '';

        if (name.contains('Android') && name.endsWith('.apk')) {
          downloads['android'] = downloadUrl;
        } else if (name.contains('iOS') && name.endsWith('.ipa')) {
          downloads['ios'] = downloadUrl;
        } else if (name.contains('Windows') && name.endsWith('Setup.exe')) {
          downloads['windows_installer'] = downloadUrl;
        } else if (name.contains('Windows') && name.endsWith('.zip')) {
          downloads['windows_portable'] = downloadUrl;
        } else if (name.contains('macOS') && name.endsWith('.dmg')) {
          downloads['macos'] = downloadUrl;
        } else if (name.contains('Linux') && name.endsWith('.AppImage')) {
          downloads['linux_appimage'] = downloadUrl;
        } else if (name.contains('Linux') && name.endsWith('.flatpak')) {
          downloads['linux_flatpak'] = downloadUrl;
        } else if (name.contains('Linux') && name.endsWith('.zip')) {
          downloads['linux_zip'] = downloadUrl;
        } else if (name.contains('Linux') && name.endsWith('.zsync')) {
          downloads['linux_zsync'] = downloadUrl;
        } else if (name.contains('Web') && name.endsWith('.zip')) {
          downloads['web'] = downloadUrl;
        }
      }

      // Nightly/prerelease builds are shown in the releases list, but are never
      // flagged as an available update: their tag always sorts "newer" than the
      // matching stable (the extra .YYYYMMDD.N segments), so treating them as an
      // update would nag stable users forever and never clear. Only stable
      // releases can be "newer than current".
      bool isNewer = !isPrerelease && tag != null && compareVersions(tag, currentVersion) > 0;

      return ReleaseInfo(
        version: tag ?? 'unknown',
        changelog: changelog.trim(),
        url: htmlUrl,
        isNewerThanCurrent: isNewer,
        isPrerelease: isPrerelease,
        downloads: downloads,
      );
    }).toList();
  }

  Future<bool> isUpToDate() async {
    final releases = await fetchRecentReleases();
    return !releases.any((release) => release.isNewerThanCurrent);
  }
}

/// Compares dot-separated versions, tolerating pre-release suffixes by using
/// the leading number of each segment (e.g. "5-nightly" -> 5,
/// "0.10.5-nightly.20260628.2" -> [0,10,5,20260628,2]). Extra numeric segments
/// count as newer, so nightly builds order after their base version. Returns
/// >0 if [a] is newer than [b].
int compareVersions(String a, String b) {
  final aParts = a.split('.').map(_leadingInt).toList();
  final bParts = b.split('.').map(_leadingInt).toList();

  for (var i = 0; i < aParts.length || i < bParts.length; i++) {
    final aVal = i < aParts.length ? aParts[i] : 0;
    final bVal = i < bParts.length ? bParts[i] : 0;
    if (aVal != bVal) return aVal.compareTo(bVal);
  }
  return 0;
}

int _leadingInt(String segment) {
  final match = RegExp(r'^\d+').firstMatch(segment.trim());
  return match == null ? 0 : (int.tryParse(match.group(0)!) ?? 0);
}

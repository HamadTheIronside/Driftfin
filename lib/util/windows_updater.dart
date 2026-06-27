import 'dart:io';

import 'package:flutter/foundation.dart';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Self-updater for the Windows portable build.
///
/// The Driftfin release pipeline ships Windows as a portable `.zip`
/// (`Driftfin-Windows-*.zip`). To "install" an update we download that zip,
/// then hand off to a detached PowerShell helper that waits for this process
/// to exit, overwrites the install directory with the new files and relaunches
/// the app. The Dart side must call [exit] right after [downloadAndInstall]
/// returns so the running executable is no longer locked.
class WindowsUpdater {
  static bool get isSupported => !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;

  /// Downloads [downloadUrl] (the `windows_portable` asset), stages a helper
  /// script and launches it detached. Reports download progress (0..1) via
  /// [onProgress]. After this returns the caller should immediately exit the
  /// app so the helper can replace the files.
  static Future<void> downloadAndInstall(
    String downloadUrl, {
    void Function(double progress)? onProgress,
  }) async {
    if (!isSupported) {
      throw StateError('WindowsUpdater is only supported on Windows.');
    }

    final tempDir = await getTemporaryDirectory();
    final zipPath = p.join(tempDir.path, 'driftfin_update.zip');
    final scriptPath = p.join(tempDir.path, 'driftfin_update.ps1');

    await _download(downloadUrl, zipPath, onProgress);

    final exePath = Platform.resolvedExecutable;
    final installDir = p.dirname(exePath);

    await File(scriptPath).writeAsString(_helperScript);

    await Process.start(
      'powershell.exe',
      [
        '-NoProfile',
        '-ExecutionPolicy', 'Bypass',
        '-WindowStyle', 'Hidden',
        '-File', scriptPath,
        '-ProcessId', '$pid',
        '-ZipPath', zipPath,
        '-InstallDir', installDir,
        '-ExePath', exePath,
      ],
      mode: ProcessStartMode.detached,
    );
  }

  static Future<void> _download(
    String url,
    String destination,
    void Function(double progress)? onProgress,
  ) async {
    final client = http.Client();
    try {
      final response = await client.send(http.Request('GET', Uri.parse(url)));
      if (response.statusCode != 200) {
        throw HttpException('Download failed (${response.statusCode})', uri: Uri.parse(url));
      }

      final total = response.contentLength ?? 0;
      var received = 0;
      final sink = File(destination).openWrite();
      try {
        await for (final chunk in response.stream) {
          sink.add(chunk);
          received += chunk.length;
          if (total > 0) onProgress?.call(received / total);
        }
      } finally {
        await sink.close();
      }
    } finally {
      client.close();
    }
  }

  /// PowerShell helper: waits for the app to close, expands the zip over the
  /// install directory and relaunches the executable. The portable zip's root
  /// maps directly onto the install dir (driftfin.exe, data\, *.dll).
  static const String _helperScript = r'''
param(
  [int]$ProcessId,
  [string]$ZipPath,
  [string]$InstallDir,
  [string]$ExePath
)

$ErrorActionPreference = 'Stop'

try {
  Wait-Process -Id $ProcessId -Timeout 120 -ErrorAction SilentlyContinue
} catch {}
Start-Sleep -Seconds 1

$extractDir = Join-Path $env:TEMP 'driftfin_update_extract'
if (Test-Path $extractDir) { Remove-Item -Recurse -Force $extractDir }

Expand-Archive -Path $ZipPath -DestinationPath $extractDir -Force
Copy-Item -Path (Join-Path $extractDir '*') -Destination $InstallDir -Recurse -Force

Start-Process -FilePath $ExePath

Remove-Item -Recurse -Force $extractDir -ErrorAction SilentlyContinue
Remove-Item -Force $ZipPath -ErrorAction SilentlyContinue
Remove-Item -Force $MyInvocation.MyCommand.Path -ErrorAction SilentlyContinue
''';
}

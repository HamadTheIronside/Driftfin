import 'package:background_downloader/background_downloader.dart' as dl;
import 'package:driftfin/models/syncing/download_stream.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DownloadStream.empty', () {
    test('has sentinel defaults and no active download', () {
      final stream = DownloadStream.empty();
      expect(stream.id, '');
      expect(stream.task, isNull);
      expect(stream.progress, -1);
      expect(stream.status, dl.TaskStatus.notFound);
      expect(stream.hasDownload, isFalse);
      expect(stream.isEnqueuedOrDownloading, isFalse);
    });
  });

  group('DownloadStream.hasDownload', () {
    test('is true while running with a real progress value', () {
      final stream = DownloadStream(id: 'a', progress: 0.5, status: dl.TaskStatus.running);
      expect(stream.hasDownload, isTrue);
    });

    test('is false when progress is still the -1 sentinel', () {
      final stream = DownloadStream(id: 'a', status: dl.TaskStatus.running);
      expect(stream.hasDownload, isFalse);
    });

    test('is false once complete, even with a progress value', () {
      final stream = DownloadStream(id: 'a', progress: 1.0, status: dl.TaskStatus.complete);
      expect(stream.hasDownload, isFalse);
    });

    test('is false when notFound', () {
      final stream = DownloadStream(id: 'a', progress: 0.2, status: dl.TaskStatus.notFound);
      expect(stream.hasDownload, isFalse);
    });
  });

  group('DownloadStream.isEnqueuedOrDownloading', () {
    test('is true for enqueued and running', () {
      expect(DownloadStream(id: 'a', status: dl.TaskStatus.enqueued).isEnqueuedOrDownloading, isTrue);
      expect(DownloadStream(id: 'a', status: dl.TaskStatus.running).isEnqueuedOrDownloading, isTrue);
    });

    test('is false for complete, failed, canceled, paused', () {
      for (final status in [
        dl.TaskStatus.complete,
        dl.TaskStatus.failed,
        dl.TaskStatus.canceled,
        dl.TaskStatus.paused,
      ]) {
        expect(DownloadStream(id: 'a', status: status).isEnqueuedOrDownloading, isFalse, reason: '$status');
      }
    });
  });

  group('DownloadStream.copyWith', () {
    test('overrides only the named fields', () {
      final base = DownloadStream(id: 'a', progress: 0.1, downloadSpeed: '1MB/s', status: dl.TaskStatus.running);
      final next = base.copyWith(progress: 0.9);

      expect(next.progress, 0.9);
      expect(next.id, 'a');
      expect(next.downloadSpeed, '1MB/s');
      expect(next.status, dl.TaskStatus.running);
    });

    test('with no arguments returns an equivalent copy', () {
      final base = DownloadStream(id: 'a', progress: 0.4, status: dl.TaskStatus.enqueued);
      final next = base.copyWith();

      expect(next.id, base.id);
      expect(next.progress, base.progress);
      expect(next.status, base.status);
    });
  });
}

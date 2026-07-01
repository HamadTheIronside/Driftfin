import 'package:flutter_test/flutter_test.dart';

import 'package:driftfin/jellyfin/jellyfin_open_api.swagger.dart' as dto;
import 'package:driftfin/models/items/media_streams_model.dart';
import 'package:driftfin/util/video_properties.dart';

void main() {
  VideoStreamModel videoStream({
    int width = 1920,
    int height = 1080,
    dto.VideoRangeType? videoRangeType,
    bool isDefault = true,
  }) {
    return VideoStreamModel(
      name: 'v',
      codec: 'h264',
      isDefault: isDefault,
      isExternal: false,
      index: 0,
      videoDoViTitle: null,
      videoRangeType: videoRangeType,
      bitRate: null,
      width: width,
      height: height,
      frameRate: 24,
    );
  }

  group('Resolution.fromSize', () {
    test('returns null when width or height is null', () {
      expect(Resolution.fromSize(null, 1080), isNull);
      expect(Resolution.fromSize(1920, null), isNull);
      expect(Resolution.fromSize(null, null), isNull);
    });

    test('1920x1080 or smaller is HD', () {
      expect(Resolution.fromSize(1920, 1080), Resolution.hd);
      expect(Resolution.fromSize(1280, 720), Resolution.hd);
    });

    test('boundary just above HD (e.g. 2560x1440) is classified as 4K (udh)', () {
      expect(Resolution.fromSize(2560, 1440), Resolution.udh);
    });

    test('exactly 3840x2160 is 4K', () {
      expect(Resolution.fromSize(3840, 2160), Resolution.udh);
    });

    test('above 4K bounds falls through to sd (per current implementation)', () {
      // Note: this looks like a naming quirk in the source (large resolutions
      // map to the "sd" enum value) but the branching logic itself is intentional
      // (three-tier width/height check), so it is preserved and tested as-is.
      expect(Resolution.fromSize(7680, 4320), Resolution.sd);
    });
  });

  group('Resolution.fromVideoStream', () {
    test('returns null for a null model', () {
      expect(Resolution.fromVideoStream(null), isNull);
    });

    test('derives resolution from stream width/height', () {
      expect(Resolution.fromVideoStream(videoStream(width: 1920, height: 1080)), Resolution.hd);
      expect(Resolution.fromVideoStream(videoStream(width: 3840, height: 2160)), Resolution.udh);
    });
  });

  group('DisplayProfile.fromVideoStream (single stream)', () {
    test('maps each VideoRangeType to the expected profile', () {
      expect(DisplayProfile.fromVideoStream(videoStream(videoRangeType: dto.VideoRangeType.sdr)), DisplayProfile.sdr);
      expect(
          DisplayProfile.fromVideoStream(videoStream(videoRangeType: dto.VideoRangeType.hdr10)), DisplayProfile.hdr10);
      expect(DisplayProfile.fromVideoStream(videoStream(videoRangeType: dto.VideoRangeType.hdr10plus)),
          DisplayProfile.hdr10Plus);
      expect(DisplayProfile.fromVideoStream(videoStream(videoRangeType: dto.VideoRangeType.hlg)), DisplayProfile.hlg);
      expect(DisplayProfile.fromVideoStream(videoStream(videoRangeType: dto.VideoRangeType.dovi)),
          DisplayProfile.dolbyVision);
      expect(DisplayProfile.fromVideoStream(videoStream(videoRangeType: dto.VideoRangeType.doviwithhdr10)),
          DisplayProfile.dolbyVisionHdr10);
      expect(DisplayProfile.fromVideoStream(videoStream(videoRangeType: dto.VideoRangeType.doviwithsdr)),
          DisplayProfile.dolbyVisionHlg);
      expect(DisplayProfile.fromVideoStream(videoStream(videoRangeType: dto.VideoRangeType.doviwithhlg)),
          DisplayProfile.dolbyVisionHlg);
      expect(DisplayProfile.fromVideoStream(videoStream(videoRangeType: dto.VideoRangeType.doviwithel)),
          DisplayProfile.dolbyVision);
      expect(DisplayProfile.fromVideoStream(videoStream(videoRangeType: dto.VideoRangeType.doviwithhdr10plus)),
          DisplayProfile.dolbyVisionHdr10Plus);
      expect(DisplayProfile.fromVideoStream(videoStream(videoRangeType: dto.VideoRangeType.doviwithelhdr10plus)),
          DisplayProfile.dolbyVisionHdr10Plus);
    });

    test('unknown, null, or invalid range types default to sdr', () {
      expect(DisplayProfile.fromVideoStream(videoStream(videoRangeType: null)), DisplayProfile.sdr);
      expect(
          DisplayProfile.fromVideoStream(videoStream(videoRangeType: dto.VideoRangeType.unknown)), DisplayProfile.sdr);
      expect(DisplayProfile.fromVideoStream(videoStream(videoRangeType: dto.VideoRangeType.swaggerGeneratedUnknown)),
          DisplayProfile.sdr);
      expect(DisplayProfile.fromVideoStream(videoStream(videoRangeType: dto.VideoRangeType.doviinvalid)),
          DisplayProfile.sdr);
    });
  });

  group('DisplayProfile.fromVideoStreams (list)', () {
    test('returns null for null or empty list', () {
      expect(DisplayProfile.fromVideoStreams(null), isNull);
      expect(DisplayProfile.fromVideoStreams([]), isNull);
    });

    test('prefers the default stream over the first one', () {
      final streams = [
        videoStream(isDefault: false, videoRangeType: dto.VideoRangeType.hdr10),
        videoStream(isDefault: true, videoRangeType: dto.VideoRangeType.dovi),
      ];
      expect(DisplayProfile.fromVideoStreams(streams), DisplayProfile.dolbyVision);
    });

    test('falls back to first stream when none is default', () {
      final streams = [
        videoStream(isDefault: false, videoRangeType: dto.VideoRangeType.hlg),
        videoStream(isDefault: false, videoRangeType: dto.VideoRangeType.dovi),
      ];
      expect(DisplayProfile.fromVideoStreams(streams), DisplayProfile.hlg);
    });
  });

  group('DisplayProfile.fromStreams (raw MediaStream list)', () {
    test('returns null for null or empty list', () {
      expect(DisplayProfile.fromStreams(null), isNull);
      expect(DisplayProfile.fromStreams([]), isNull);
    });

    test('picks the video-typed stream over non-video streams', () {
      final streams = [
        const dto.MediaStream(type: dto.MediaStreamType.audio, videoRangeType: dto.VideoRangeType.hdr10),
        const dto.MediaStream(type: dto.MediaStreamType.video, videoRangeType: dto.VideoRangeType.dovi),
      ];
      expect(DisplayProfile.fromStreams(streams), DisplayProfile.dolbyVision);
    });

    test('falls back to the first stream when no video-typed stream exists', () {
      final streams = [
        const dto.MediaStream(type: dto.MediaStreamType.audio, videoRangeType: dto.VideoRangeType.hlg),
      ];
      expect(DisplayProfile.fromStreams(streams), DisplayProfile.hlg);
    });
  });
}

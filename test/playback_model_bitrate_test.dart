import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:driftfin/models/items/media_streams_model.dart';
import 'package:driftfin/models/playback/playback_model.dart';
import 'package:driftfin/models/settings/video_player_settings.dart';
import 'package:driftfin/providers/connectivity_provider.dart';
import 'package:driftfin/providers/settings/video_player_settings_provider.dart';
import 'package:driftfin/providers/shared_provider.dart';
import 'package:driftfin/util/bitrate_helper.dart';

class _FakeVideoPlayerSettingsNotifier extends VideoPlayerSettingsProviderNotifier {
  _FakeVideoPlayerSettingsNotifier(super.ref, VideoPlayerSettingsModel initial) {
    Future.microtask(() => super.state = initial);
  }
}

class _FakeConnectivityStatus extends ConnectivityStatus {
  _FakeConnectivityStatus(this._initial);
  final ConnectionState _initial;

  @override
  ConnectionState build() => _initial;
}

final _refProvider = Provider<Ref>((ref) => ref);

Future<ProviderContainer> _container({
  required VideoPlayerSettingsModel settings,
  required ConnectionState connection,
  bool localConnection = false,
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();

  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      videoPlayerSettingsProvider.overrideWith((ref) => _FakeVideoPlayerSettingsNotifier(ref, settings)),
      connectivityStatusProvider.overrideWith(() => _FakeConnectivityStatus(connection)),
      localConnectionAvailableProvider.overrideWith((ref) => localConnection),
    ],
  );
  addTearDown(container.dispose);
  // Force-create the notifier now so its constructor's deferred
  // `Future.microtask` state assignment has a chance to run below.
  container.read(videoPlayerSettingsProvider);
  await Future<void>.delayed(Duration.zero);
  return container;
}

void main() {
  group('PlaybackModelHelper.resolveVideoQualityOptions', () {
    test('uses maxHomeBitrate when connected over the local URL', () async {
      final container = await _container(
        settings: VideoPlayerSettingsModel(maxHomeBitrate: Bitrate.b4Mbps, maxInternetBitrate: Bitrate.b1_5Mbps),
        connection: ConnectionState.wifi,
        localConnection: true,
      );
      final helper = PlaybackModelHelper(ref: container.read(_refProvider));

      final options = helper.resolveVideoQualityOptions(null);
      expect(options[Bitrate.b4Mbps], isTrue);
    });

    test('uses maxInternetBitrate when not on the local URL', () async {
      final container = await _container(
        settings: VideoPlayerSettingsModel(maxHomeBitrate: Bitrate.b4Mbps, maxInternetBitrate: Bitrate.b1_5Mbps),
        connection: ConnectionState.wifi,
        localConnection: false,
      );
      final helper = PlaybackModelHelper(ref: container.read(_refProvider));

      final options = helper.resolveVideoQualityOptions(null);
      expect(options[Bitrate.b1_5Mbps], isTrue);
      expect(options[Bitrate.b4Mbps], isFalse);
    });

    test('derives videoBitRate/videoCodec from the stream model', () async {
      final container = await _container(
        settings: VideoPlayerSettingsModel(),
        connection: ConnectionState.ethernet,
      );
      final helper = PlaybackModelHelper(ref: container.read(_refProvider));

      final streamModel = MediaStreamsModel(
        versionStreams: [
          VersionStreamModel(
            name: 'v1',
            index: 0,
            defaultAudioStreamIndex: null,
            defaultSubStreamIndex: null,
            videoStreams: [
              VideoStreamModel(
                name: 'v',
                codec: 'h264',
                isDefault: true,
                isExternal: false,
                index: 0,
                videoDoViTitle: null,
                videoRangeType: null,
                bitRate: 3000000,
                width: 1920,
                height: 1080,
                frameRate: 24.0,
              ),
            ],
            audioStreams: const [],
            subStreams: const [],
          ),
        ],
      );

      final options = helper.resolveVideoQualityOptions(streamModel);
      expect(options.containsKey(Bitrate.b3Mbps), isTrue);
    });
  });
}

import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/src/translations_pigeon.g.dart',
    dartOptions: DartOptions(),
    kotlinOut: 'android/app/src/main/kotlin/io/github/hamadtheironside/driftfin/api/TranslationsPigeon.g.kt',
    kotlinOptions: KotlinOptions(
      includeErrorClass: false,
    ),
    dartPackageName: 'io_github_hamadtheironside_driftfin.settings',
  ),
)
@FlutterApi()
abstract class TranslationsPigeon {
  String next();
  String nextVideo();
  String close();

  String skip(String name);

  String subtitles();
  String subtitleSync();

  String off();
  String chapters(int count);

  String nextUpInSeconds(int seconds);
  String hoursAndMinutes(String time);

  String endsAt(String time);

  String switchChannel();
  String switchChannelDesc(String programName, String channelName);
  String watch();
  String now();
  String decline();
}

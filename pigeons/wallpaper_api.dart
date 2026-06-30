import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/src/wallpaper_api.g.dart',
    kotlinOut: 'android/app/src/main/kotlin/io/github/hamadtheironside/driftfin/wallpaper/WallpaperApi.g.kt',
    kotlinOptions: KotlinOptions(
      package: 'nl.jknaapen.fladder.wallpaper',
      includeErrorClass: false,
    ),
    dartPackageName: 'io_github_hamadtheironside_driftfin.wallpaper',
  ),
)
@HostApi()
abstract class WallpaperApi {
  @async
  bool openWallpaperPopup(String filePath);
}

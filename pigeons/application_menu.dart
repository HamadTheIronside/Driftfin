import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/src/application_menu.g.dart',
    dartOptions: DartOptions(),
    swiftOut: 'macos/Runner/ApplicationMenu.g.swift',
    swiftOptions: SwiftOptions(
      includeErrorClass: false,
    ),
    dartPackageName: 'io_github_hamadtheironside_driftfin.application_menu',
  ),
)
@FlutterApi()
abstract class ApplicationMenu {
  void openNewWindow();
  void newInstance();
}

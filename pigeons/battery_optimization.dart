import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/src/battery_optimization_pigeon.g.dart',
    dartOptions: DartOptions(),
    kotlinOut: 'android/app/src/main/kotlin/io/github/hamadtheironside/driftfin/api/BatteryOptimizationPigeon.g.kt',
    kotlinOptions: KotlinOptions(
      includeErrorClass: false,
    ),
    dartPackageName: 'io_github_hamadtheironside_driftfin.settings',
  ),
)
@HostApi()
abstract class BatteryOptimizationPigeon {
  bool isIgnoringBatteryOptimizations();

  void openBatteryOptimizationSettings();
}

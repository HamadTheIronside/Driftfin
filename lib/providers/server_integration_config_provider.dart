import 'dart:convert';
import 'dart:developer';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import 'package:driftfin/models/server_integration_config.dart';
import 'package:driftfin/providers/api_provider.dart';
import 'package:driftfin/providers/user_provider.dart';

/// Holds the server-wide integration config served by the optional Driftfin
/// Jellyfin plugin. `null` means "no plugin / not loaded" — the app then uses
/// its local per-device settings exactly as before. This is refreshed on login
/// (see [User.updateInformation]) and cleared on logout.
final serverIntegrationConfigProvider =
    StateNotifierProvider<ServerIntegrationConfigNotifier, ServerIntegrationConfig?>((ref) {
  return ServerIntegrationConfigNotifier(ref);
});

class ServerIntegrationConfigNotifier extends StateNotifier<ServerIntegrationConfig?> {
  ServerIntegrationConfigNotifier(this.ref) : super(null);

  final Ref ref;

  /// Fetches `GET {server}/Driftfin/Config`. The endpoint is provided only by
  /// the Driftfin plugin, so a 404/timeout/parse-failure simply means the
  /// plugin isn't installed — we leave [state] null and the app keeps working
  /// off local settings. This call never throws.
  Future<void> load() async {
    final url = buildServerUrl(ref, pathSegments: ['Driftfin', 'Config']);
    final credentials = ref.read(userProvider)?.credentials;
    if (url.isEmpty || credentials == null) {
      state = null;
      return;
    }
    try {
      final response = await http
          .get(Uri.parse(url), headers: credentials.header(ref))
          .timeout(const Duration(seconds: 8));
      if (response.statusCode != 200 || response.body.isEmpty) {
        state = null;
        return;
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        state = null;
        return;
      }
      state = ServerIntegrationConfig.fromJson(decoded);
    } catch (e) {
      log('Driftfin plugin config unavailable (using local settings): $e');
      state = null;
    }
  }

  void clear() => state = null;
}

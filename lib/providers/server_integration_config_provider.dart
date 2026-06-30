import 'dart:convert';
import 'dart:developer';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import 'package:driftfin/models/server_integration_config.dart';
import 'package:driftfin/providers/api_provider.dart';
import 'package:driftfin/providers/user_provider.dart';

/// Fetches the Driftfin plugin config from [url]. The endpoint is provided only
/// by the Driftfin plugin, so a 404/empty/non-JSON/timeout/exception simply
/// means the plugin isn't installed — returns null and the app keeps working
/// off local settings. Never throws. [client] is injectable for testing.
Future<ServerIntegrationConfig?> fetchServerIntegrationConfig(
  String url,
  Map<String, String> headers,
  http.Client client,
) async {
  try {
    final response = await client.get(Uri.parse(url), headers: headers).timeout(const Duration(seconds: 8));
    if (response.statusCode != 200 || response.body.isEmpty) return null;
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) return null;
    return ServerIntegrationConfig.fromJson(decoded);
  } catch (e) {
    log('Driftfin plugin config unavailable (using local settings): $e');
    return null;
  }
}

/// Holds the server-wide integration config served by the optional Driftfin
/// Jellyfin plugin. `null` means "no plugin / not loaded" — the app then uses
/// its local per-device settings exactly as before. This is refreshed on login
/// (see [User.updateInformation]) and cleared on logout.
final serverIntegrationConfigProvider =
    StateNotifierProvider<ServerIntegrationConfigNotifier, ServerIntegrationConfig?>(
  (ref) => ServerIntegrationConfigNotifier(ref),
);

class ServerIntegrationConfigNotifier extends StateNotifier<ServerIntegrationConfig?> {
  ServerIntegrationConfigNotifier(this.ref, {http.Client? client})
      : _client = client ?? http.Client(),
        super(null);

  final Ref ref;
  final http.Client _client;

  /// Fetches `GET {server}/Driftfin/Config` and stores the result (or null when
  /// the plugin is absent / unreachable).
  Future<void> load() async {
    final url = buildServerUrl(ref, pathSegments: ['Driftfin', 'Config']);
    final credentials = ref.read(userProvider)?.credentials;
    if (url.isEmpty || credentials == null) {
      state = null;
      return;
    }
    state = await fetchServerIntegrationConfig(url, credentials.header(ref), _client);
  }

  void clear() => state = null;
}

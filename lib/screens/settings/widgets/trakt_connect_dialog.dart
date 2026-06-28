import 'dart:async';

import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:driftfin/providers/trakt_provider.dart';
import 'package:driftfin/screens/shared/media/external_urls.dart';
import 'package:driftfin/util/localization_helper.dart';

/// Runs the Trakt device-code login: shows the user a code + activation URL and
/// polls until they approve it. Pops `true` on success.
Future<bool?> showTraktConnectDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => const _TraktConnectDialog(),
  );
}

class _TraktConnectDialog extends ConsumerStatefulWidget {
  const _TraktConnectDialog();

  @override
  ConsumerState<_TraktConnectDialog> createState() => _TraktConnectDialogState();
}

class _TraktConnectDialogState extends ConsumerState<_TraktConnectDialog> {
  TraktDeviceCode? _code;
  String? _error;
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _start() async {
    final code = await ref.read(traktProvider.notifier).startDeviceLogin();
    if (!mounted) return;
    if (code == null) {
      setState(() => _error = context.localized.traktConnectFailed);
      return;
    }
    setState(() => _code = code);
    _poll = Timer.periodic(Duration(seconds: code.interval.clamp(2, 30)), (_) => _tick(code.deviceCode));
  }

  Future<void> _tick(String deviceCode) async {
    final result = await ref.read(traktProvider.notifier).pollDeviceToken(deviceCode);
    if (!mounted) return;
    switch (result.status) {
      case TraktPollStatus.success:
        _poll?.cancel();
        Navigator.of(context).pop(true);
      case TraktPollStatus.pending:
      case TraktPollStatus.slowDown:
        break; // keep waiting
      case TraktPollStatus.expired:
      case TraktPollStatus.denied:
      case TraktPollStatus.invalid:
      case TraktPollStatus.error:
        _poll?.cancel();
        setState(() => _error = context.localized.traktConnectFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final code = _code;
    return AlertDialog(
      title: Text(context.localized.traktConnect),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_error != null)
            Text(_error!, textAlign: TextAlign.center)
          else if (code == null)
            const Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator())
          else ...[
            Text(context.localized.traktActivateInstructions(code.verificationUrl), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            SelectableText(
              code.userCode,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4,
                  ),
            ),
            const SizedBox(height: 16),
            FilledButton.tonalIcon(
              onPressed: () => launchUrl(context, code.verificationUrl),
              icon: const Icon(Icons.open_in_new),
              label: Text(code.verificationUrl),
            ),
            const SizedBox(height: 8),
            const LinearProgressIndicator(),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(context.localized.cancel),
        ),
      ],
    );
  }
}

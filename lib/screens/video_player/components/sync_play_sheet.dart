import 'dart:async';

import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import 'package:driftfin/jellyfin/jellyfin_open_api.swagger.dart';
import 'package:driftfin/models/syncplay/sync_play_models.dart';
import 'package:driftfin/models/syncplay/sync_play_state.dart';
import 'package:driftfin/providers/syncplay/sync_play_controller.dart';
import 'package:driftfin/util/localization_helper.dart';

/// Opens Watch Together as a keyboard-aware modal bottom sheet (chat needs the
/// input to stay above the on-screen keyboard, which a centered dialog can't do).
Future<void> showSyncPlaySheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (context) => const SyncPlaySheet(),
  );
}

class SyncPlaySheet extends ConsumerStatefulWidget {
  const SyncPlaySheet({super.key});

  @override
  ConsumerState<SyncPlaySheet> createState() => _SyncPlaySheetState();
}

class _SyncPlaySheetState extends ConsumerState<SyncPlaySheet> {
  Timer? _poll;
  List<GroupInfoDto> _groups = [];
  bool _busy = false;
  final _chatController = TextEditingController();
  final _chatFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _refresh();
    _poll = Timer.periodic(const Duration(seconds: 3), (_) => _refresh());
  }

  @override
  void dispose() {
    _poll?.cancel();
    _chatController.dispose();
    _chatFocus.dispose();
    super.dispose();
  }

  void _sendChat() {
    final text = _chatController.text;
    if (text.trim().isEmpty) return;
    _chatController.clear();
    ref.read(syncPlayControllerProvider.notifier).sendChat(text);
    // Keep the keyboard up so several messages can be sent in a row.
    _chatFocus.requestFocus();
  }

  Future<void> _refresh() async {
    if (ref.read(syncPlayControllerProvider).inGroup) return;
    final groups = await ref.read(syncPlayControllerProvider.notifier).listGroups();
    if (mounted) setState(() => _groups = groups);
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(syncPlayControllerProvider);
    final notifier = ref.read(syncPlayControllerProvider.notifier);
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    // Cap the sheet to ~85% of the screen, leaving room for the keyboard so the
    // input and content stay fully on-screen while typing.
    final maxHeight = (MediaQuery.sizeOf(context).height * 0.85 - keyboard).clamp(220.0, double.infinity);

    return Padding(
      padding: EdgeInsets.only(bottom: keyboard),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(IconsaxPlusBold.people),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(context.localized.watchTogether, style: Theme.of(context).textTheme.titleLarge),
                  ),
                ],
              ),
              if (state.lastError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(state.lastError!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                ),
              const SizedBox(height: 8),
              const Divider(height: 1),
              const SizedBox(height: 8),
              Flexible(child: state.inGroup ? _inGroup(context, state, notifier) : _lobby(context, notifier)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _inGroup(BuildContext context, SyncPlayState state, SyncPlayController notifier) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Compact group header so chat gets the space.
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    state.groupName ?? context.localized.watchTogether,
                    style: Theme.of(context).textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${_statusLabel(context, state)} · ${_membersLabel(context, state)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: state.isWaiting ? Theme.of(context).colorScheme.tertiary : null,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            TextButton.icon(
              onPressed: _busy ? null : () => _run(notifier.leaveGroup),
              icon: const Icon(IconsaxPlusLinear.logout, size: 18),
              label: Text(context.localized.syncPlayLeave),
            ),
          ],
        ),
        if (notifier.pendingItemId != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              context.localized.syncPlayDifferentItem,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.tertiary),
            ),
          ),
        const SizedBox(height: 8),
        // Chat takes all remaining vertical space.
        Flexible(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(8),
            child: _chatList(context, state),
          ),
        ),
        const SizedBox(height: 8),
        _chatInput(context),
      ],
    );
  }

  Widget _chatList(BuildContext context, SyncPlayState state) {
    if (state.chat.isEmpty) {
      return Center(
        child: Opacity(
          opacity: 0.5,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(context.localized.syncPlayChatEmpty, textAlign: TextAlign.center),
          ),
        ),
      );
    }
    final messages = state.chat.reversed.toList();
    return ListView.builder(
      reverse: true,
      padding: EdgeInsets.zero,
      itemCount: messages.length,
      itemBuilder: (context, i) => _bubble(context, messages[i]),
    );
  }

  Widget _bubble(BuildContext context, SyncChatMessage m) {
    final scheme = Theme.of(context).colorScheme;
    return Align(
      alignment: m.mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.7),
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: m.mine ? scheme.primary : scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(14),
            topRight: const Radius.circular(14),
            bottomLeft: Radius.circular(m.mine ? 14 : 4),
            bottomRight: Radius.circular(m.mine ? 4 : 14),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!m.mine && m.sender.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  m.sender,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(color: scheme.primary),
                ),
              ),
            Text(
              m.text,
              style: TextStyle(color: m.mine ? scheme.onPrimary : scheme.onSurface),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chatInput(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: TextField(
            controller: _chatController,
            focusNode: _chatFocus,
            textInputAction: TextInputAction.send,
            minLines: 1,
            maxLines: 4,
            onSubmitted: (_) => _sendChat(),
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              hintText: context.localized.syncPlayChatHint,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton.filled(
          onPressed: _sendChat,
          icon: const Icon(IconsaxPlusBold.send_1),
        ),
      ],
    );
  }

  Widget _lobby(BuildContext context, SyncPlayController notifier) {
    return ListView(
      shrinkWrap: true,
      children: [
        FilledButton.icon(
          onPressed: _busy ? null : () => _run(() => notifier.createGroup()),
          icon: const Icon(IconsaxPlusLinear.add),
          label: Text(context.localized.syncPlayCreateGroup),
        ),
        const SizedBox(height: 16),
        Text(context.localized.syncPlayAvailableGroups, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 4),
        if (_groups.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Opacity(opacity: 0.6, child: Text(context.localized.syncPlayNoGroups)),
          )
        else
          ..._groups.map((g) => ListTile(
                leading: const Icon(IconsaxPlusLinear.people),
                title: Text(g.groupName ?? context.localized.watchTogether),
                subtitle: Text(context.localized.syncPlayMembers(g.participants?.length ?? 0)),
                trailing: const Icon(IconsaxPlusLinear.login_1),
                onTap: _busy || g.groupId == null ? null : () => _run(() => notifier.joinGroup(g.groupId!)),
              )),
      ],
    );
  }

  String _membersLabel(BuildContext context, SyncPlayState state) {
    if (state.members.isEmpty) return context.localized.syncPlayMembers(0);
    return state.members.join(', ');
  }

  String _statusLabel(BuildContext context, SyncPlayState state) {
    if (state.connection == SyncPlayConnection.connecting) return context.localized.syncPlayConnecting;
    if (state.groupState == SyncGroupState.waiting) return context.localized.syncPlayWaiting;
    return context.localized.syncPlayInGroup;
  }
}

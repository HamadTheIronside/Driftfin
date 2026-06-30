import 'dart:async';

import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import 'package:driftfin/jellyfin/jellyfin_open_api.swagger.dart';
import 'package:driftfin/models/syncplay/sync_play_models.dart';
import 'package:driftfin/models/syncplay/sync_play_state.dart';
import 'package:driftfin/providers/syncplay/sync_play_controller.dart';
import 'package:driftfin/util/localization_helper.dart';

Future<void> showSyncPlaySheet(BuildContext context) {
  return showDialog(
    context: context,
    builder: (context) => const Dialog(child: SyncPlaySheet()),
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
    super.dispose();
  }

  void _sendChat() {
    final text = _chatController.text;
    if (text.trim().isEmpty) return;
    _chatController.clear();
    ref.read(syncPlayControllerProvider.notifier).sendChat(text);
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

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: 480, maxHeight: MediaQuery.sizeOf(context).height * 0.7),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(IconsaxPlusBold.people),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(context.localized.watchTogether, style: Theme.of(context).textTheme.titleLarge),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(IconsaxPlusBold.close_circle),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (state.lastError != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(state.lastError!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ),
            const Divider(),
            Flexible(child: state.inGroup ? _inGroup(context, state, notifier) : _lobby(context, notifier)),
          ],
        ),
      ),
    );
  }

  Widget _inGroup(BuildContext context, SyncPlayState state, SyncPlayController notifier) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(IconsaxPlusBold.video),
          title: Text(state.groupName ?? context.localized.watchTogether),
          subtitle:
              Text('${_statusLabel(context, state)} · ${context.localized.syncPlayMembers(state.members.length)}'),
          trailing: TextButton.icon(
            onPressed: _busy ? null : () => _run(notifier.leaveGroup),
            icon: const Icon(IconsaxPlusLinear.logout),
            label: Text(context.localized.syncPlayLeave),
          ),
        ),
        if (notifier.pendingItemId != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(context.localized.syncPlayDifferentItem,
                style: TextStyle(color: Theme.of(context).colorScheme.tertiary)),
          ),
        if (state.members.isNotEmpty)
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: state.members
                .map((m) => Chip(
                      visualDensity: VisualDensity.compact,
                      avatar: const Icon(IconsaxPlusLinear.user, size: 16),
                      label: Text(m),
                    ))
                .toList(),
          ),
        const Divider(),
        Expanded(child: _chatList(context, state)),
        _chatInput(context),
      ],
    );
  }

  Widget _chatList(BuildContext context, SyncPlayState state) {
    if (state.chat.isEmpty) {
      return Center(
        child: Opacity(opacity: 0.5, child: Text(context.localized.syncPlayChatEmpty)),
      );
    }
    final messages = state.chat.reversed.toList();
    return ListView.builder(
      reverse: true,
      itemCount: messages.length,
      itemBuilder: (context, i) {
        final m = messages[i];
        return Align(
          alignment: m.mine ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 2),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: m.mine
                  ? Theme.of(context).colorScheme.primaryContainer
                  : Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!m.mine && m.sender.isNotEmpty) Text(m.sender, style: Theme.of(context).textTheme.labelSmall),
                Text(m.text),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _chatInput(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _chatController,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendChat(),
              decoration: InputDecoration(
                isDense: true,
                hintText: context.localized.syncPlayChatHint,
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          IconButton(onPressed: _sendChat, icon: const Icon(IconsaxPlusBold.send_1)),
        ],
      ),
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

  String _statusLabel(BuildContext context, SyncPlayState state) {
    if (state.connection == SyncPlayConnection.connecting) return context.localized.syncPlayConnecting;
    if (state.groupState == SyncGroupState.waiting) return context.localized.syncPlayWaiting;
    return context.localized.syncPlayInGroup;
  }
}

import 'package:collection/collection.dart';

import 'package:driftfin/models/syncplay/sync_play_models.dart';

enum SyncPlayConnection { disconnected, connecting, connected }

/// A single Watch Together chat line. Chat is relayed over Jellyfin session
/// `DisplayMessage`s since SyncPlay itself carries no chat channel.
class SyncChatMessage {
  const SyncChatMessage({required this.sender, required this.text, required this.mine});
  final String sender;
  final String text;
  final bool mine;
}

/// Immutable UI/state snapshot of the SyncPlay session.
class SyncPlayState {
  const SyncPlayState({
    this.connection = SyncPlayConnection.disconnected,
    this.inGroup = false,
    this.groupId,
    this.groupName,
    this.members = const [],
    this.groupState = SyncGroupState.idle,
    this.chat = const [],
    this.lastError,
  });

  final SyncPlayConnection connection;
  final bool inGroup;
  final String? groupId;
  final String? groupName;

  /// Participant display names reported by the server.
  final List<String> members;
  final SyncGroupState groupState;
  final List<SyncChatMessage> chat;
  final String? lastError;

  /// True while the group is holding for a member to finish buffering.
  bool get isWaiting => groupState == SyncGroupState.waiting;

  SyncPlayState copyWith({
    SyncPlayConnection? connection,
    bool? inGroup,
    String? groupId,
    String? groupName,
    List<String>? members,
    SyncGroupState? groupState,
    List<SyncChatMessage>? chat,
    String? lastError,
    bool clearError = false,
    bool clearGroup = false,
  }) {
    return SyncPlayState(
      connection: connection ?? this.connection,
      inGroup: clearGroup ? false : (inGroup ?? this.inGroup),
      groupId: clearGroup ? null : (groupId ?? this.groupId),
      groupName: clearGroup ? null : (groupName ?? this.groupName),
      members: clearGroup ? const [] : (members ?? this.members),
      groupState: clearGroup ? SyncGroupState.idle : (groupState ?? this.groupState),
      chat: clearGroup ? const [] : (chat ?? this.chat),
      lastError: clearError ? null : (lastError ?? this.lastError),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is SyncPlayState &&
      other.connection == connection &&
      other.inGroup == inGroup &&
      other.groupId == groupId &&
      other.groupName == groupName &&
      const ListEquality().equals(other.members, members) &&
      other.groupState == groupState &&
      identical(other.chat, chat) &&
      other.lastError == lastError;

  @override
  int get hashCode => Object.hash(
        connection,
        inGroup,
        groupId,
        groupName,
        const ListEquality().hash(members),
        groupState,
        identityHashCode(chat),
        lastError,
      );
}

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

/// A quick emoji reaction (issue #5). The controller keeps only a short
/// recent-history window; the UI renders it as a fading/transient bubble.
class SyncReactionEvent {
  const SyncReactionEvent({required this.sender, required this.emoji, required this.at, required this.mine});
  final String sender;
  final String emoji;
  final DateTime at;
  final bool mine;
}

/// Per-member presence flags relayed over the optional Driftfin plugin's chat
/// channel (issue #5). Requires the Driftfin plugin (see
/// `jellyfin-plugin/README.md`); without it these simply never populate.
class SyncPresenceInfo {
  const SyncPresenceInfo({this.typing = false, this.buffering = false});
  final bool typing;
  final bool buffering;

  SyncPresenceInfo copyWith({bool? typing, bool? buffering}) =>
      SyncPresenceInfo(typing: typing ?? this.typing, buffering: buffering ?? this.buffering);

  @override
  bool operator ==(Object other) => other is SyncPresenceInfo && other.typing == typing && other.buffering == buffering;

  @override
  int get hashCode => Object.hash(typing, buffering);
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
    this.reactions = const [],
    this.presence = const {},
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

  /// Recent emoji reactions (issue #5), newest last. Relay-only — requires the
  /// Driftfin plugin.
  final List<SyncReactionEvent> reactions;

  /// Per-member typing/buffering presence (issue #5), keyed by member name.
  /// Relay-only — requires the Driftfin plugin.
  final Map<String, SyncPresenceInfo> presence;
  final String? lastError;

  /// True while the group is holding for a member to finish buffering.
  bool get isWaiting => groupState == SyncGroupState.waiting;

  /// Members currently reported as typing in chat.
  List<String> get typingMembers =>
      presence.entries.where((e) => e.value.typing).map((e) => e.key).toList(growable: false);

  /// Members currently reported as buffering (in addition to the group-level
  /// [isWaiting] signal, which doesn't say *who*).
  List<String> get bufferingMembers =>
      presence.entries.where((e) => e.value.buffering).map((e) => e.key).toList(growable: false);

  SyncPlayState copyWith({
    SyncPlayConnection? connection,
    bool? inGroup,
    String? groupId,
    String? groupName,
    List<String>? members,
    SyncGroupState? groupState,
    List<SyncChatMessage>? chat,
    List<SyncReactionEvent>? reactions,
    Map<String, SyncPresenceInfo>? presence,
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
      reactions: clearGroup ? const [] : (reactions ?? this.reactions),
      presence: clearGroup ? const {} : (presence ?? this.presence),
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
      identical(other.reactions, reactions) &&
      const MapEquality().equals(other.presence, presence) &&
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
        identityHashCode(reactions),
        const MapEquality().hash(presence),
        lastError,
      );
}

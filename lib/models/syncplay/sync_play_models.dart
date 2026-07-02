/// Hand-written SyncPlay models.
///
/// Jellyfin's generated OpenAPI client cannot type the WebSocket
/// `SyncPlayGroupUpdate.Data` payload (the `GroupUpdate.Data` property is a C#
/// generic that Swashbuckle emits as untyped — see jellyfin/jellyfin#6052), so
/// the inbound group-update messages are parsed by hand here from the raw
/// PascalCase JSON the server sends over `/socket`.
library;

import 'dart:convert';

/// High-level lifecycle/state of a SyncPlay group as reported by the server.
enum SyncGroupState {
  idle,
  waiting, // a member is buffering / not ready
  paused,
  playing,
  unknown;

  static SyncGroupState parse(Object? raw) {
    switch (raw?.toString().toLowerCase()) {
      case 'idle':
        return SyncGroupState.idle;
      case 'waiting':
        return SyncGroupState.waiting;
      case 'paused':
        return SyncGroupState.paused;
      case 'playing':
        return SyncGroupState.playing;
      default:
        return SyncGroupState.unknown;
    }
  }
}

/// The `Type` discriminator of a `SyncPlayGroupUpdate` message.
enum SyncGroupUpdateType {
  groupJoined,
  groupLeft,
  userJoined,
  userLeft,
  stateUpdate,
  playQueue,
  notInGroup,
  groupDoesNotExist,
  libraryAccessDenied,
  unknown;

  static SyncGroupUpdateType parse(Object? raw) {
    switch (raw?.toString().toLowerCase()) {
      case 'groupjoined':
        return SyncGroupUpdateType.groupJoined;
      case 'groupleft':
        return SyncGroupUpdateType.groupLeft;
      case 'userjoined':
        return SyncGroupUpdateType.userJoined;
      case 'userleft':
        return SyncGroupUpdateType.userLeft;
      case 'stateupdate':
        return SyncGroupUpdateType.stateUpdate;
      case 'playqueue':
        return SyncGroupUpdateType.playQueue;
      case 'notingroup':
        return SyncGroupUpdateType.notInGroup;
      case 'groupdoesnotexist':
        return SyncGroupUpdateType.groupDoesNotExist;
      case 'libraryaccessdenied':
        return SyncGroupUpdateType.libraryAccessDenied;
      default:
        return SyncGroupUpdateType.unknown;
    }
  }
}

/// A decoded `SyncPlayGroupUpdate` envelope. [data] is the still-untyped inner
/// payload whose shape depends on [type] (a GroupInfoDto map for groupJoined, a
/// participant-name string for user(Joined|Left), a GroupStateUpdate map for
/// stateUpdate, a PlayQueueUpdate map for playQueue).
class SyncPlayGroupUpdate {
  const SyncPlayGroupUpdate({required this.type, this.groupId, this.data});

  final SyncGroupUpdateType type;
  final String? groupId;
  final Object? data;

  static SyncPlayGroupUpdate fromJson(Map<String, dynamic> json) {
    return SyncPlayGroupUpdate(
      type: SyncGroupUpdateType.parse(json['Type']),
      groupId: json['GroupId']?.toString(),
      data: json['Data'],
    );
  }

  /// For [SyncGroupUpdateType.groupJoined] the [data] is a GroupInfoDto-shaped
  /// map. Returns it as a map, or null otherwise.
  Map<String, dynamic>? get groupInfo => data is Map<String, dynamic> ? data as Map<String, dynamic> : null;
}

/// Resolved scheduled-command kinds from a `SendCommand` (`SendCommandType`).
/// Note Jellyfin names the resume action `Unpause`, not `Play`.
enum SyncCommand { unpause, pause, stop, seek, unknown }

SyncCommand parseSyncCommand(Object? raw) {
  switch (raw?.toString().toLowerCase()) {
    case 'unpause':
      return SyncCommand.unpause;
    case 'pause':
      return SyncCommand.pause;
    case 'stop':
      return SyncCommand.stop;
    case 'seek':
      return SyncCommand.seek;
    default:
      return SyncCommand.unknown;
  }
}

/// Discriminates a Driftfin-relay group message: a chat line, a quick emoji
/// reaction, or a transient typing/buffering presence ping. See
/// [SyncRelayMessage] for how these travel over the wire.
enum SyncRelayKind { chat, reaction, typing, buffering, unknown }

SyncRelayKind parseSyncRelayKind(Object? raw) {
  switch (raw?.toString().toLowerCase()) {
    case 'chat':
      return SyncRelayKind.chat;
    case 'reaction':
      return SyncRelayKind.reaction;
    case 'typing':
      return SyncRelayKind.typing;
    case 'buffering':
      return SyncRelayKind.buffering;
    default:
      return SyncRelayKind.unknown;
  }
}

/// Marker used as the `Header` of a relayed `DisplayMessage` GeneralCommand so
/// a Driftfin client can tell a Driftfin plugin relay payload (JSON in `Text`)
/// apart from a genuine admin-authored broadcast message, which should still
/// be shown as a plain system banner rather than parsed as JSON.
///
/// Must match `DriftfinSyncPlayController.RelayHeader` in the companion
/// Jellyfin plugin (`jellyfin-plugin/`).
const syncRelayMarker = '__driftfin.syncplay.relay__';

/// A decoded Driftfin relay payload, as broadcast by the optional Driftfin
/// Jellyfin plugin's `POST /Driftfin/SyncPlay/{groupId}/Messages` endpoint
/// (see issue #4). The wire shape uses short keys because it rides inside a
/// stock Jellyfin `DisplayMessage`, which some non-Driftfin clients may render
/// literally as a text popup.
class SyncRelayMessage {
  const SyncRelayMessage({required this.kind, required this.sender, this.text, this.emoji});

  final SyncRelayKind kind;
  final String sender;
  final String? text;
  final String? emoji;

  /// Parses a `GeneralCommand`'s `Header`/`Text` arguments. Returns null when
  /// [header] doesn't carry the Driftfin relay marker (i.e. this is a genuine
  /// admin `DisplayMessage`, not a relay payload) or when [text] isn't valid
  /// JSON in the expected shape.
  static SyncRelayMessage? tryParse({required String header, required String text}) {
    if (header != syncRelayMarker) return null;
    try {
      final json = jsonDecode(text);
      if (json is! Map<String, dynamic>) return null;
      final sender = json['s']?.toString();
      if (sender == null || sender.isEmpty) return null;
      return SyncRelayMessage(
        kind: parseSyncRelayKind(json['k']),
        sender: sender,
        text: json['t']?.toString(),
        emoji: json['e']?.toString(),
      );
    } catch (_) {
      return null;
    }
  }
}

/// Hand-written SyncPlay models.
///
/// Jellyfin's generated OpenAPI client cannot type the WebSocket
/// `SyncPlayGroupUpdate.Data` payload (the `GroupUpdate.Data` property is a C#
/// generic that Swashbuckle emits as untyped — see jellyfin/jellyfin#6052), so
/// the inbound group-update messages are parsed by hand here from the raw
/// PascalCase JSON the server sends over `/socket`.
library;

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

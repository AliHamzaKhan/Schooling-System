import 'package:flutter/foundation.dart';

/// Lifecycle of a single call, surfaced reactively by the call controller so
/// the UI can render the right state (lobby → connecting → live → ended).
enum CallStatus {
  /// No call in progress.
  idle,

  /// Joining the channel / negotiating media.
  connecting,

  /// In the channel, waiting for the other party to join.
  waiting,

  /// At least one remote participant is present.
  connected,

  /// The call has been reconnecting after a network drop.
  reconnecting,

  /// The call ended (locally or remotely).
  ended,

  /// A fatal error tore the call down.
  failed,
}

/// Everything needed to join one call channel.
///
/// [channelId] is the room name both parties share. [token] is the short-lived
/// RTC token your backend mints (channel + uid scoped). [uid] is this device's
/// numeric id within the channel (0 lets the SDK assign one).
@immutable
class CallSession {
  final String channelId;
  final String? token;
  final int uid;

  /// Whether the local user publishes media (a doctor/patient on a consult) or
  /// only watches (an observer / supervisor).
  final bool isBroadcaster;

  /// Display info for the local user — handy for participant lists.
  final CallParticipant localUser;

  const CallSession({
    required this.channelId,
    this.token,
    this.uid = 0,
    this.isBroadcaster = true,
    this.localUser = const CallParticipant(uid: 0, name: 'You', isLocal: true),
  });
}

/// One participant in the call — local or remote. The controller maintains a
/// reactive list of these for rendering tiles and a participant roster.
@immutable
class CallParticipant {
  final int uid;
  final String name;
  final bool isLocal;

  /// Remote audio/video publish state, updated from engine mute events.
  final bool audioEnabled;
  final bool videoEnabled;

  const CallParticipant({
    required this.uid,
    this.name = '',
    this.isLocal = false,
    this.audioEnabled = true,
    this.videoEnabled = true,
  });

  CallParticipant copyWith({
    String? name,
    bool? audioEnabled,
    bool? videoEnabled,
  }) =>
      CallParticipant(
        uid: uid,
        name: name ?? this.name,
        isLocal: isLocal,
        audioEnabled: audioEnabled ?? this.audioEnabled,
        videoEnabled: videoEnabled ?? this.videoEnabled,
      );

  @override
  bool operator ==(Object other) =>
      other is CallParticipant && other.uid == uid;

  @override
  int get hashCode => uid.hashCode;
}

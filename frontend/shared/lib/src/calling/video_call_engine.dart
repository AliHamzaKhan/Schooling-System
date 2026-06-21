import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/widgets.dart';

import 'call_config.dart';
import 'call_models.dart';

/// Engine-agnostic callbacks the [CallController] listens to. Keeping these in
/// an interface means the controller and UI never import Agora directly — swap
/// [AgoraVideoCallEngine] for another backend without touching call code.
abstract class CallEngineEvents {
  void onLocalJoined(int uid);
  void onRemoteJoined(int uid);
  void onRemoteLeft(int uid);
  void onRemoteAudioToggled(int uid, bool enabled);
  void onRemoteVideoToggled(int uid, bool enabled);
  void onConnectionLost();
  void onReconnected();
  void onError(String message);
}

/// The contract a video backend must satisfy. The Agora implementation lives
/// below; the rest of the app depends only on this surface.
abstract class VideoCallEngine {
  Future<void> initialize();
  Future<void> joinCall(CallSession session, CallEngineEvents events);
  Future<void> leaveCall();
  Future<void> dispose();

  Future<void> setMicMuted(bool muted);
  Future<void> setCameraEnabled(bool enabled);
  Future<void> setSpeakerphone(bool enabled);
  Future<void> switchCamera();

  /// Local camera preview widget.
  Widget localPreview();

  /// Remote participant's video widget for [uid].
  Widget remoteView(int uid);
}

/// [VideoCallEngine] backed by `agora_rtc_engine`.
///
/// Handles SDK init, channel join/leave, the audio/video controls, and exposes
/// Agora's native video surfaces as plain [Widget]s.
class AgoraVideoCallEngine implements VideoCallEngine {
  RtcEngine? _engine;
  String _channelId = '';
  bool _initialised = false;

  RtcEngine get _e {
    final e = _engine;
    if (e == null) {
      throw StateError('AgoraVideoCallEngine.initialize() must run first.');
    }
    return e;
  }

  @override
  Future<void> initialize() async {
    if (_initialised) return;
    if (!CallConfig.isConfigured) {
      throw StateError(
        'CallConfig.configure(appId: …) must be called before initialize().',
      );
    }
    final engine = createAgoraRtcEngine();
    await engine.initialize(RtcEngineContext(appId: CallConfig.appId));
    await engine.enableVideo();
    await engine.enableAudio();
    _engine = engine;
    _initialised = true;
  }

  @override
  Future<void> joinCall(CallSession session, CallEngineEvents events) async {
    await initialize();
    _channelId = session.channelId;

    _e.registerEventHandler(RtcEngineEventHandler(
      onJoinChannelSuccess: (conn, elapsed) =>
          events.onLocalJoined(conn.localUid ?? session.uid),
      onUserJoined: (conn, remoteUid, elapsed) =>
          events.onRemoteJoined(remoteUid),
      onUserOffline: (conn, remoteUid, reason) =>
          events.onRemoteLeft(remoteUid),
      onUserMuteAudio: (conn, remoteUid, muted) =>
          events.onRemoteAudioToggled(remoteUid, !muted),
      onUserMuteVideo: (conn, remoteUid, muted) =>
          events.onRemoteVideoToggled(remoteUid, !muted),
      onConnectionLost: (conn) => events.onConnectionLost(),
      onRejoinChannelSuccess: (conn, elapsed) => events.onReconnected(),
      onError: (err, msg) => events.onError('${err.name}: $msg'),
    ));

    await _e.setClientRole(
      role: session.isBroadcaster
          ? ClientRoleType.clientRoleBroadcaster
          : ClientRoleType.clientRoleAudience,
    );
    await _e.startPreview();
    await _e.joinChannel(
      token: session.token ?? '',
      channelId: session.channelId,
      uid: session.uid,
      options: ChannelMediaOptions(
        channelProfile: ChannelProfileType.channelProfileCommunication,
        clientRoleType: session.isBroadcaster
            ? ClientRoleType.clientRoleBroadcaster
            : ClientRoleType.clientRoleAudience,
      ),
    );
  }

  @override
  Future<void> leaveCall() async {
    if (!_initialised) return;
    await _e.stopPreview();
    await _e.leaveChannel();
    _channelId = '';
  }

  @override
  Future<void> dispose() async {
    if (!_initialised) return;
    await _e.release();
    _engine = null;
    _initialised = false;
  }

  @override
  Future<void> setMicMuted(bool muted) => _e.muteLocalAudioStream(muted);

  @override
  Future<void> setCameraEnabled(bool enabled) =>
      _e.muteLocalVideoStream(!enabled);

  @override
  Future<void> setSpeakerphone(bool enabled) =>
      _e.setEnableSpeakerphone(enabled);

  @override
  Future<void> switchCamera() => _e.switchCamera();

  @override
  Widget localPreview() => AgoraVideoView(
        controller: VideoViewController(
          rtcEngine: _e,
          canvas: const VideoCanvas(uid: 0),
        ),
      );

  @override
  Widget remoteView(int uid) => AgoraVideoView(
        controller: VideoViewController.remote(
          rtcEngine: _e,
          canvas: VideoCanvas(uid: uid),
          connection: RtcConnection(channelId: _channelId),
        ),
      );
}

import 'dart:async';

import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

import 'call_models.dart';
import 'video_call_engine.dart';

/// Drives one live-consultation call on top of a [VideoCallEngine].
///
/// Owns the reactive call state (status, participants, mic/camera/speaker
/// toggles, elapsed duration) so any view can `Obx` over it. Construct one per
/// call screen and `dispose` it when the screen closes:
///
/// ```dart
/// final call = CallController(engine: AgoraVideoCallEngine());
/// await call.start(CallSession(channelId: 'consult_42', token: rtcToken));
/// // … render with VideoCallScreen(controller: call) …
/// await call.end();
/// ```
class CallController extends GetxController implements CallEngineEvents {
  final VideoCallEngine engine;

  CallController({required this.engine});

  // ── Reactive state ──────────────────────────────────────────
  final Rx<CallStatus> status = CallStatus.idle.obs;
  final RxList<CallParticipant> participants = <CallParticipant>[].obs;

  final RxBool isMicMuted = false.obs;
  final RxBool isCameraOff = false.obs;
  final RxBool isSpeakerOn = true.obs;
  final RxBool isFrontCamera = true.obs;

  /// Seconds elapsed since the call connected — for the on-screen timer.
  final RxInt elapsedSeconds = 0.obs;

  /// Last error message, if [status] is [CallStatus.failed].
  final Rxn<String> error = Rxn<String>();

  int _localUid = 0;
  Timer? _timer;

  /// Remote participants only (everyone but the local user).
  List<CallParticipant> get remoteParticipants =>
      participants.where((p) => !p.isLocal).toList();

  bool get hasRemote => remoteParticipants.isNotEmpty;

  /// Request camera + microphone permission. Returns true when both granted.
  Future<bool> ensurePermissions() async {
    final statuses = await [Permission.camera, Permission.microphone].request();
    return statuses.values.every((s) => s.isGranted);
  }

  /// Begin the call: check permissions, init the engine, and join the channel.
  Future<void> start(CallSession session) async {
    if (status.value == CallStatus.connecting ||
        status.value == CallStatus.connected) {
      return;
    }
    error.value = null;
    status.value = CallStatus.connecting;

    if (!await ensurePermissions()) {
      error.value = 'Camera and microphone permission are required';
      status.value = CallStatus.failed;
      return;
    }

    participants.assignAll([session.localUser]);

    try {
      await engine.joinCall(session, this);
    } catch (e) {
      error.value = e.toString();
      status.value = CallStatus.failed;
    }
  }

  // ── Controls ────────────────────────────────────────────────
  Future<void> toggleMic() async {
    isMicMuted.toggle();
    await engine.setMicMuted(isMicMuted.value);
    _patchLocal(audioEnabled: !isMicMuted.value);
  }

  Future<void> toggleCamera() async {
    isCameraOff.toggle();
    await engine.setCameraEnabled(!isCameraOff.value);
    _patchLocal(videoEnabled: !isCameraOff.value);
  }

  Future<void> toggleSpeaker() async {
    isSpeakerOn.toggle();
    await engine.setSpeakerphone(isSpeakerOn.value);
  }

  Future<void> switchCamera() async {
    await engine.switchCamera();
    isFrontCamera.toggle();
  }

  /// Leave the channel and tear the engine down.
  Future<void> end() async {
    _stopTimer();
    try {
      await engine.leaveCall();
    } finally {
      status.value = CallStatus.ended;
      participants.clear();
    }
  }

  // ── CallEngineEvents (from the engine) ──────────────────────
  @override
  void onLocalJoined(int uid) {
    _localUid = uid;
    status.value = hasRemote ? CallStatus.connected : CallStatus.waiting;
    _startTimer();
  }

  @override
  void onRemoteJoined(int uid) {
    if (!participants.any((p) => p.uid == uid)) {
      participants.add(CallParticipant(uid: uid, name: 'Participant'));
    }
    status.value = CallStatus.connected;
  }

  @override
  void onRemoteLeft(int uid) {
    participants.removeWhere((p) => p.uid == uid);
    if (!hasRemote && status.value == CallStatus.connected) {
      status.value = CallStatus.waiting;
    }
  }

  @override
  void onRemoteAudioToggled(int uid, bool enabled) =>
      _patchParticipant(uid, audioEnabled: enabled);

  @override
  void onRemoteVideoToggled(int uid, bool enabled) =>
      _patchParticipant(uid, videoEnabled: enabled);

  @override
  void onConnectionLost() => status.value = CallStatus.reconnecting;

  @override
  void onReconnected() =>
      status.value = hasRemote ? CallStatus.connected : CallStatus.waiting;

  @override
  void onError(String message) {
    error.value = message;
    status.value = CallStatus.failed;
  }

  // ── Helpers ─────────────────────────────────────────────────
  void _patchLocal({bool? audioEnabled, bool? videoEnabled}) =>
      _patchParticipant(_localUid,
          audioEnabled: audioEnabled, videoEnabled: videoEnabled, local: true);

  void _patchParticipant(int uid,
      {bool? audioEnabled, bool? videoEnabled, bool local = false}) {
    final i = participants.indexWhere((p) => local ? p.isLocal : p.uid == uid);
    if (i == -1) return;
    participants[i] = participants[i]
        .copyWith(audioEnabled: audioEnabled, videoEnabled: videoEnabled);
    participants.refresh();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => elapsedSeconds.value++,
    );
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  /// `mm:ss` formatted call duration for the timer label.
  String get formattedDuration {
    final s = elapsedSeconds.value;
    final m = (s ~/ 60).toString().padLeft(2, '0');
    final sec = (s % 60).toString().padLeft(2, '0');
    return '$m:$sec';
  }

  @override
  void onClose() {
    _stopTimer();
    engine.dispose();
    super.onClose();
  }
}

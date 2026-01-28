import 'dart:ui';

import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:camerawesome/pigeon.dart';
import 'package:camerawesome/src/orchestrator/camera_context.dart';
import 'package:flutter/foundation.dart';

/// When Camera is in Video mode
class VideoCameraState extends CameraState {
  VideoCameraState({
    required CameraContext cameraContext,
    required this.filePathBuilder,
  }) : super(cameraContext);

  factory VideoCameraState.from(CameraContext cameraContext) =>
      VideoCameraState(
        cameraContext: cameraContext,
        filePathBuilder: cameraContext.saveConfig!.videoPathBuilder!,
      );

  final CaptureRequestBuilder filePathBuilder;

  @override
  void setState(CaptureMode captureMode) {
    if (captureMode == CaptureMode.video) {
      return;
    }
    cameraContext.changeState(captureMode.toCameraState(cameraContext));
  }

  @override
  CaptureMode get captureMode => CaptureMode.video;

  /// You can listen to [cameraSetup.mediaCaptureStream] to get updates
  /// of the photo capture (capturing, success/failure)
  Future<CaptureRequest> startRecording() async {
    final debugConfig = CamerawesomeDebugConfig.instance;

    CaptureRequest captureRequest =
        await filePathBuilder(sensorConfig.sensors.nonNulls.toList());
    _mediaCapture = MediaCapture.capturing(
        captureRequest: captureRequest, videoState: VideoState.started);
    try {
      // ════════════════════════════════════════════════════════════════════════
      // NATIVE-LEVEL AUDIO DEBUG INJECTION
      // ════════════════════════════════════════════════════════════════════════
      // Sets native debug mode to inject failures at the NATIVE layer.
      // This allows testing that ensureAudioReady() properly detects when
      // isAudioSetup == false and handles the retry/failure correctly.
      //
      // Unlike Dart-level injection (which throws before ensureAudioReady runs),
      // native-level injection lets ensureAudioReady() actually run and detect
      // the failure state - testing the full code path.

      if (debugConfig.audioSetupFailureMode != AudioSetupFailureMode.none) {
        final nativeMode = debugConfig.nativeAudioDebugMode;
        final delayMs = debugConfig.audioPreWarmDelayMs;
        debugPrint('[CamerAwesome DEBUG] Setting native audio debug mode: $nativeMode (delay: ${delayMs}ms)');
        await CamerawesomePlugin.setNativeAudioDebugMode(nativeMode, delayMs: delayMs);
      }

      // ════════════════════════════════════════════════════════════════════════
      // JIT AUDIO SETUP - Ensures audio is ready before recording
      // ════════════════════════════════════════════════════════════════════════
      // This handles the race condition where the user taps record before audio
      // pre-warm completes. If audio isn't ready, this will retry setup.
      //
      // The native layer will:
      // 1. Check if audio is already set up (isAudioSetup flag)
      // 2. If not, retry the audio setup
      // 3. Return success/failure based on actual native state
      final audioReady = await CamerawesomePlugin.ensureAudioReady();
      if (!audioReady) {
        throw AudioSetupException('Microphone is not available');
      }

      // ════════════════════════════════════════════════════════════════════════
      // RECORDING FAILURE DEBUG INJECTION
      // ════════════════════════════════════════════════════════════════════════
      // Simulates native recording failure for testing state machine fix.

      if (debugConfig.forceRecordingFailure) {
        await Future.delayed(
            Duration(milliseconds: debugConfig.recordingFailureDelayMs));
        throw Exception(debugConfig.recordingFailureMessage);
      }
      await CamerawesomePlugin.recordVideo(captureRequest);
    } on Exception catch (e) {
      // Toggle between buggy and fixed behavior for testing
      if (debugConfig.useBuggyStateMachineBehavior) {
        // BUGGY: Original behavior - broadcast failure but STILL transition to recording state
        // This creates UI/native state mismatch: UI shows recording, native isn't recording
        // When user taps stop → crash: "video is not recording"
        //
        // Note: We intentionally DON'T broadcast failure here to simulate the original bug
        // where users got stuck in recording state (error wasn't shown to them)
        debugPrint('[CamerAwesome DEBUG] BUGGY MODE: Recording failed but transitioning to recording state anyway');
        debugPrint('[CamerAwesome DEBUG] Exception was: $e');
        cameraContext.changeState(VideoRecordingCameraState.from(cameraContext));
        return captureRequest;
      } else {
        // FIXED: Broadcast failure and rethrow - don't transition to recording state
        _mediaCapture =
            MediaCapture.failure(captureRequest: captureRequest, exception: e);
        rethrow;
      }
    }
    // Only transition to recording state if we get here (no exception)
    cameraContext.changeState(VideoRecordingCameraState.from(cameraContext));
    return captureRequest;
  }

  /// If the video recording should [enableAudio].
  /// This method applies to the next recording. If a recording is ongoing, it will not be affected.
  // TODO Add ability to mute temporarly a video recording
  Future<void> enableAudio(bool enableAudio) {
    return CamerawesomePlugin.setAudioMode(enableAudio);
  }

  /// PRIVATES

  set _mediaCapture(MediaCapture media) {
    if (!cameraContext.mediaCaptureController.isClosed) {
      cameraContext.mediaCaptureController.add(media);
    }
  }

  @override
  void dispose() {
    // Nothing to do
  }

  focus() {
    cameraContext.focus();
  }

  Future<void> focusOnPoint({
    required Offset flutterPosition,
    required PreviewSize pixelPreviewSize,
    required PreviewSize flutterPreviewSize,
    AndroidFocusSettings? androidFocusSettings,
  }) {
    return cameraContext.focusOnPoint(
      flutterPosition: flutterPosition,
      pixelPreviewSize: pixelPreviewSize,
      flutterPreviewSize: flutterPreviewSize,
      androidFocusSettings: androidFocusSettings,
    );
  }
}

import 'package:camerawesome/pigeon.dart';

/// Audio setup failure injection modes for testing.
enum AudioSetupFailureMode {
  /// No failure injection - normal behavior.
  none,

  /// Pre-warm fails, but JIT retry succeeds.
  /// Tests: Recovery path works correctly.
  preWarmFailsRetrySucceeds,

  /// Pre-warm fails, and JIT retry also fails.
  /// Tests: Error handling and user messaging.
  preWarmFailsRetryFails,

  /// Pre-warm is artificially delayed (simulates slow device/contention).
  /// Tests: Race condition timing - record button appears before audio ready.
  preWarmDelayed,

  /// Simulate microphone permission denied.
  /// Tests: Permission error handling and messaging.
  permissionDenied,
}

/// Debug configuration for CamerAwesome to enable deterministic reproduction
/// of edge cases and bugs.
///
/// This is intended for development/testing only and should never be enabled
/// in production builds.
class CamerawesomeDebugConfig {
  CamerawesomeDebugConfig._();

  static final CamerawesomeDebugConfig instance = CamerawesomeDebugConfig._();

  // ════════════════════════════════════════════════════════════════════════════
  // RECORDING FAILURE DEBUG (State Machine Bug)
  // ════════════════════════════════════════════════════════════════════════════

  /// When true, [recordVideo] will throw an exception to simulate
  /// native recording failure. This reproduces the state machine bug
  /// where UI transitions to recording state even when native fails.
  bool forceRecordingFailure = false;

  /// Delay in milliseconds before throwing the simulated failure.
  /// This mimics real-world timing where native setup takes time before failing.
  int recordingFailureDelayMs = 100;

  /// The exception message to throw when [forceRecordingFailure] is true.
  String recordingFailureMessage = 'DEBUG: Simulated recording failure';

  /// When true, uses the BUGGY behavior where state transitions even on failure.
  /// When false (default), uses the FIXED behavior where exception is rethrown.
  ///
  /// Use this to A/B test the fix:
  /// 1. Set [useBuggyStateMachineBehavior] = true  → crash on stop
  /// 2. Set [useBuggyStateMachineBehavior] = false → graceful error handling
  bool useBuggyStateMachineBehavior = false;

  /// Reset all debug flags to defaults.
  void reset() {
    // Recording failure debug
    forceRecordingFailure = false;
    recordingFailureDelayMs = 100;
    recordingFailureMessage = 'DEBUG: Simulated recording failure';
    useBuggyStateMachineBehavior = false;

    // Audio setup debug
    audioSetupFailureMode = AudioSetupFailureMode.none;
    audioPreWarmDelayMs = 1500;
    _audioSetupAttemptCount = 0;
    skipEnsureAudioReady = false;
  }

  /// Enable recording failure simulation with optional custom delay.
  void enableRecordingFailure({
    int delayMs = 100,
    String? message,
    bool useBuggyBehavior = false,
  }) {
    forceRecordingFailure = true;
    recordingFailureDelayMs = delayMs;
    useBuggyStateMachineBehavior = useBuggyBehavior;
    if (message != null) {
      recordingFailureMessage = message;
    }
  }

  /// Disable recording failure simulation.
  void disableRecordingFailure() {
    forceRecordingFailure = false;
    useBuggyStateMachineBehavior = false;
  }

  // ════════════════════════════════════════════════════════════════════════════
  // AUDIO SETUP DEBUG (Race Condition / JIT Retry Testing)
  // ════════════════════════════════════════════════════════════════════════════

  /// Audio setup failure injection mode.
  /// Used to test the JIT audio retry solution deterministically.
  AudioSetupFailureMode audioSetupFailureMode = AudioSetupFailureMode.none;

  /// Delay in milliseconds for [AudioSetupFailureMode.preWarmDelayed] mode.
  /// Simulates slow audio initialization to reproduce race conditions.
  int audioPreWarmDelayMs = 1500;

  /// Internal counter to track pre-warm vs retry attempts.
  /// Used by [preWarmFailsRetrySucceeds] to fail first attempt only.
  int _audioSetupAttemptCount = 0;

  /// Get the current audio setup attempt count (for native layer).
  int get audioSetupAttemptCount => _audioSetupAttemptCount;

  /// Increment the audio setup attempt counter.
  void incrementAudioSetupAttempt() {
    _audioSetupAttemptCount++;
  }

  /// Reset the audio setup attempt counter.
  void resetAudioSetupAttemptCount() {
    _audioSetupAttemptCount = 0;
  }

  /// Set audio setup failure injection mode.
  ///
  /// ## Test Cases:
  ///
  /// ### Case A: Pre-warm fails, retry succeeds
  /// ```dart
  /// CamerawesomeDebugConfig.instance.setAudioSetupFailure(
  ///   mode: AudioSetupFailureMode.preWarmFailsRetrySucceeds,
  /// );
  /// // Expected: Recording works after brief delay
  /// ```
  ///
  /// ### Case B: Pre-warm fails, retry fails
  /// ```dart
  /// CamerawesomeDebugConfig.instance.setAudioSetupFailure(
  ///   mode: AudioSetupFailureMode.preWarmFailsRetryFails,
  /// );
  /// // Expected: Clear error message, UI never shows recording state
  /// ```
  ///
  /// ### Case C: Pre-warm delayed (race condition)
  /// ```dart
  /// CamerawesomeDebugConfig.instance.setAudioSetupFailure(
  ///   mode: AudioSetupFailureMode.preWarmDelayed,
  ///   delayMs: 2000,
  /// );
  /// // Expected: Record button appears, tapping works after JIT blocks
  /// ```
  ///
  /// ### Case D: Permission denied
  /// ```dart
  /// CamerawesomeDebugConfig.instance.setAudioSetupFailure(
  ///   mode: AudioSetupFailureMode.permissionDenied,
  /// );
  /// // Expected: Immediate failure with actionable permission message
  /// ```
  void setAudioSetupFailure({
    required AudioSetupFailureMode mode,
    int delayMs = 1500,
  }) {
    audioSetupFailureMode = mode;
    audioPreWarmDelayMs = delayMs;
    _audioSetupAttemptCount = 0; // Reset counter when changing mode
  }

  /// Clear audio setup failure injection.
  void clearAudioSetupFailure() {
    audioSetupFailureMode = AudioSetupFailureMode.none;
    _audioSetupAttemptCount = 0;
  }

  /// Check if audio setup should fail based on current debug mode and attempt count.
  ///
  /// Returns `null` if audio setup should proceed normally.
  /// Returns error message string if audio setup should fail.
  ///
  /// For [preWarmFailsRetrySucceeds]: fails on attempt 0 (pre-warm), succeeds on attempt 1+ (retry).
  /// For [preWarmFailsRetryFails]: fails on all attempts.
  /// For [permissionDenied]: fails on all attempts with permission-specific message.
  /// For [preWarmDelayed]: returns null (delay is handled separately).
  String? shouldAudioSetupFail() {
    switch (audioSetupFailureMode) {
      case AudioSetupFailureMode.none:
        return null;

      case AudioSetupFailureMode.preWarmFailsRetrySucceeds:
        // Fail only on first attempt (pre-warm), succeed on retry
        if (_audioSetupAttemptCount == 0) {
          return 'DEBUG: Simulated pre-warm failure (retry will succeed)';
        }
        return null;

      case AudioSetupFailureMode.preWarmFailsRetryFails:
        // Fail on all attempts
        return 'DEBUG: Simulated audio setup failure (all attempts)';

      case AudioSetupFailureMode.permissionDenied:
        // Fail with permission-specific message
        return 'Microphone permission denied';

      case AudioSetupFailureMode.preWarmDelayed:
        // Delay is handled separately, no failure
        return null;
    }
  }

  /// Get delay in milliseconds for pre-warm (0 if no delay mode active).
  int getPreWarmDelayMs() {
    if (audioSetupFailureMode == AudioSetupFailureMode.preWarmDelayed &&
        _audioSetupAttemptCount == 0) {
      // Only delay on first attempt (pre-warm), not on retry
      return audioPreWarmDelayMs;
    }
    return 0;
  }

  // ════════════════════════════════════════════════════════════════════════════
  // NATIVE-LEVEL AUDIO DEBUG (Tests ensureAudioReady() detection mechanism)
  // ════════════════════════════════════════════════════════════════════════════

  /// When true, skips the ensureAudioReady() check before recording.
  /// This allows reproducing the PRODUCTION BUG where video saves without audio.
  ///
  /// Use this to A/B test the JIT audio fix:
  /// 1. Set [skipEnsureAudioReady] = true  → reproduce bug: silent video
  /// 2. Set [skipEnsureAudioReady] = false → verify fix: recording blocked
  ///
  /// ## Production Bug Reproduction Test
  ///
  /// ```dart
  /// // Step 1: Reproduce the bug (video saves without audio)
  /// CamerawesomeDebugConfig.instance.enableProductionBugReproduction();
  /// // Navigate to camera, record video, verify it has NO audio
  ///
  /// // Step 2: Verify the fix prevents the bug
  /// CamerawesomeDebugConfig.instance.enableFixVerification();
  /// // Navigate to camera, try to record, verify error toast appears
  /// ```
  bool skipEnsureAudioReady = false;

  /// Enable reproduction of the production bug where video saves without audio.
  ///
  /// This sets:
  /// - Native mode to fail ALL audio setup attempts
  /// - Skips ensureAudioReady() check (simulates code before the fix)
  ///
  /// Expected result: Video records and saves, but plays back with NO AUDIO.
  /// This proves the bug exists and the fix is needed.
  void enableProductionBugReproduction() {
    audioSetupFailureMode = AudioSetupFailureMode.preWarmFailsRetryFails;
    skipEnsureAudioReady = true;
    _audioSetupAttemptCount = 0;
  }

  /// Enable verification that the fix prevents the production bug.
  ///
  /// This sets:
  /// - Native mode to fail ALL audio setup attempts
  /// - Enables ensureAudioReady() check (the fix)
  ///
  /// Expected result: Recording is blocked with clear error message.
  /// Video is NOT saved because audio isn't available.
  void enableFixVerification() {
    audioSetupFailureMode = AudioSetupFailureMode.preWarmFailsRetryFails;
    skipEnsureAudioReady = false;
    _audioSetupAttemptCount = 0;
  }

  /// Verifies that the audio failure state was properly reproduced.
  ///
  /// Call this AFTER camera initialization to confirm the debug injection worked.
  /// Returns a description of the verification result.
  ///
  /// Example usage:
  /// ```dart
  /// CamerawesomeDebugConfig.instance.enableProductionBugReproduction();
  /// // Navigate to camera (camera inits)
  /// // After camera is ready:
  /// final result = await CamerawesomeDebugConfig.instance.verifyAudioFailureState();
  /// print(result); // "✓ Audio is NOT set up (as expected for bug reproduction)"
  /// ```
  Future<String> verifyAudioFailureState() async {
    final isSetup = await CameraInterface().isAudioSetup();

    if (audioSetupFailureMode == AudioSetupFailureMode.none) {
      return '⚠️ No audio failure mode active. Call enableProductionBugReproduction() first.';
    }

    if (isSetup) {
      return '❌ Audio IS set up - debug injection may not have worked. '
          'Try hot restarting the app after setting the debug mode.';
    } else {
      return '✓ Audio is NOT set up (as expected for bug reproduction). '
          'If skipEnsureAudioReady=true, video will record without audio.';
    }
  }

  /// Convert [AudioSetupFailureMode] to native debug mode integer.
  ///
  /// Native debug modes:
  /// - 0: none (normal behavior)
  /// - 1: preWarmFailsRetrySucceeds
  /// - 2: preWarmFailsRetryFails
  /// - 3: preWarmDelayed
  /// - 4: permissionDenied
  int audioSetupFailureModeToNativeMode(AudioSetupFailureMode mode) {
    switch (mode) {
      case AudioSetupFailureMode.none:
        return 0;
      case AudioSetupFailureMode.preWarmFailsRetrySucceeds:
        return 1;
      case AudioSetupFailureMode.preWarmFailsRetryFails:
        return 2;
      case AudioSetupFailureMode.preWarmDelayed:
        return 3;
      case AudioSetupFailureMode.permissionDenied:
        return 4;
    }
  }

  /// Get the native debug mode integer for the current [audioSetupFailureMode].
  int get nativeAudioDebugMode =>
      audioSetupFailureModeToNativeMode(audioSetupFailureMode);
}

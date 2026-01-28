/// Debug configuration for CamerAwesome to enable deterministic reproduction
/// of edge cases and bugs.
///
/// This is intended for development/testing only and should never be enabled
/// in production builds.
class CamerawesomeDebugConfig {
  CamerawesomeDebugConfig._();

  static final CamerawesomeDebugConfig instance = CamerawesomeDebugConfig._();

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
    forceRecordingFailure = false;
    recordingFailureDelayMs = 100;
    recordingFailureMessage = 'DEBUG: Simulated recording failure';
    useBuggyStateMachineBehavior = false;
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
}

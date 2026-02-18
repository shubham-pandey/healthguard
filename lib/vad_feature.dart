import 'package:runanywhere/runanywhere.dart';

class VADFeature {
  VoiceSessionHandle? _currentSession;
  bool _isListening = false;

  bool get isListening => _isListening;
  bool get hasActiveSession => _currentSession != null;

  /// Start a voice session with VAD
  /// The session automatically detects speech activity and can orchestrate
  /// STT, LLM, and TTS in sequence
  Future<void> startVoiceSession({
    double speechThreshold = 0.03,
    double silenceDuration = 1.5,
    bool continuousMode = true,
  }) async {
    try {
      if (_currentSession != null) {
        print('⚠ Voice session already active');
        return;
      }

      _currentSession = await RunAnywhere.startVoiceSession(
        config: VoiceSessionConfig(
          speechThreshold: speechThreshold,
          silenceDuration: silenceDuration,
          continuousMode: continuousMode,
        ),
      );

      print('✓ Voice session started');
      _isListening = true;

      // Listen to session events
      _currentSession!.events.listen(_handleVoiceEvent);
    } catch (e) {
      print('✗ Failed to start voice session: $e');
      rethrow;
    }
  }

  /// Stop the current voice session
  Future<void> stopVoiceSession() async {
    try {
      if (_currentSession == null) {
        print('⚠ No active voice session');
        return;
      }

      _currentSession!.stop();
      _currentSession = null;
      _isListening = false;

      print('✓ Voice session stopped');
    } catch (e) {
      print('✗ Failed to stop voice session: $e');
      rethrow;
    }
  }

  /// Handle different voice session events
  void _handleVoiceEvent(VoiceSessionEvent event) {
    switch (event) {
      case VoiceSessionListening(:final audioLevel):
        print('🎤 Listening... (level: ${(audioLevel * 100).toStringAsFixed(1)}%)');
        break;

      case VoiceSessionSpeechStarted():
        print('🗣️ Speech detected');
        break;

      case VoiceSessionSpeechEnded():
        print('🤐 Speech ended');
        break;

      case VoiceSessionProcessing():
        print('⏳ Processing...');
        break;

      case VoiceSessionTranscribed(:final text):
        print('📝 You: $text');
        break;

      case VoiceSessionResponded(:final text):
        print('🤖 AI: $text');
        break;

      case VoiceSessionSpeaking():
        print('🔊 AI speaking...');
        break;

      case VoiceSessionTurnCompleted():
        print('✅ Turn completed');
        break;

      case VoiceSessionError(:final message):
        print('❌ Error: $message');
        break;

      case VoiceSessionStopped():
        print('⛔ Session stopped');
        break;

      default:
        break;
    }
  }

  /// Configure VAD sensitivity for quiet environments
  /// Use this when the app runs in quiet environments
  Future<void> setSensitiveVAD() async {
    try {
      await stopVoiceSession();
      await startVoiceSession(
        speechThreshold: 0.01,
        silenceDuration: 1.0,
      );
      print('✓ VAD set to sensitive mode');
    } catch (e) {
      print('✗ Failed to set sensitive VAD: $e');
    }
  }

  /// Configure VAD for noisy environments
  /// Use this when the app runs in noisy environments
  Future<void> setRobustVAD() async {
    try {
      await stopVoiceSession();
      await startVoiceSession(
        speechThreshold: 0.1,
        silenceDuration: 2.0,
      );
      print('✓ VAD set to robust mode');
    } catch (e) {
      print('✗ Failed to set robust VAD: $e');
    }
  }

  /// Get real-time audio level stream (if available through session)
  Stream<VoiceSessionEvent> get voiceEvents {
    if (_currentSession == null) {
      throw Exception('No active voice session');
    }
    return _currentSession!.events;
  }

  /// Clean up resources
  Future<void> dispose() async {
    if (_currentSession != null) {
      await stopVoiceSession();
    }
  }
}

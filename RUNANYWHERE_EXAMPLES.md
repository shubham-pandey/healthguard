flutter config --android-sdk /Users/shubham3327/Library/Android/sdk# RunAnywhere SDK Usage Examples

This document provides practical examples for using each RunAnywhere SDK feature in your HealthGuard app.

## Quick Start

### 1. Initialize the SDK

**Location:** main.dart (already done)

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final service = RunAnywhereService();
  try {
    await service.initialize();
    await service.setupLLM();    // For LLM features
    await service.setupSTT();    // For speech recognition
    await service.setupTTS();    // For voice synthesis
    await service.setupVAD();    // For voice detection
    print('✓ RunAnywhere SDK ready');
  } catch (e) {
    print('✗ Initialization failed: $e');
  }

  runApp(const MyApp());
}
```

## LLM Usage Examples

### Example 1: Simple Health Question

```dart
final llm = LLMFeature();

// Get simple response
try {
  final response = await llm.chat('What are the benefits of drinking water?');
  print(response);
  // Output: "Drinking water has many benefits including..."
} catch (e) {
  print('Error: $e');
}
```

### Example 2: Streaming Response

```dart
final llm = LLMFeature();

Future<void> streamHealthAdvice(String topic) async {
  try {
    final streamResult = await llm.generateStream(
      'Provide health advice about $topic',
      maxTokens: 500,
      temperature: 0.7,
    );

    String fullResponse = '';
    
    // Stream tokens in real-time
    await for (final token in streamResult.stream) {
      fullResponse += token;
      print(fullResponse); // Update UI with each token
    }

    // Get metrics after streaming completes
    final metrics = await streamResult.result;
    print('Generated ${metrics.tokensUsed} tokens in ${metrics.latencyMs}ms');
  } catch (e) {
    print('Error: $e');
  }
}

// Usage
streamHealthAdvice('fitness routines');
```

### Example 3: Health Assistant with Context

```dart
final llm = LLMFeature();

Future<void> askHealthAssistant(String question) async {
  try {
    final response = await llm.askHealthQuestion(question);
    print('Assistant: $response');
  } catch (e) {
    print('Error: $e');
  }
}

// Usage
askHealthAssistant('I have been feeling tired lately, what should I do?');
```

### Example 4: Generate with Metrics

```dart
final llm = LLMFeature();

Future<void> generateDetailedResponse(String prompt) async {
  try {
    final result = await llm.generate(
      prompt,
      maxTokens: 256,
      temperature: 0.8,
      topP: 0.95,
      systemPrompt: 'You are a friendly health coach.',
    );

    print('Response: ${result.text}');
    print('Tokens used: ${result.tokensUsed}');
    print('Speed: ${result.tokensPerSecond.toStringAsFixed(1)} tok/s');
    print('Latency: ${result.latencyMs.toStringAsFixed(0)}ms');
  } catch (e) {
    print('Error: $e');
  }
}
```

## STT (Speech-to-Text) Usage Examples

### Example 1: Record and Transcribe

```dart
final stt = STTFeature();

Future<String?> recordAndTranscribeVoice() async {
  // Start recording
  final started = await stt.startRecording();
  if (!started) {
    print('Failed to start recording');
    return null;
  }

  print('Recording... Speak now');

  // Wait for user to speak
  await Future.delayed(const Duration(seconds: 5));

  // Stop and get audio
  final audioBytes = await stt.stopRecording();
  if (audioBytes == null) return null;

  // Transcribe
  try {
    final text = await stt.transcribe(audioBytes);
    print('Transcribed: $text');
    return text;
  } catch (e) {
    print('Transcription error: $e');
    return null;
  }
}

// Usage
void main() async {
  final transcribedText = await recordAndTranscribeVoice();
  if (transcribedText != null) {
    print('You said: $transcribedText');
  }
}
```

### Example 2: Get Confidence & Metadata

```dart
final stt = STTFeature();

Future<void> transcribeWithDetails(Uint8List audioBytes) async {
  try {
    final result = await stt.transcribeWithResult(audioBytes);

    print('Text: ${result.text}');
    print('Confidence: ${(result.confidence * 100).toStringAsFixed(1)}%');
    print('Duration: ${result.durationMs}ms');
    if (result.language != null) {
      print('Language: ${result.language}');
    }
  } catch (e) {
    print('Error: $e');
  }
}
```

### Example 3: Manual Recording Control

```dart
final stt = STTFeature();
bool isRecording = false;

Future<void> startRecording() async {
  final started = await stt.startRecording();
  if (started) {
    isRecording = true;
    print('Recording started');
  }
}

Future<void> stopAndTranscribe() async {
  if (!isRecording) return;

  isRecording = false;
  final audioBytes = await stt.stopRecording();

  if (audioBytes != null) {
    final text = await stt.transcribe(audioBytes);
    print('Result: $text');
  }
}
```

## TTS (Text-to-Speech) Usage Examples

### Example 1: Speak Simple Text

```dart
final tts = TTSFeature();

Future<void> speakHealthTip(String tip) async {
  try {
    await tts.speakText(tip);
    print('Speaking...');
  } catch (e) {
    print('Error: $e');
  }
}

// Usage
speakHealthTip('Remember to drink at least 8 glasses of water daily!');
```

### Example 2: Speak with Custom Parameters

```dart
final tts = TTSFeature();

Future<void> speakWithCustomization(String text, {
  double rate = 1.0,
  double pitch = 1.0,
  double volume = 1.0,
}) async {
  try {
    // For important announcements - slower and more emphatic
    await tts.speakText(
      text,
      rate: 0.8,    // Slower
      pitch: 1.1,   // Slightly higher pitch
      volume: 1.0,  // Full volume
    );
  } catch (e) {
    print('Error: $e');
  }
}

// Usage
speakWithCustomization(
  'This is an important health alert!',
  rate: 0.8,
  pitch: 1.2,
);
```

### Example 3: Playback Control

```dart
final tts = TTSFeature();

Future<void> demonstratePlaybackControl() async {
  try {
    // Start speaking
    await tts.speakText('This is a long wellness message...');

    // Later - pause
    await tts.pause();
    print('Audio paused');

    // Resume
    await tts.resume();
    print('Audio resumed');

    // Stop
    await tts.stop();
    print('Audio stopped');

    // Check state
    final state = tts.getCurrentState();
    print('Current state: $state');
  } catch (e) {
    print('Error: $e');
  }
}
```

### Example 4: Listen to State Changes

```dart
final tts = TTSFeature();

Future<void> setupAudioStateListener() async {
  tts.onStateChanged().listen((state) {
    switch (state) {
      case PlayerState.playing:
        print('Audio playing');
      case PlayerState.paused:
        print('Audio paused');
      case PlayerState.stopped:
        print('Audio stopped');
      case PlayerState.completed:
        print('Audio completed');
      case PlayerState.disposed:
        print('Audio player disposed');
    }
  });
}
```

## VAD (Voice Activity Detection) Usage Examples

### Example 1: Simple Voice Session

```dart
final vad = VADFeature();

Future<void> startVoiceSession() async {
  try {
    await vad.startVoiceSession(
      speechThreshold: 0.03,
      silenceDuration: 1.5,
    );
    print('Listening for voice...');
  } catch (e) {
    print('Error: $e');
  }
}

Future<void> endVoiceSession() async {
  await vad.stopVoiceSession();
  print('Voice session ended');
}
```

### Example 2: Handle Voice Events

```dart
final vad = VADFeature();

Future<void> monitorVoiceEvents() async {
  await vad.startVoiceSession();

  vad.voiceEvents.listen((event) {
    switch (event.runtimeType.toString()) {
      case 'VoiceSessionListening':
        print('🎤 Listening...');
      case 'VoiceSessionSpeechStarted':
        print('🗣️ Speech detected!');
      case 'VoiceSessionSpeechEnded':
        print('🤐 User stopped speaking');
      case 'VoiceSessionProcessing':
        print('⏳ Processing...');
      case 'VoiceSessionTranscribed':
        print('📝 Transcription complete');
      case 'VoiceSessionResponded':
        print('🤖 AI responded');
      case 'VoiceSessionTurnCompleted':
        print('✅ Turn complete');
      default:
        print('Event: ${event.runtimeType}');
    }
  });
}
```

### Example 3: Environment-Specific Configuration

```dart
final vad = VADFeature();

Future<void> setForQuietEnvironment() async {
  // Office, study room, library
  await vad.setSensitiveVAD();
  print('VAD set to sensitive mode for quiet environment');
}

Future<void> setForNoisyEnvironment() async {
  // Coffee shop, outdoor, event
  await vad.setRobustVAD();
  print('VAD set to robust mode for noisy environment');
}
```

## Complete Integration Example

### Health Voice Assistant

This example combines LLM, STT, TTS, and VAD into a complete voice assistant:

```dart
class HealthVoiceAssistant {
  final llm = LLMFeature();
  final stt = STTFeature();
  final tts = TTSFeature();
  final vad = VADFeature();

  Future<void> run() async {
    print('Starting health voice assistant...');

    await vad.startVoiceSession(
      speechThreshold: 0.03,
      silenceDuration: 1.5,
    );

    // Listen for speech
    vad.voiceEvents.listen((event) async {
      switch (event.runtimeType.toString()) {
        case 'VoiceSessionSpeechEnded':
          await _processUserSpeech();
          break;
        default:
          break;
      }
    });
  }

  Future<void> _processUserSpeech() async {
    try {
      // 1. Record and transcribe
      print('Recording...');
      final started = await stt.startRecording();
      if (!started) return;

      await Future.delayed(const Duration(seconds: 5));
      final audioBytes = await stt.stopRecording();
      if (audioBytes == null) return;

      print('Transcribing...');
      final userQuestion = await stt.transcribe(audioBytes);
      print('User: $userQuestion');

      // 2. Generate response
      print('Generating response...');
      final response = await llm.askHealthQuestion(userQuestion);
      print('Assistant response ready');

      // 3. Speak response
      print('Speaking...');
      await tts.speakText(response);
      print('Done!');
    } catch (e) {
      print('Error: $e');
      await tts.speakText('Sorry, I encountered an error. Please try again.');
    }
  }

  Future<void> stop() async {
    await vad.stopVoiceSession();
    await tts.stop();
    stt.dispose();
    tts.dispose();
    vad.dispose();
  }
}

// Usage
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final assistant = HealthVoiceAssistant();
  await assistant.run();

  // Run for 30 seconds
  await Future.delayed(const Duration(seconds: 30));
  await assistant.stop();
}
```

## Error Handling Patterns

### Pattern 1: Graceful Degradation

```dart
Future<String> askQuestion(String question) async {
  try {
    return await llm.chat(question);
  } catch (e) {
    print('LLM failed: $e');
    return 'I encountered a technical issue. Please try again.';
  }
}
```

### Pattern 2: Retry Logic

```dart
Future<String?> transcribeWithRetry(
  Uint8List audioBytes, {
  int maxRetries = 3,
}) async {
  for (int i = 0; i < maxRetries; i++) {
    try {
      return await stt.transcribe(audioBytes);
    } catch (e) {
      print('Attempt ${i + 1} failed: $e');
      if (i < maxRetries - 1) {
        await Future.delayed(Duration(milliseconds: 500 * (i + 1)));
      }
    }
  }
  return null;
}
```

### Pattern 3: Timeout Handling

```dart
Future<String> generateWithTimeout(String prompt) async {
  try {
    final streamResult = await llm.generateStream(prompt);
    
    // Set timeout for streaming
    await streamResult.stream
        .timeout(
          const Duration(seconds: 30),
          onTimeout: () async {
            streamResult.cancel();
            return '';
          },
        )
        .forEach((token) {
      // Process token
    });

    return 'Generation completed';
  } on TimeoutException {
    print('Generation timed out');
    return 'Request timed out. Please try again.';
  }
}
```

## Performance Tips

1. **Preload Models:** Download models before user needs them
2. **Stream for UX:** Use streaming for better perceived performance
3. **Cancel Long Operations:** Provide cancel buttons for long operations
4. **Batch Requests:** Process multiple items together when possible
5. **Monitor Memory:** Keep track of model memory usage
6. **Use Appropriate Models:** Match model size to device capabilities

## Permissions Testing

### iOS
```bash
# Run on iOS simulator/device
flutter run -d ios
# Check microphone permissions in Settings > HealthGuard
```

### Android
```bash
# Run on Android
flutter run -d android
# Grant microphone permission when prompted
```

## Integration Checklist

- [ ] Dependencies added to pubspec.yaml
- [ ] iOS Podfile updated (14.0, static linkage)
- [ ] iOS Info.plist has microphone permission
- [ ] Android manifest has RECORD_AUDIO permission
- [ ] RunAnywhereService initialized in main()
- [ ] Error handling implemented
- [ ] Models tested to load successfully
- [ ] Demo screens working
- [ ] Permissions requested and granted
- [ ] Production build tested

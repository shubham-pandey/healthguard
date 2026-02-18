# RunAnywhere SDK Integration Guide

This document outlines the complete RunAnywhere SDK implementation in the HealthGuard Flutter app, including on-device LLM, STT, TTS, and VAD capabilities.

## Overview

The RunAnywhere SDK provides production-grade, on-device AI capabilities for Flutter applications, ensuring:
- ✓ 100% on-device inference (offline capable)
- ✓ Minimal latency
- ✓ Maximum privacy
- ✓ No network connectivity required after model download

## Architecture

### Project Structure

```
lib/
├── main.dart                          # SDK initialization
├── app/screens/
│   ├── login.dart                     # Updated with RunAnywhere demo section
│   ├── ai_chat_screen.dart            # LLM demonstration
│   └── voice_interaction_screen.dart  # STT, TTS, VAD demonstration
└── services/
    ├── runanywhere_service.dart       # Core SDK service
    ├── llm_feature.dart               # LLM text generation
    ├── stt_feature.dart               # Speech-to-Text
    ├── tts_feature.dart               # Text-to-Speech
    └── vad_feature.dart               # Voice Activity Detection
```

## Features Implemented

### 1. LLM (Large Language Model)

**File:** [lib/services/llm_feature.dart](lib/services/llm_feature.dart)

**Capabilities:**
- Simple chat responses with `chat()`
- Full text generation with metrics using `generate()`
- Real-time token streaming with `generateStream()`
- System prompts for contextual responses
- Generation cancellation support
- Health assistant specialized mode

**Model:** SmolLM2 360M Q8_0 (~500MB)

**Usage Example:**
```dart
final llm = LLMFeature();
final streamResult = await llm.generateStream('Your question here');
await for (final token in streamResult.stream) {
  print(token); // Real-time token output
}
```

### 2. STT (Speech-to-Text)

**File:** [lib/services/stt_feature.dart](lib/services/stt_feature.dart)

**Capabilities:**
- Real-time audio recording (16kHz mono, PCM16)
- Batch audio transcription
- Detailed results with confidence scores
- Language detection
- Recording and transcription in one step

**Model:** Whisper Tiny English (~75MB)

**Requirements:**
- Microphone permission
- Audio format: PCM16 at 16kHz mono

**Usage Example:**
```dart
final stt = STTFeature();
await stt.startRecording();
// User speaks...
final audioBytes = await stt.stopRecording();
final text = await stt.transcribe(audioBytes);
print('You said: $text');
```

### 3. TTS (Text-to-Speech)

**File:** [lib/services/tts_feature.dart](lib/services/tts_feature.dart)

**Capabilities:**
- Neural voice synthesis with customizable parameters
- Real-time audio playback
- Pitch, rate, and volume control
- WAV file conversion and playback
- Audio state tracking

**Model:** Piper US English (Lessac) (~50MB)

**Parameters:**
- `rate` (0.5-2.0): Speech speed
- `pitch` (0.5-2.0): Voice pitch
- `volume` (0.0-1.0): Volume level

**Usage Example:**
```dart
final tts = TTSFeature();
await tts.speakText('Hello world!', rate: 1.0, pitch: 1.0);
```

### 4. VAD (Voice Activity Detection)

**File:** [lib/services/vad_feature.dart](lib/services/vad_feature.dart)

**Capabilities:**
- Automatic speech detection
- Hands-free voice interfaces
- Real-time audio level monitoring
- Configurable sensitivity thresholds
- Complete voice pipeline orchestration (VAD → STT → LLM → TTS)

**Parameters:**
- `speechThreshold` (0.01-0.1): Sensitivity to speech
- `silenceDuration` (0.5-2.0): Seconds of silence before processing

**Environment Presets:**
- **Sensitive Mode:** `speechThreshold: 0.01, silenceDuration: 1.0`
- **Robust Mode:** `speechThreshold: 0.1, silenceDuration: 2.0`

**Usage Example:**
```dart
final vad = VADFeature();
await vad.startVoiceSession();
vad.voiceEvents.listen((event) {
  // Handle VAD events
});
```

## Installation & Setup

### 1. Dependencies Added

**pubspec.yaml** includes:
```yaml
dependencies:
  runanywhere: ^0.15.11
  runanywhere_llamacpp: ^0.15.11
  runanywhere_onnx: ^0.15.11
  record: ^5.0.0
  audioplayers: ^6.0.0
  path_provider: ^2.1.0
```

### 2. iOS Configuration

**Updated ios/Podfile:**
```ruby
# Set minimum iOS version to 14.0
platform :ios, '14.0'

target 'Runner' do
  # REQUIRED: Static linkage
  use_frameworks! :linkage => :static
  # ... rest of configuration
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '14.0'
      config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= [
        '$(inherited)',
        'PERMISSION_MICROPHONE=1',
      ]
    end
  end
end
```

**Added ios/Runner/Info.plist:**
```xml
<key>NSMicrophoneUsageDescription</key>
<string>This app needs microphone access for speech recognition and voice features</string>
```

### 3. Android Configuration

**Updated android/app/src/main/AndroidManifest.xml:**
```xml
<uses-permission android:name="android.permission.RECORD_AUDIO" />
```

### 4. Initialize SDK in main.dart

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final service = RunAnywhereService();
  try {
    await service.initialize();
    print('✓ RunAnywhere SDK initialized');
  } catch (e) {
    print('✗ Failed to initialize: $e');
  }

  runApp(const MyApp());
}
```

## Service Layer Architecture

### RunAnywhereService

**Purpose:** Central service for SDK lifecycle management

**Key Methods:**
- `initialize()` - Initialize the core SDK
- `setupLLM()` - Register LlamaCpp backend
- `setupSTT()` - Register ONNX for speech recognition
- `setupTTS()` - Register ONNX for speech synthesis
- `setupVAD()` - Prepare voice activity detection
- `downloadModel(modelId)` - Download model with progress
- `loadModel(modelId)` - Load model into memory

### Feature Services

Each feature has its own service class with domain-specific methods:

**LLMFeature:**
- `chat()` - Simple response
- `generate()` - Full response with metrics
- `generateStream()` - Real-time token streaming
- `cancelGeneration()` - Cancel ongoing generation

**STTFeature:**
- `startRecording()` - Begin audio capture
- `stopRecording()` - Stop and return audio bytes
- `transcribe()` - Convert audio to text
- `recordAndTranscribe()` - Combined operation

**TTSFeature:**
- `synthesize()` - Convert text to audio
- `speakText()` - Synthesize and play
- `stop()`, `pause()`, `resume()` - Playback control

**VADFeature:**
- `startVoiceSession()` - Begin VAD listening
- `stopVoiceSession()` - Stop VAD session
- `setSensitiveVAD()` - Optimize for quiet environments
- `setRobustVAD()` - Optimize for noisy environments

## Demo Screens

### AI Chat Screen

**Location:** [lib/app/screens/ai_chat_screen.dart](lib/app/screens/ai_chat_screen.dart)

**Features:**
- Model download progress tracking
- Real-time token streaming
- Performance metrics display
- Cancel generation support
- Health assistant context

### Voice Interaction Screen

**Location:** [lib/app/screens/voice_interaction_screen.dart](lib/app/screens/voice_interaction_screen.dart)

**Features:**
- Real-time audio level visualization
- STT recording and transcription
- TTS audio playback with controls
- VAD voice session management
- Comprehensive event monitoring

## Model Information

| Feature | Model | Size | Format | Backend |
|---------|-------|------|--------|---------|
| LLM | SmolLM2 360M Q8_0 | ~500MB | GGUF | LlamaCpp |
| STT | Whisper Tiny EN | ~75MB | ONNX | ONNX Runtime |
| TTS | Piper US English | ~50MB | ONNX | ONNX Runtime |
| VAD | Silero VAD | Built-in | - | ONNX Runtime |

## Performance Considerations

### LLM
- **Speed:** ~5-15 tokens/sec on ARM64 devices
- **Memory:** ~500-800MB peak usage
- **GPU:** Metal acceleration on iOS, NEON on Android

### STT
- **Latency:** Real-time streaming with <100ms overhead
- **Accuracy:** 94% on English audio (Whisper Tiny)
- **Format:** Requires 16kHz mono PCM

### TTS
- **Latency:** Sub-second synthesis for short text
- **Quality:** Natural-sounding neural voices
- **Format:** Float32 PCM at 22050Hz

### VAD
- **Latency:** <50ms detection time
- **CPU:** Minimal overhead (<5%)
- **Configurable:** Adjust sensitivity based on environment

## Best Practices

### 1. Model Management
```dart
// Check if model is downloaded before loading
final isDownloaded = await service.isModelDownloaded('model-id');
if (!isDownloaded) {
  await for (final progress in service.downloadModel('model-id')) {
    updateProgressUI(progress);
    if (progress.state.isCompleted) break;
  }
}
```

### 2. Error Handling
```dart
try {
  final result = await llm.generate(prompt);
} on SDKError catch (e) {
  print('SDK Error: ${e.message}');
} catch (e) {
  print('Unexpected error: $e');
}
```

### 3. Resource Cleanup
```dart
@override
void dispose() {
  stt.dispose();
  tts.dispose();
  vad.dispose();
  super.dispose();
}
```

### 4. STT Audio Format
```dart
// CRITICAL: Whisper requires specific format
await recorder.start(
  const RecordConfig(
    encoder: AudioEncoder.pcm16bits,
    sampleRate: 16000,
    numChannels: 1,
  ),
);
```

### 5. VAD Tuning
```dart
// For quiet environments (offices, quiet rooms)
await vad.setSensitiveVAD(); // threshold: 0.01

// For noisy environments (outdoors, events)
await vad.setRobustVAD(); // threshold: 0.1
```

## Troubleshooting

### iOS Build Issues
- **"Symbol not found" errors:** Ensure `use_frameworks! :linkage => :static` in Podfile
- **Microphone permission denied:** Check Info.plist has NSMicrophoneUsageDescription
- **Pod install fails:** Run `cd ios && pod repo update && pod install && cd ..`

### Android Issues
- **Record permission denied:** Add android:name="android.permission.RECORD_AUDIO" to manifest
- **Model not loading:** Check app has storage permissions
- **Audio playback issues:** Ensure audio focus is properly handled

### Runtime Errors
- **"Model not loaded" exception:** Call `loadModel()` before using features
- **STT transcription fails:** Verify audio is 16kHz mono PCM format
- **TTS playback silent:** Check volume settings and audio permissions

## Documentation References

- **RunAnywhere Docs:** https://docs.runanywhere.ai/
- **Flutter SDK Intro:** https://docs.runanywhere.ai/flutter/introduction
- **Quick Start:** https://docs.runanywhere.ai/flutter/quick-start
- **LLM Chat:** https://docs.runanywhere.ai/flutter/llm/chat
- **Streaming:** https://docs.runanywhere.ai/flutter/llm/stream
- **STT:** https://docs.runanywhere.ai/flutter/stt/transcribe
- **TTS:** https://docs.runanywhere.ai/flutter/tts/synthesize
- **VAD:** https://docs.runanywhere.ai/flutter/vad

## Next Steps

1. **Test the demo:** Run the app and test AI Chat and Voice Interaction screens
2. **Integrate into your UI:** Copy service classes and adapt to your screens
3. **Customize models:** Replace with larger/different models as needed
4. **Add health context:** Use health-specific prompts and commands
5. **Optimize for deployment:** Consider model quantization and caching strategies

## Support & Resources

- Official Repository: https://github.com/RunanywhereAI/flutter-starter-example
- Documentation: https://docs.runanywhere.ai/flutter/introduction
- Issue Tracker: Check RunAnywhere repository

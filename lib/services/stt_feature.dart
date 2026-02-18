import 'dart:typed_data';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:runanywhere/runanywhere.dart';

class STTFeature {
  final AudioRecorder _recorder = AudioRecorder();
  String? _currentRecordingPath;

  /// Start recording audio in the correct format for STT
  /// Returns true if recording started successfully
  Future<bool> startRecording() async {
    try {
      // Check microphone permission
      if (! await _recorder.hasPermission()) {
        print('✗ Microphone permission denied');
        return false;
      }

      // Get temporary directory
      final tempDir = await getTemporaryDirectory();
      _currentRecordingPath = '${tempDir.path}/stt_recording_${DateTime.now().millisecondsSinceEpoch}.pcm';

      // Start recording with correct format for Whisper
      // Whisper expects: PCM16 at 16kHz mono
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: 16000,
          numChannels: 1,
        ),
        path: _currentRecordingPath!,
      );

      print('✓ Recording started: $_currentRecordingPath');
      return true;
    } catch (e) {
      print('✗ Failed to start recording: $e');
      return false;
    }
  }

  /// Stop recording and return audio bytes
  Future<Uint8List?> stopRecording() async {
    try {
      final path = await _recorder.stop();
      if (path == null || _currentRecordingPath == null) {
        print('✗ No recording active');
        return null;
      }

      final audioFile = File(_currentRecordingPath!);
      if (!await audioFile.exists()) {
        print('✗ Recording file not found');
        return null;
      }

      final audioBytes = await audioFile.readAsBytes();
      print('✓ Recording stopped: ${audioBytes.length} bytes');
      return audioBytes;
    } catch (e) {
      print('✗ Failed to stop recording: $e');
      return null;
    }
  }

  /// Transcribe audio bytes
  Future<String> transcribe(Uint8List audioBytes) async {
    try {
      if (!RunAnywhere.isModelLoaded) {
        throw Exception('STT model not loaded');
      }

      final text = await RunAnywhere.transcribe(audioBytes);
      print('✓ Transcription: $text');
      return text;
    } catch (e) {
      print('✗ Transcription error: $e');
      rethrow;
    }
  }

  /// Transcribe audio with detailed result (confidence, duration, language)
  Future<STTResult> transcribeWithResult(Uint8List audioBytes) async {
    try {
      if (!RunAnywhere.isModelLoaded) {
        throw Exception('STT model not loaded');
      }

      final result = await RunAnywhere.transcribeWithResult(audioBytes);
      print('✓ Transcription: ${result.text}');
      print('  Confidence: ${(result.confidence * 100).toStringAsFixed(1)}%');
      print('  Duration: ${result.durationMs}ms');
      if (result.language != null) {
        print('  Language: ${result.language}');
      }
      return result;
    } catch (e) {
      print('✗ Transcription error: $e');
      rethrow;
    }
  }

  /// Record and transcribe in one step
  Future<String?> recordAndTranscribe({
    Duration maxDuration = const Duration(seconds: 30),
  }) async {
    try {
      // Start recording
      final started = await startRecording();
      if (!started) return null;

      // Wait for user to finish speaking (or max duration)
      // In a real app, you'd use VAD to detect when user stops speaking
      await Future.delayed(const Duration(seconds: 2));

      // Stop recording
      final audioBytes = await stopRecording();
      if (audioBytes == null) return null;

      // Transcribe
      return await transcribe(audioBytes);
    } catch (e) {
      print('✗ Record and transcribe error: $e');
      rethrow;
    }
  }

  /// Clean up resources
  void dispose() {
    _recorder.dispose();
    // Optionally delete temporary files
  }
}

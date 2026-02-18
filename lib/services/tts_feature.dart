import 'dart:typed_data';
import 'package:runanywhere/runanywhere.dart';
import 'package:audioplayers/audioplayers.dart';

class TTSFeature {
  final AudioPlayer _player = AudioPlayer();
  bool _isSpeaking = false;

  bool get isSpeaking => _isSpeaking;

  /// Synthesize text to speech
  Future<TTSResult> synthesize(
    String text, {
    double rate = 1.0,
    double pitch = 1.0,
    double volume = 1.0,
  }) async {
    try {
      if (!RunAnywhere.isModelLoaded) {
        throw Exception('TTS model not loaded');
      }

      final result = await RunAnywhere.synthesize(
        text,
        rate: rate.clamp(0.5, 2.0),
        pitch: pitch.clamp(0.5, 2.0),
        volume: volume.clamp(0.0, 1.0),
      );

      print('✓ Synthesized: ${result.durationSeconds.toStringAsFixed(2)}s');
      return result;
    } catch (e) {
      print('✗ Synthesis error: $e');
      rethrow;
    }
  }

  /// Synthesize and play audio
  Future<void> speakText(
    String text, {
    double rate = 1.0,
    double pitch = 1.0,
    double volume = 1.0,
  }) async {
    try {
      _isSpeaking = true;

      // Synthesize
      final result = await synthesize(
        text,
        rate: rate,
        pitch: pitch,
        volume: volume,
      );

      // Convert Float32 PCM to WAV bytes
      final wavBytes = _convertToWav(result.samples, result.sampleRate);

      // Play audio
      await _player.play(BytesSource(wavBytes));

      print('✓ Playing audio');
    } catch (e) {
      print('✗ Speak error: $e');
      _isSpeaking = false;
      rethrow;
    } finally {
      _isSpeaking = false;
    }
  }

  /// Stop current playback
  Future<void> stop() async {
    await _player.stop();
    _isSpeaking = false;
  }

  /// Pause playback
  Future<void> pause() async {
    await _player.pause();
  }

  /// Resume playback
  Future<void> resume() async {
    await _player.resume();
  }

  /// Get current playback state
  PlayerState getCurrentState() {
    return _player.state;
  }

  /// Listen to audio state changes
  Stream<PlayerState> onStateChanged() {
    return _player.onPlayerStateChanged;
  }

  /// Convert Float32 PCM to WAV file format
  Uint8List _convertToWav(Float32List samples, int sampleRate) {
    // Convert Float32 PCM to Int16 PCM
    final int16Samples = Int16List(samples.length);
    for (var i = 0; i < samples.length; i++) {
      int16Samples[i] = (samples[i] * 32767).clamp(-32768, 32767).toInt();
    }

    final dataSize = int16Samples.length * 2;
    final header = ByteData(44);

    // RIFF header
    header.setUint32(0, 0x52494646, Endian.big); // "RIFF"
    header.setUint32(4, 36 + dataSize, Endian.little);
    header.setUint32(8, 0x57415645, Endian.big); // "WAVE"

    // fmt chunk
    header.setUint32(12, 0x666d7420, Endian.big); // "fmt "
    header.setUint32(16, 16, Endian.little); // chunk size
    header.setUint16(20, 1, Endian.little); // PCM format
    header.setUint16(22, 1, Endian.little); // mono
    header.setUint32(24, sampleRate, Endian.little);
    header.setUint32(28, sampleRate * 2, Endian.little); // byte rate
    header.setUint16(32, 2, Endian.little); // block align
    header.setUint16(34, 16, Endian.little); // bits per sample

    // data chunk
    header.setUint32(36, 0x64617461, Endian.big); // "data"
    header.setUint32(40, dataSize, Endian.little);

    final wavBytes = Uint8List(44 + dataSize);
    wavBytes.setAll(0, header.buffer.asUint8List());
    wavBytes.setAll(44, int16Samples.buffer.asUint8List());

    return wavBytes;
  }

  /// Health wellness affirmation
  Future<void> speakWellnessMessage(String message, {double rate = 1.0}) {
    return speakText(
      message,
      rate: rate,
      pitch: 1.0,
      volume: 1.0,
    );
  }

  /// Clean up resources
  void dispose() {
    _player.dispose();
  }
}

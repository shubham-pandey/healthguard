import 'package:flutter/material.dart';
import 'package:healthguard/services/stt_feature.dart';
import 'package:healthguard/services/tts_feature.dart';
import 'package:healthguard/vad_feature.dart';
import 'package:healthguard/services/runanywhere_service.dart';

class VoiceInteractionScreen extends StatefulWidget {
  const VoiceInteractionScreen({super.key});

  @override
  State<VoiceInteractionScreen> createState() => _VoiceInteractionScreenState();
}

class _VoiceInteractionScreenState extends State<VoiceInteractionScreen> {
  final RunAnywhereService _service = RunAnywhereService();
  final STTFeature _stt = STTFeature();
  final TTSFeature _tts = TTSFeature();
  final VADFeature _vad = VADFeature();

  bool _isRecording = false;
  String _transcription = '';
  double _audioLevel = 0.0;
  bool _isSpeaking = false;
  String _status = 'Ready';

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      if (!_service.isInitialized) {
        await _service.initialize();
        await _service.setupSTT();
        await _service.setupTTS();
        await _service.setupVAD();
      }

      // Load models
      _downloadAndLoadModel('sherpa-onnx-whisper-tiny.en', 'STT');
      _downloadAndLoadModel('vits-piper-en_US-lessac-medium', 'TTS');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Initialization error: $e')),
        );
      }
    }
  }

  Future<void> _downloadAndLoadModel(String modelId, String modelType) async {
    try {
      final isDownloaded = await _service.isModelDownloaded(modelId);

      if (!isDownloaded) {
        print('Downloading $modelType model...');
        await for (final progress
            in _service.downloadModel(modelId)) {
          print(
              '  ${modelType}: ${(progress.percentage * 100).toStringAsFixed(1)}%');
          if (progress.state.isCompleted) break;
        }
      }

      if (modelType == 'STT') {
        await _service.loadSTTModel();
      } else if (modelType == 'TTS') {
        await _service.loadTTSModel();
      }

      print('✓ $modelType model loaded');
    } catch (e) {
      print('✗ Failed to load $modelType: $e');
    }
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      // Stop recording and transcribe
      setState(() {
        _isRecording = false;
        _status = 'Transcribing...';
      });

      final audioBytes = await _stt.stopRecording();
      if (audioBytes != null) {
        try {
          final text = await _stt.transcribe(audioBytes);
          setState(() {
            _transcription = text;
            _status = 'Ready';
          });

          // Show snackbar with transcription
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Transcribed: $text'),
                duration: const Duration(seconds: 3),
              ),
            );
          }
        } catch (e) {
          setState(() => _status = 'Transcription failed');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: $e')),
            );
          }
        }
      }
    } else {
      // Start recording
      final started = await _stt.startRecording();
      if (started) {
        setState(() {
          _isRecording = true;
          _status = 'Recording... Speak now';
          _transcription = '';
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to start recording. Check permissions.'),
            ),
          );
        }
      }
    }
  }

  Future<void> _speakText() async {
    if (_transcription.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No text to speak. Record something first.')),
      );
      return;
    }

    try {
      setState(() => _status = 'Speaking...');
      await _tts.speakText(_transcription);
      setState(() => _status = 'Ready');
    } catch (e) {
      setState(() => _status = 'Speech failed');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _startVoiceSession() async {
    try {
      setState(() => _status = 'Starting voice session...');
      await _vad.startVoiceSession(
        speechThreshold: 0.03,
        silenceDuration: 1.5,
      );

      // Listen to VAD events
      _vad.voiceEvents.listen((event) {
        if (!mounted) return;

        setState(() {
          switch (event.runtimeType.toString()) {
            case 'VoiceSessionListening':
              _status = 'Listening...';
              break;
            case 'VoiceSessionSpeechStarted':
              _status = 'Speech detected!';
              _isSpeaking = true;
              break;
            case 'VoiceSessionSpeechEnded':
              _status = 'Processing...';
              _isSpeaking = false;
              break;
            case 'VoiceSessionProcessing':
              _status = 'Processing...';
              break;
            case 'VoiceSessionTranscribed':
              _status = 'Transcribed!';
              break;
            case 'VoiceSessionResponded':
              _status = 'AI responded!';
              break;
            case 'VoiceSessionSpeaking':
              _status = 'AI speaking...';
              break;
            case 'VoiceSessionTurnCompleted':
              _status = 'Turn completed';
              break;
            case 'VoiceSessionStopped':
              _status = 'Session stopped';
              break;
            default:
              _status = 'Voice session active';
          }
        });
      });

      setState(() => _status = 'Voice session active. Listening...');
    } catch (e) {
      setState(() => _status = 'Failed to start voice session');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _stopVoiceSession() async {
    try {
      await _vad.stopVoiceSession();
      setState(() => _status = 'Voice session stopped');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _stt.dispose();
    _tts.dispose();
    _vad.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Voice Interaction'),
        backgroundColor: const Color(0xFF00A8A8),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Status indicator
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F8F8),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF00A8A8)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Status',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _status,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF00A8A8),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Audio level indicator
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Audio Level',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: _audioLevel.clamp(0.0, 1.0),
                        minHeight: 20,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation(
                          _isSpeaking ? Colors.green : Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Transcription display
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey[50],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Transcription',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _transcription.isEmpty
                          ? 'No transcription yet...'
                          : _transcription,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Recording button
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.white,
                ),
                child: Column(
                  children: [
                    const Text(
                      'Speech-to-Text (STT)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _toggleRecording,
                      icon: Icon(
                        _isRecording ? Icons.stop : Icons.mic,
                      ),
                      label: Text(_isRecording ? 'Stop Recording' : 'Start Recording'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isRecording
                            ? Colors.red
                            : const Color(0xFF00A8A8),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        minimumSize: const Size(double.infinity, 48),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Speak button
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.white,
                ),
                child: Column(
                  children: [
                    const Text(
                      'Text-to-Speech (TTS)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _tts.isSpeaking ? null : _speakText,
                      icon: Icon(
                        _tts.isSpeaking ? Icons.stop : Icons.volume_up,
                      ),
                      label: Text(
                        _tts.isSpeaking ? 'Stop Speaking' : 'Speak Text',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00A8A8),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        minimumSize: const Size(double.infinity, 48),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Voice session buttons
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.white,
                ),
                child: Column(
                  children: [
                    const Text(
                      'Voice Activity Detection (VAD)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _vad.hasActiveSession
                                ? null
                                : _startVoiceSession,
                            icon: const Icon(Icons.play_arrow),
                            label: const Text('Start'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00A8A8),
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _vad.hasActiveSession
                                ? _stopVoiceSession
                                : null,
                            icon: const Icon(Icons.stop),
                            label: const Text('Stop'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:runanywhere/runanywhere.dart';
import 'package:runanywhere_llamacpp/runanywhere_llamacpp.dart';
import 'package:runanywhere_onnx/runanywhere_onnx.dart';

class RunAnywhereService {
  static final RunAnywhereService _instance = RunAnywhereService._internal();

  factory RunAnywhereService() {
    return _instance;
  }

  RunAnywhereService._internal();

  bool _isInitialized = false;
  bool _llmReady = false;
  bool _sttReady = false;
  bool _ttsReady = false;
  bool _vadReady = false;

  bool get isInitialized => _isInitialized;
  bool get isLLMReady => _llmReady;
  bool get isSTTReady => _sttReady;
  bool get isTTSReady => _ttsReady;
  bool get isVADReady => _vadReady;

  /// Initialize the RunAnywhere SDK
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize the core SDK
      await RunAnywhere.initialize();
      print('✓ RunAnywhere Core SDK initialized');
      _isInitialized = true;
    } catch (e) {
      print('✗ Failed to initialize RunAnywhere: $e');
      rethrow;
    }
  }

  /// Setup LLM backend with SmolLM2 model
  Future<void> setupLLM() async {
    if (!_isInitialized) throw Exception('RunAnywhere not initialized');
    if (_llmReady) return;

    try {
      // Register LlamaCpp backend
      await LlamaCpp.register();
      print('✓ LlamaCpp backend registered');

      // Add SmolLM2 model
      LlamaCpp.addModel(
        id: 'smollm2-360m-q8_0',
        name: 'SmolLM2 360M Q8_0',
        url: 'https://huggingface.co/prithivMLmods/SmolLM2-360M-GGUF/resolve/main/SmolLM2-360M.Q8_0.gguf',
        memoryRequirement: 500000000,
      );
      print('✓ SmolLM2 model registered');

      _llmReady = true;
    } catch (e) {
      print('✗ Failed to setup LLM: $e');
      rethrow;
    }
  }

  /// Setup STT backend with Whisper Tiny model
  Future<void> setupSTT() async {
    if (!_isInitialized) throw Exception('RunAnywhere not initialized');
    if (_sttReady) return;

    try {
      // Register ONNX backend
      await Onnx.register();
      print('✓ ONNX backend registered');

      // Add Whisper Tiny model for STT
      Onnx.addModel(
        id: 'sherpa-onnx-whisper-tiny.en',
        name: 'Whisper Tiny English',
        url: 'https://github.com/RunanywhereAI/sherpa-onnx/releases/download/runanywhere-models-v1/sherpa-onnx-whisper-tiny.en.tar.gz',
        modality: ModelCategory.speechRecognition,
      );
      print('✓ Whisper Tiny model registered');

      _sttReady = true;
    } catch (e) {
      print('✗ Failed to setup STT: $e');
      rethrow;
    }
  }

  /// Setup TTS backend with Piper voice model
  Future<void> setupTTS() async {
    if (!_isInitialized) throw Exception('RunAnywhere not initialized');
    if (_ttsReady) return;

    try {
      // Register ONNX backend if not already done
      try {
        await Onnx.register();
      } catch (_) {
        // Already registered
      }
      print('✓ ONNX backend ready for TTS');

      // Add Piper TTS model
      Onnx.addModel(
        id: 'vits-piper-en_US-lessac-medium',
        name: 'Piper US English (Lessac)',
        url: 'https://github.com/RunanywhereAI/sherpa-onnx/releases/download/runanywhere-models-v1/vits-piper-en_US-lessac-medium.tar.bz2',
        modality: ModelCategory.speechSynthesis,
      );
      print('✓ Piper TTS model registered');

      _ttsReady = true;
    } catch (e) {
      print('✗ Failed to setup TTS: $e');
      rethrow;
    }
  }

  /// Setup VAD (Voice Activity Detection) - uses ONNX
  Future<void> setupVAD() async {
    if (!_isInitialized) throw Exception('RunAnywhere not initialized');
    if (_vadReady) return;

    try {
      // Register ONNX backend if not already done
      try {
        await Onnx.register();
      } catch (_) {
        // Already registered
      }
      print('✓ ONNX backend ready for VAD');

      _vadReady = true;
    } catch (e) {
      print('✗ Failed to setup VAD: $e');
      rethrow;
    }
  }

  /// Download a model with progress tracking
  Stream<DownloadProgress> downloadModel(String modelId) {
    return RunAnywhere.downloadModel(modelId);
  }

  /// Load a model into memory
  Future<void> loadModel(String modelId) async {
    return RunAnywhere.loadModel(modelId);
  }

  /// Load LLM model
  Future<void> loadLLMModel() async {
    if (!_llmReady) await setupLLM();
    return RunAnywhere.loadModel('smollm2-360m-q8_0');
  }

  /// Load STT model
  Future<void> loadSTTModel() async {
    if (!_sttReady) await setupSTT();
    return RunAnywhere.loadSTTModel('sherpa-onnx-whisper-tiny.en');
  }

  /// Load TTS model
  Future<void> loadTTSModel() async {
    if (!_ttsReady) await setupTTS();
    return RunAnywhere.loadTTSVoice('vits-piper-en_US-lessac-medium');
  }

  /// Get list of available models
  Future<List<dynamic>> getAvailableModels() async {
    return RunAnywhere.availableModels();
  }

  /// Check if a model is downloaded
  Future<bool> isModelDownloaded(String modelId) async {
    final models = await getAvailableModels();
    final model = models.firstWhere(
      (m) => m?.id == modelId,
      orElse: () => throw Exception('Model not found: $modelId'),
    );
    return model?.isDownloaded ?? false;
  }
}

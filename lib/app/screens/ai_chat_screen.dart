import 'package:flutter/material.dart';
import 'package:healthguard/services/llm_feature.dart';
import 'package:healthguard/services/runanywhere_service.dart';
import 'package:runanywhere/runanywhere.dart';

class AIChartScreen extends StatefulWidget {
  const AIChartScreen({super.key});

  @override
  State<AIChartScreen> createState() => _AIChartScreenState();
}

class _AIChartScreenState extends State<AIChartScreen> {
  final RunAnywhereService _service = RunAnywhereService();
  final LLMFeature _llm = LLMFeature();
  final TextEditingController _promptController = TextEditingController();

  String _response = '';
  bool _isLoading = false;
  bool _isModelLoaded = false;
  double _downloadProgress = 0;
  LLMStreamingResult? _currentStream;

  @override
  void initState() {
    super.initState();
    _initializeAndLoadModel();
  }

  Future<void> _initializeAndLoadModel() async {
    try {
      // Initialize SDK if needed
      if (!_service.isInitialized) {
        await _service.initialize();
        await _service.setupLLM();
      }

      // Check if model is already downloaded
      final isDownloaded =
          await _service.isModelDownloaded('smollm2-360m-q8_0');

      if (!isDownloaded) {
        // Download model with progress
        setState(() => _isLoading = true);
        await for (final progress in _service.downloadModel('smollm2-360m-q8_0')) {
          setState(() => _downloadProgress = progress.percentage);
          if (progress.state.isCompleted) break;
        }
      }

      // Load model
      await _service.loadLLMModel();
      setState(() => _isModelLoaded = true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _generateResponse() async {
    if (_promptController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a prompt')),
      );
      return;
    }

    setState(() {
      _response = '';
      _isLoading = true;
    });

    try {
      final streamResult = await _llm.generateStream(
        _promptController.text,
        maxTokens: 300,
      );

      _currentStream = streamResult;

      // Stream tokens in real-time
      await for (final token in streamResult.stream) {
        setState(() => _response += token);
      }

      // Get final metrics
      final metrics = await streamResult.result;
      setState(() {
        _response += '\n\n--- Metrics ---\n'
            'Tokens: ${metrics.tokensUsed}\n'
            'Speed: ${metrics.tokensPerSecond.toStringAsFixed(1)} tok/s\n'
            'Latency: ${metrics.latencyMs.toStringAsFixed(0)}ms';
      });
    } catch (e) {
      setState(() => _response = 'Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Generation error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _cancelGeneration() {
    _currentStream?.cancel();
    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Chat'),
        backgroundColor: const Color(0xFF00A8A8),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Model status
          Container(
            color: const Color(0xFFE8F8F8),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Model Status',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (_isLoading && !_isModelLoaded)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Downloading... ${(_downloadProgress * 100).toStringAsFixed(1)}%',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: _downloadProgress,
                                minHeight: 6,
                                backgroundColor: Colors.grey[300],
                                valueColor: const AlwaysStoppedAnimation(
                                  Color(0xFF00A8A8),
                                ),
                              ),
                            ),
                          ],
                        )
                      else
                        Text(
                          _isModelLoaded ? '✓ Ready' : '✗ Not ready',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _isModelLoaded ? Colors.green : Colors.red,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Response display
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey[50],
              ),
              child: SingleChildScrollView(
                child: Text(
                  _response.isEmpty ? 'Response will appear here...' : _response,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ),
          ),
          // Input area
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _promptController,
                  decoration: InputDecoration(
                    hintText: 'Ask me anything...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  maxLines: 2,
                  enabled: _isModelLoaded && !_isLoading,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isModelLoaded && !_isLoading
                            ? _generateResponse
                            : null,
                        icon: Icon(_isLoading ? Icons.stop : Icons.send),
                        label: Text(_isLoading ? 'Cancel' : 'Send'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00A8A8),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    if (_isLoading)
                      Padding(
                        padding: const EdgeInsets.only(left: 12),
                        child: SizedBox(
                          height: 48,
                          width: 48,
                          child: GestureDetector(
                            onTap: _cancelGeneration,
                            child: const Tooltip(
                              message: 'Cancel generation',
                              child: Icon(
                                Icons.stop_circle,
                                color: Color(0xFF00A8A8),
                                size: 32,
                              ),
                            ),
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
    );
  }
}

import 'package:runanywhere/runanywhere.dart';

class LLMFeature {

  /// Simple chat response
  Future<String> chat(String prompt) async {
    try {
      if (!RunAnywhere.isModelLoaded) {
        throw Exception('LLM model not loaded');
      }
      return await RunAnywhere.chat(prompt);
    } catch (e) {
      print('✗ Chat error: $e');
      rethrow;
    }
  }

  /// Generate text with detailed metrics
  Future<LLMGenerationResult> generate(
    String prompt, {
    int maxTokens = 256,
    double temperature = 0.7,
    double topP = 0.95,
    List<String> stopSequences = const [],
    String? systemPrompt,
  }) async {
    try {
      if (!RunAnywhere.isModelLoaded) {
        throw Exception('LLM model not loaded');
      }

      final result = await RunAnywhere.generate(
        prompt,
        options: LLMGenerationOptions(
          maxTokens: maxTokens,
          temperature: temperature,
          topP: topP,
          stopSequences: stopSequences,
          systemPrompt: systemPrompt,
        ),
      );

      return result;
    } catch (e) {
      print('✗ Generate error: $e');
      rethrow;
    }
  }

  /// Stream tokens in real-time for responsive UI
  Future<LLMStreamingResult> generateStream(
    String prompt, {
    int maxTokens = 256,
    double temperature = 0.7,
    double topP = 0.95,
    List<String> stopSequences = const [],
    String? systemPrompt,
  }) async {
    try {
      if (!RunAnywhere.isModelLoaded) {
        throw Exception('LLM model not loaded');
      }

      return await RunAnywhere.generateStream(
        prompt,
        options: LLMGenerationOptions(
          maxTokens: maxTokens,
          temperature: temperature,
          topP: topP,
          stopSequences: stopSequences,
          systemPrompt: systemPrompt,
        ),
      );
    } catch (e) {
      print('✗ Stream error: $e');
      rethrow;
    }
  }

  /// Cancel ongoing generation
  Future<void> cancelGeneration() async {
    return RunAnywhere.cancelGeneration();
  }

  /// Health assistant system prompt
  static const String healthAssistantPrompt = '''You are a helpful health and wellness assistant. 
You provide general health information and wellness tips. 
Always remind users to consult with healthcare professionals for medical advice.
Keep responses concise and friendly.''';

  /// Chat with health context
  Future<String> askHealthQuestion(String question) async {
    return generate(
      question,
      systemPrompt: healthAssistantPrompt,
      maxTokens: 200,
    ).then((result) => result.text);
  }

  /// Stream health assistant response
  Future<LLMStreamingResult> streamHealthResponse(String question) async {
    return generateStream(
      question,
      systemPrompt: healthAssistantPrompt,
      maxTokens: 200,
    );
  }
}

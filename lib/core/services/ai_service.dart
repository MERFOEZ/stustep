import 'package:dio/dio.dart';

enum AIModel { deepseek, gemini, claude, gpt }

class AIService {
  final Dio _dio = Dio();

  // USER: Add your API keys here
  static const String _deepSeekApiKey =
      'YOUR_DEEPSEEK_API_KEY'; // Direct DeepSeek
  static const String _groqApiKey = 'YOUR_GROQ_API_KEY'; // For Distill models
  static const String _openRouterApiKey =
      'YOUR_OPEN_ROUTER_API_KEY'; // For others

  Future<String> getChatResponse(
    String message,
    AIModel model, {
    String? base64Image,
  }) async {
    try {
      // IF NO API KEYS - Provide a simulated smart response for the demo
      if ((_groqApiKey == 'YOUR_GROQ_API_KEY' ||
              _openRouterApiKey == 'YOUR_OPEN_ROUTER_API_KEY') &&
          _deepSeekApiKey == 'YOUR_DEEPSEEK_API_KEY') {
        return _getSimulatedResponse(
          message,
          model,
          hasImage: base64Image != null,
        );
      }

      switch (model) {
        case AIModel.deepseek:
          if (_deepSeekApiKey != 'YOUR_DEEPSEEK_API_KEY') {
            return await _callDeepSeek(message, base64Image: base64Image);
          }
          // Fallback to OpenRouter or Groq if direct key is missing
          return await _callOpenRouter(
            message,
            'deepseek/deepseek-r1',
            base64Image: base64Image,
          );
        case AIModel.gemini:
          return await _callOpenRouter(
            message,
            'google/gemini-pro-1.5',
            base64Image: base64Image,
          );
        case AIModel.claude:
          return await _callOpenRouter(
            message,
            'anthropic/claude-3.5-sonnet',
            base64Image: base64Image,
          );
        case AIModel.gpt:
          return await _callOpenRouter(
            message,
            'openai/gpt-4o-mini',
            base64Image: base64Image,
          );
      }
    } catch (e) {
      return 'Error: Could not connect to AI service. Please check your internet or API keys.';
    }
  }

  Future<String> _callOpenRouter(
    String message,
    String modelId, {
    String? base64Image,
  }) async {
    final List<Map<String, dynamic>> messages = [];

    if (base64Image != null) {
      messages.add({
        'role': 'user',
        'content': [
          {'type': 'text', 'text': message},
          {
            'type': 'image_url',
            'image_url': {'url': 'data:image/jpeg;base64,$base64Image'},
          },
        ],
      });
    } else {
      messages.add({'role': 'user', 'content': message});
    }

    final response = await _dio.post(
      'https://openrouter.ai/api/v1/chat/completions',
      options: Options(
        headers: {
          'Authorization': 'Bearer $_openRouterApiKey',
          'HTTP-Referer': 'https://stustep.app',
          'X-Title': 'StuStep App',
        },
      ),
      data: {'model': modelId, 'messages': messages},
    );
    return response.data['choices'][0]['message']['content'];
  }

  Future<String> _callDeepSeek(String message, {String? base64Image}) async {
    final List<Map<String, dynamic>> messages = [];

    // DeepSeek official API currently doesn't support image input directly in the same way as GPT-4o
    // But we'll structure it for text first, handling images if they add support or via link
    if (base64Image != null) {
      // For now, we might check documentation, but assuming text-only for 'deepseek-reasoner' (R1) basics
      messages.add({'role': 'user', 'content': message});
    } else {
      messages.add({'role': 'user', 'content': message});
    }

    final response = await _dio.post(
      'https://api.deepseek.com/chat/completions',
      options: Options(
        headers: {
          'Authorization': 'Bearer $_deepSeekApiKey',
          'Content-Type': 'application/json',
        },
      ),
      data: {
        'model': 'deepseek-reasoner', // DeepSeek R1
        'messages': messages,
        'stream': false,
      },
    );
    return response.data['choices'][0]['message']['content'];
  }

  String _getSimulatedResponse(
    String message,
    AIModel model, {
    bool hasImage = false,
  }) {
    final modelName = model.name.toUpperCase();
    final imageStatus = hasImage ? " (with image attached)" : "";
    return '[Simulated $modelName Response$imageStatus]\n\nThis is a placeholder response because no API keys were found in ai_service.dart. \n\nYour message was: "$message"';
  }
}

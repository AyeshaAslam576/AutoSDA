import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class AiService {
  /// 🔐 HuggingFace API key (DeepSeek model)
  static const String openRouterApiKey ="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";
      static Future<String> sendToOpenAI(String prompt) async {
    const endpoint = 'https://openrouter.ai/api/v1/chat/completions';

    try {
      final response = await http.post(
        Uri.parse(endpoint),
        headers: {
          'Authorization': 'Bearer $openRouterApiKey',
          'Content-Type': 'application/json',
          'HTTP-Referer': 'https://spec2uml.app',
          'X-Title': 'Spec2UML Chat'
        },
        body: jsonEncode({
          'model': 'openai/gpt-4o',
          'max_tokens': 1500, // ✅ FREE LIMIT!
          'messages': [
            {
              'role': 'user',
              'content':
              "You are an expert in software design and architecture. Generate a UML  diagrams codes in PlantUML format for the following requirement:\n\n$prompt"
            }
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'].toString().trim();
      } else {
        final error = jsonDecode(response.body);
        final msg = error['error']?['message'] ?? 'Unknown error';
        throw Exception("OpenRouter Error: $msg");
      }
    } catch (e) {
      throw Exception("Failed to connect to OpenRouter: $e");
    }
  }

}

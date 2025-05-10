import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class ChatService {
  // Bật chế độ test = true → chỉ trả lời giả lập, không gọi GPT thật
  static const bool isTesting = true;

  // Gửi tin nhắn dạng văn bản
  static Future<String?> sendMessageToGPT({
    required String userMessage,
    required String gender,
    required String height,
    required String weight,
  }) async {
    if (isTesting) {
      await Future.delayed(const Duration(seconds: 1)); // giả lập thời gian phản hồi
      return "💬 Trả lời giả lập: Bạn nói '$userMessage'. Đây là phản hồi test từ chatbot.";
    }

    final apiKey = dotenv.env['OPENAI_API_KEY'] ?? '';
    if (apiKey.isEmpty) {
      print('❌ Thiếu OPENAI_API_KEY trong .env');
      return null;
    }

    final url = Uri.parse('https://api.openai.com/v1/chat/completions');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $apiKey',
    };

    final body = jsonEncode({
      'model': 'gpt-4o',
      'messages': [
        {
          'role': 'system',
          'content': 'Bạn là một huấn luyện viên thể hình. Người dùng hiện tại có giới tính là $gender, chiều cao $height cm, cân nặng $weight kg. '
              'Chỉ trả lời các câu hỏi liên quan đến sức khỏe, thể hình, chế độ tập luyện, ăn uống. Nếu câu hỏi không liên quan, hãy từ chối trả lời một cách lịch sự.'
        },
        {'role': 'user', 'content': userMessage}
      ],
    });

    try {
      final response = await http.post(url, headers: headers, body: body);
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return json['choices'][0]['message']['content'];
      } else {
        print('❌ Lỗi GPT API: ${response.body}');
        return null;
      }
    } catch (e) {
      print('❌ Exception GPT: $e');
      return null;
    }
  }

  // Gửi tin nhắn dạng ảnh
  static Future<String?> sendImageMessageToGPT({
    required String imageUrl,
    required String gender,
    required String height,
    required String weight,
  }) async {
    if (isTesting) {
      await Future.delayed(const Duration(seconds: 1)); // giả lập thời gian phản hồi
      return "💬 Trả lời giả lập: Bạn đã gửi ảnh có URL là '$imageUrl'. Đây là phản hồi test từ chatbot.";
    }

    final apiKey = dotenv.env['OPENAI_API_KEY'] ?? '';
    if (apiKey.isEmpty) {
      print('❌ Thiếu OPENAI_API_KEY trong .env');
      return null;
    }

    final url = Uri.parse('https://api.openai.com/v1/chat/completions');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $apiKey',
    };

    final body = jsonEncode({
      'model': 'gpt-4o',
      'messages': [
        {
          'role': 'system',
          'content': 'Bạn là một huấn luyện viên thể hình. Người dùng hiện tại có giới tính là $gender, chiều cao $height cm, cân nặng $weight kg. '
              'Người dùng vừa gửi một hình ảnh tại URL: $imageUrl. Chỉ trả lời các câu hỏi liên quan đến sức khỏe, thể hình, chế độ tập luyện, ăn uống.'
        },
      ],
    });

    try {
      final response = await http.post(url, headers: headers, body: body);
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return json['choices'][0]['message']['content'];
      } else {
        print('❌ Lỗi GPT API: ${response.body}');
        return null;
      }
    } catch (e) {
      print('❌ Exception GPT: $e');
      return null;
    }
  }
}

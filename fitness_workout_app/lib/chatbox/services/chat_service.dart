import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:fitness_workout_app/chatbox/models/message.dart';// đảm bảo import file định nghĩa Message

class ChatService {
  static bool isTesting = true;

  static Future<String?> sendMessageToGPT({
    required String userMessage,
    String? imageUrl,
    required String gender,
    required String height,
    required String weight,
    required List<Message> historyMessages,
  }) async {
    print("📌 User info — Gender: $gender, Height: $height, Weight: $weight");

    if (isTesting) {
      await Future.delayed(const Duration(seconds: 1));
      return imageUrl != null
          ? "💬 Trả lời giả lập: Bạn nói '$userMessage' kèm ảnh URL '$imageUrl'. Đây là phản hồi test từ chatbot."
          : "💬 Trả lời giả lập: Bạn nói '$userMessage'. Đây là phản hồi test từ chatbot.";
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

    // ⚡ Chuyển history từ Message sang format OpenAI
    final List<Map<String, dynamic>> chatHistory = [
      {
        'role': 'system',
        'content':
        'Bạn là một huấn luyện viên thể hình. Người dùng hiện tại có giới tính là $gender, chiều cao $height cm, cân nặng $weight kg. '
            'Dựa trên nội dung và hình ảnh nếu có, hãy đưa ra tư vấn về thể trạng, chế độ tập luyện, ăn uống. Nếu không phù hợp, hãy từ chối lịch sự. '
            'Câu trả lời cần ngắn gọn, chỉ từ 3 đến 5 dòng để tiết kiệm chi phí.'
      },
      ...historyMessages.map((msg) => {
        'role': msg.isUser ? 'user' : 'assistant',
        'content': msg.text,
      }),
    ];

    // 👉 Gộp userMessage và image (nếu có) thành 1 message cuối
    final userContent = [];

    if (userMessage.trim().isNotEmpty) {
      userContent.add({'type': 'text', 'text': userMessage});
    }

    if (imageUrl != null && imageUrl.trim().isNotEmpty) {
      userContent.add({
        'type': 'image_url',
        'image_url': {'url': imageUrl}
      });
    }

    // Thêm message cuối cùng vào danh sách chat
    chatHistory.add({
      'role': 'user',
      'content': userContent,
    });

    final body = jsonEncode({
      'model': 'gpt-4o-mini',
      'max_tokens': 1000,
      'messages': chatHistory,
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

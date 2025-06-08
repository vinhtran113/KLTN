import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:fitness_workout_app/chatbox/models/message.dart';

class ChatService {
  static bool isTesting = false;

  static Future<String?> sendMessageToGPT({
    required String userMessage,
    String? imageUrl,
    required String gender,
    required String height,
    required String weight,
    required String bodyFat,
    required List<String> medicalHistory,
    required List<String> medicalHistoryOther,
    required String medicalNote,
    required List<Message> historyMessages,
  }) async {
    print(
        "📌 User info — Gender: $gender, Height: $height, Weight: $weight, BodyFat: $bodyFat");

    if (isTesting) {
      await Future.delayed(const Duration(seconds: 1));
      return imageUrl != null
          ? "💬 Trả lời giả lập: Bạn nói '$userMessage' kèm ảnh URL '$imageUrl'. Đây là phản hồi test từ chatbot."
          : "💬 Trả lời giả lập: Bạn nói '$userMessage'. Đây là phản hồi test từ chatbot.";
    }

    final apiKey = dotenv.env['OPENROUTER_API_KEY'] ?? '';
    if (apiKey.isEmpty) {
      print('❌ Thiếu OPENROUTER_API_KEY trong .env');
      return null;
    }

    final url = Uri.parse('https://openrouter.ai/api/v1/chat/completions');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $apiKey',
      'HTTP-Referer': 'https://your-app-url.com', // tuỳ chỉnh nếu cần
      'X-Title': 'FitnessWorkoutApp', // tuỳ chỉnh nếu cần
    };

    final List<Map<String, dynamic>> chatHistory = [
      {
        'role': 'system',
        'content': '''
Bạn là một bác sĩ chuyên khoa sức khoẻ, dinh dưỡng và thể hình. 
Thông tin bệnh nhân: 
- Giới tính: $gender
- Chiều cao: $height cm
- Cân nặng: $weight kg
- Tỉ lệ mỡ cơ thể: $bodyFat%
- Tiền sử bệnh: ${medicalHistory.join(", ")}
- Tiền sử bệnh khác: ${medicalHistoryOther.join(", ")}
- Ghi chú sức khoẻ: $medicalNote

Yêu cầu:
- Phân tích tình trạng sức khoẻ, thể trạng, nguy cơ bệnh lý, chế độ tập luyện và dinh dưỡng dựa trên thông tin trên và nội dung người dùng gửi (bao gồm cả hình ảnh nếu có).
- Phản hồi phải chi tiết, khoa học, có thể trích dẫn các nghiên cứu hoặc khuyến nghị y khoa nếu phù hợp.
- Đưa ra nhận định tổng quan, các vấn đề nổi bật, nguy cơ tiềm ẩn (nếu có), lời khuyên cụ thể về tập luyện, dinh dưỡng, phòng ngừa bệnh.
- Văn phong chuyên nghiệp, súc tích, dễ hiểu, giúp bác sĩ nắm nhanh tình trạng bệnh nhân.
- Nếu thông tin chưa đủ để kết luận, hãy liệt kê rõ những gì còn thiếu và đề xuất bổ sung.
- Trả lời tối đa 7 câu, tránh lan man, tập trung vào các điểm chính.
'''
      },
      ...historyMessages.map((msg) => {
            'role': msg.isUser ? 'user' : 'assistant',
            'content': msg.text,
          }),
    ];

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

    chatHistory.add({
      'role': 'user',
      'content': userContent,
    });

    final body = jsonEncode({
      'model': 'openai/gpt-4o-mini',
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

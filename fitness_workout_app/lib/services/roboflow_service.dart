import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class RoboflowService {
  static const String _apiKey = "";
  static const String _modelId = "";
  static const String _baseUrl = "";

  /// Trả về danh sách tên món ăn nhận diện được từ ảnh
  static Future<List<String>> detectFoodItems(File imageFile) async {
    final url = Uri.parse("$_baseUrl/$_modelId?api_key=$_apiKey");

    final request = http.MultipartRequest('POST', url);
    request.files
        .add(await http.MultipartFile.fromPath('file', imageFile.path));

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      final data = jsonDecode(responseBody);
      final predictions = data['predictions'] as List;

      ///for (var item in predictions) {
      //  print("${item['class']} - Confidence: ${item['confidence']}");
      //}

      //Thiết lập ngưỡng độ tin cậy (ví dụ: >= 0.75)
      const confidenceThreshold = 0.75;

      final filtered = predictions.where(
        (item) => (item['confidence'] ?? 0.0) >= confidenceThreshold,
      );

      final foodNames = filtered
          .map<String>((item) => item['class'].toString())
          .toSet()
          .toList();

      //print("Các món ăn (lọc theo confidence ≥ $confidenceThreshold): $foodNames");

      return foodNames;
    } else {
      print("Lỗi Roboflow: ${response.statusCode} - $responseBody");
      return [];
    }
  }
}

class Nutrition {
  final Map<String, double> values;

  Nutrition({required this.values});

  factory Nutrition.fromMap(Map<String, dynamic> map) {
    return Nutrition(
      values: map.map((key, value) => MapEntry(key, ((value as num?)?.toDouble() ?? 0.0))),
    );
  }

  factory Nutrition.empty() => Nutrition(
    values: {
      'calories': 0.0,
      'protein': 0.0,
      'fat': 0.0,
      'carb': 0.0,
    },
  );

  Map<String, dynamic> toMap() {
    return values;
  }

  double getCalories() {
    return values['calories'] ?? 0.0;
  }

  String getImage(String key) {
    switch (key.toLowerCase()) {
      case 'calories':
        return 'assets/img/burn.png';
      case 'fat':
        return 'assets/img/egg.png';
      case 'protein':
        return 'assets/img/proteins.png';
      case 'carb':
        return 'assets/img/carbo.png';
      default:
        return 'assets/img/no_image.png';
    }
  }

  /// Trả ra list dùng để hiển thị
  List<Map<String, String>> toDisplayList() {
    return values.entries.map((entry) {
      final key = entry.key;
      final value = entry.value;
      final displayTitle = '$value ${_getUnit(key)}';
      return {
        'title': displayTitle,
        'image': getImage(key),
      };
    }).toList();
  }

  String _getUnit(String key) {
    switch (key.toLowerCase()) {
      case 'calories':
        return 'kCal';
      case 'fat':
      case 'protein':
      case 'carb':
        return 'g';
      default:
        return '';
    }
  }
}
class ProgressPhoto {
  final String imageUrl;
  final DateTime date;
  final String weight;
  final String height;
  final String bodyFat;

  ProgressPhoto({
    required this.imageUrl,
    required this.date,
    required this.weight,
    required this.height,
    required this.bodyFat,
  });

  Map<String, dynamic> toJson() => {
    'imageUrl': imageUrl,
    'date': date.toIso8601String(),
    'weight': weight,
    'height': height,
    'bodyFat': bodyFat,
  };
}

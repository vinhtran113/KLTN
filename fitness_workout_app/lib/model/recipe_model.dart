class Recipe {
  final String detail;

  Recipe({
    required this.detail,
  });

  factory Recipe.fromJson(Map<String, dynamic> data) {
    return Recipe(
      detail: data['detail'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'detail': detail,
    };
  }
}
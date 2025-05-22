import 'nutrition_model.dart';

class Ingredient {
  final String name;
  final String unit;
  final String image;
  final Nutrition nutri; // dùng Nutrition
  double amount;

  Ingredient({
    required this.name,
    required this.unit,
    required this.image,
    required this.nutri,
    required this.amount,
  });

  factory Ingredient.fromMap(Map<String, dynamic> map) {
    return Ingredient(
      name: map['name'] ?? '',
      unit: map['unit'] ?? '',
      image: map['image'] ?? '',
      nutri: Nutrition.fromMap(map['nutri'] ?? {}),
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'unit': unit,
      'image': image,
      'nutri': nutri.toMap(),
      'amount': amount,
    };
  }
}

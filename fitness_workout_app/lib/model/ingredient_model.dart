class Ingredient {
  final String name;
  double amount;
  final String unit;
  final String image;
  final double caloriesPerUnit;

  Ingredient({
    required this.name,
    required this.amount,
    required this.unit,
    required this.image,
    required this.caloriesPerUnit,
  });

  factory Ingredient.fromMap(Map<String, dynamic> map) {
    return Ingredient(
      name: map['name'] ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      unit: map['unit'] ?? '',
      image: map['image'] ?? ' ',
      caloriesPerUnit: (map['caloriesPerUnit'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'amount': amount,
      'unit': unit,
      'image': image,
      'caloriesPerUnit': caloriesPerUnit,
    };
  }

}
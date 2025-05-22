import 'ingredient_model.dart';

class SimpleMeal {
  final String name;
  final String image;
  final double totalCalories;
  final double totalCarb;
  final double totalFat;
  final double totalProtein;
  final String time;
  final bool notify;
  final String id_notify;
  final List<Ingredient> ingredients;

  SimpleMeal({
    required this.name,
    required this.image,
    required this.totalCalories,
    required this.totalCarb,
    required this.totalFat,
    required this.totalProtein,
    required this.time,
    required this.notify,
    required this.id_notify,
    required this.ingredients,
  });

  Map<String, dynamic> toMap() => {
    'name': name,
    'image': image,
    'totalCalories': totalCalories,
    'totalCarb': totalCarb,
    'totalFat': totalFat,
    'totalProtein': totalProtein,
    'time': time,
    'notify': notify,
    'id_notify': id_notify,
    'ingredients': ingredients.map((e) => e.toMap()).toList(),
  };

  factory SimpleMeal.fromMap(Map<String, dynamic> map) => SimpleMeal(
    name: map['name'],
    image: map['image'],
    totalCalories: (map['totalCalories'] as num).toDouble(),
    totalCarb: (map['totalCarb'] as num).toDouble(),
    totalFat: (map['totalFat'] as num).toDouble(),
    totalProtein: (map['totalProtein'] as num).toDouble(),
    time: map['time'],
    notify: map['notify'],
    id_notify: map['id_notify'],
    ingredients: (map['ingredients'] as List<dynamic>)
        .map((e) => Ingredient.fromMap(e))
        .toList(),
  );
}

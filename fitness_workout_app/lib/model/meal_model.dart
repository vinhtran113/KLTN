import 'ingredient_model.dart';
import 'nutrition_model.dart';
import 'recipe_model.dart';

class Meal {
  final String description;
  final String image;
  final List<String> category;
  final List<String> level;
  final Map<int, Recipe> recipe;
  final List<String> recommend;
  final List<Ingredient> ingredients;
  final Nutrition nutri;
  final String size;
  final double time;
  final String name;
  final String id;
  final List<String> healthRisks;

  Meal(
      {required this.description,
      required this.image,
      required this.category,
      required this.level,
      required this.recipe,
      required this.recommend,
      required this.ingredients,
      required this.nutri,
      required this.size,
      required this.time,
      required this.name,
      required this.id,
      required this.healthRisks});

  factory Meal.fromMap(Map<String, dynamic> map) {
    return Meal(
      description: map['description'] ?? '',
      image: map['image'] ?? '',
      category: List<String>.from(map['category'] ?? []),
      level: List<String>.from(map['level'] ?? []),
      recipe: (map['recipe'] as Map<String, dynamic>?)?.map(
            (key, value) {
              return MapEntry(int.parse(key),
                  Recipe.fromJson(Map<String, dynamic>.from(value)));
            },
          ) ??
          {},
      recommend: List<String>.from(map['recommend'] ?? []),
      ingredients: (map['ingredients'] as List<dynamic>?)
              ?.map((e) => Ingredient.fromMap(e))
              .toList() ??
          [],
      nutri: Nutrition.fromMap(map['nutri'] ?? {}),
      name: map['name'] ?? '',
      size: map['size'] ?? '',
      time: (map['time'] as num?)?.toDouble() ?? 0.0,
      id: map['id'] ?? '',
      healthRisks: List<String>.from(map['health_risks'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'description': description,
      'image': image,
      'category': category,
      'level': level,
      'recipe': recipe
          .map((key, value) => MapEntry(key.toString(), value.toFirestore())),
      'recommend': recommend,
      'ingredients': ingredients.map((e) => e.toMap()).toList(),
      'nutri': nutri.toMap(),
      'size': size,
      'time': time,
      'name': name,
      'id': id
    };
  }

  List<Map<String, String>> getIngredientDisplayList() {
    return ingredients.map((ingredient) {
      return {
        "image": ingredient.image,
        "title": ingredient.name,
        "value": "${ingredient.amount.toString()} ${ingredient.unit}",
      };
    }).toList();
  }

  factory Meal.empty() => Meal(
        description: '',
        image: '',
        category: [],
        level: [],
        recipe: {},
        recommend: [],
        ingredients: [],
        nutri: Nutrition.empty(),
        name: '',
        size: '',
        time: 0,
        id: '',
        healthRisks: [],
      );
}

class Ingredient {
  final String name;
  final double amount;
  final String unit;
  final String image;

  Ingredient({
    required this.name,
    required this.amount,
    required this.unit,
    required this.image,
  });

  factory Ingredient.fromMap(Map<String, dynamic> map) {
    return Ingredient(
      name: map['name'] ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      unit: map['unit'] ?? '',
      image: map['image'] ?? ' ',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'amount': amount,
      'unit': unit,
      'image': image,
    };
  }

}

class Nutrition {
  final Map<String, double> values;

  Nutrition({required this.values});

  factory Nutrition.fromMap(Map<String, dynamic> map) {
    return Nutrition(
      values: map.map((key, value) => MapEntry(key, ((value as num?)?.toDouble() ?? 0.0))),
    );
  }

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
      case 'caffeine':
        return 'assets/img/caffeine.png';
      case 'fat':
        return 'assets/img/egg.png';
      case 'protein':
        return 'assets/img/proteins.png';
      case 'carbo':
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
      case 'sugar':
      case 'fat':
      case 'protein':
      case 'carbo':
        return 'g';
      case 'caffeine':
        return 'mg';
      default:
        return '';
    }
  }
}

class RecipeModel {
  final String detail;

  RecipeModel({
    required this.detail,
  });

  factory RecipeModel.fromJson(Map<String, dynamic> data) {
    return RecipeModel(
      detail: data['detail'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'detail': detail,
    };
  }
}

class Meal {
  final String description;
  final String image;
  final List<String> category;
  final List<String> level;
  final Map<int, RecipeModel> recipe;
  final List<String> recommend;
  final List<Ingredient> ingredients;
  final Nutrition nutri;
  final String size;
  final double time;
  final String name;

  Meal({
    required this.description,
    required this.image,
    required this.category,
    required this.level,
    required this.recipe,
    required this.recommend,
    required this.ingredients,
    required this.nutri,
    required this.size,
    required this.time,
    required this.name
  });

  factory Meal.fromMap(Map<String, dynamic> map) {
    return Meal(
      description: map['description'] ?? '',
      image: map['image'] ?? '',
      category: List<String>.from(map['category'] ?? []),
      level: List<String>.from(map['level'] ?? []),
      recipe: (map['recipe'] as Map<String, dynamic>?)?.map(
            (key, value) {
          return MapEntry(int.parse(key), RecipeModel.fromJson(Map<String, dynamic>.from(value)));
        },
      ) ?? {},
      recommend: List<String>.from(map['recommend'] ?? []),
      ingredients: (map['ingredients'] as List<dynamic>?)
          ?.map((e) => Ingredient.fromMap(e))
          .toList() ?? [],
      nutri: Nutrition.fromMap(map['nutri'] ?? {}),
      name: map['name'] ?? '',
      size: map['size'] ?? '',
      time: (map['time'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'description': description,
      'image': image,
      'category': category,
      'level': level,
      'recipe': recipe.map((key, value) => MapEntry(key.toString(), value.toFirestore())),
      'recommend': recommend,
      'ingredients': ingredients.map((e) => e.toMap()).toList(),
      'nutri': nutri.toMap(),
      'size': size,
      'time' : time,
      'name' : name
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
}

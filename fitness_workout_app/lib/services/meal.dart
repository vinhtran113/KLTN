import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/meal_model.dart';
import 'notification.dart';

class MealService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationServices notificationServices = NotificationServices();

  Future<int> countMealsByRecommend(String mealType) async {

    final querySnapshot = await _firestore.collection('Meals')
        .where('recommend', arrayContains: mealType.toLowerCase())
        .get();

    return querySnapshot.docs.length;
  }

  Future<List<Meal>> fetchMealsByRecommendAndLevel({
    required String recommend,
    required String level,
  }) async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('Meals')
        .where('recommend', arrayContains: recommend.toLowerCase())
        .get();

    List<Meal> meals = snapshot.docs
        .map((doc) => Meal.fromMap(doc.data() as Map<String, dynamic>))
        .where((meal) => meal.level.contains(level)) // lọc thêm ở client
        .toList();
    // Tạo danh sách unique tên nguyên liệu
    final allIngredientNames = <String>{};
    for (var meal in meals) {
      for (var ing in meal.ingredients) {
        allIngredientNames.add(ing.name);
      }
    }
    // Lấy thông tin ingredients từ Firestore
    final ingredientsData = <String, Map<String, dynamic>>{};
    for (var name in allIngredientNames) {
      final doc = await FirebaseFirestore.instance
          .collection('Ingredients')
          .doc(name) // assuming doc id is lowercase name
          .get();
      if (doc.exists) {
        ingredientsData[name] = doc.data()!;
      }
    }
    // Gắn unit và image vào từng ingredient
    for (var meal in meals) {
      for (var i = 0; i < meal.ingredients.length; i++) {
        final ing = meal.ingredients[i];
        final extra = ingredientsData[ing.name];
        if (extra != null) {
          meal.ingredients[i] = Ingredient(
            name: ing.name,
            amount: ing.amount,
            unit: extra['unit'] ?? '',
            image: extra['image'] ?? '',
          );
        }
      }
    }
    return meals;
  }

  Future<List<Meal>> fetchMealsWithRecommend({
    required String recommend
  }) async {
  // Lấy danh sách meals trước
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('Meals')
        .where('recommend', arrayContains: recommend.toLowerCase())
        .get();

    List<Meal> meals = snapshot.docs
        .map((doc) => Meal.fromMap(doc.data() as Map<String, dynamic>))
        .toList();
    // Tạo danh sách unique tên nguyên liệu
    final allIngredientNames = <String>{};
    for (var meal in meals) {
      for (var ing in meal.ingredients) {
        allIngredientNames.add(ing.name);
      }
    }
    // Lấy thông tin ingredients từ Firestore
    final ingredientsData = <String, Map<String, dynamic>>{};
    for (var name in allIngredientNames) {
      final doc = await FirebaseFirestore.instance
          .collection('Ingredients')
          .doc(name)
          .get();

      if (doc.exists) {
        ingredientsData[name] = doc.data()!;
      }
    }
    // Gắn unit và image vào từng ingredient
    for (var meal in meals) {
      for (var i = 0; i < meal.ingredients.length; i++) {
        final ing = meal.ingredients[i];
        final extra = ingredientsData[ing.name];
        print("Gán: ${extra}");
        if (extra != null) {
          meal.ingredients[i] = Ingredient(
            name: ing.name,
            amount: ing.amount,
            unit: extra['unit'] ?? '',
            image: extra['image'] ?? '',
          );
        }
      }
    }
    return meals;
  }

  Future<List<Meal>> fetchAllMeals() async {
  // Lấy danh sách meals trước
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('Meals')
        .get();
    List<Meal> meals = snapshot.docs
        .map((doc) => Meal.fromMap(doc.data() as Map<String, dynamic>))
        .toList();
    // Tạo danh sách unique tên nguyên liệu
    final allIngredientNames = <String>{};
    for (var meal in meals) {
      for (var ing in meal.ingredients) {
        allIngredientNames.add(ing.name);
      }
    }
    // Lấy thông tin ingredients từ Firestore
    final ingredientsData = <String, Map<String, dynamic>>{};
    for (var name in allIngredientNames) {
      final doc = await FirebaseFirestore.instance
          .collection('Ingredients')
          .doc(name) // assuming doc id is lowercase name
          .get();

      if (doc.exists) {
        ingredientsData[name] = doc.data()!;
      }
    }
    // Gắn unit và image vào từng ingredient
    for (var meal in meals) {
      for (var i = 0; i < meal.ingredients.length; i++) {
        final ing = meal.ingredients[i];
        final extra = ingredientsData[ing.name];

        if (extra != null) {
          meal.ingredients[i] = Ingredient(
            name: ing.name,
            amount: ing.amount,
            unit: extra['unit'] ?? '',
            image: extra['image'] ?? '',
          );

        }
      }
    }

    return meals;
  }

  Future<List<Meal>> fetchAllMealsByCate({
    required String cate
  }) async {
    // Lấy danh sách meals trước
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('Meals')
        .where('category', arrayContains: cate.toLowerCase())
        .get();

    List<Meal> meals = snapshot.docs
        .map((doc) => Meal.fromMap(doc.data() as Map<String, dynamic>))
        .toList();
    // Tạo danh sách unique tên nguyên liệu
    final allIngredientNames = <String>{};
    for (var meal in meals) {
      for (var ing in meal.ingredients) {
        allIngredientNames.add(ing.name);
      }
    }
    // Lấy thông tin ingredients từ Firestore
    final ingredientsData = <String, Map<String, dynamic>>{};
    for (var name in allIngredientNames) {
      final doc = await FirebaseFirestore.instance
          .collection('Ingredients')
          .doc(name) // assuming doc id is lowercase name
          .get();
      if (doc.exists) {
        ingredientsData[name] = doc.data()!;
      }
    }
    // Gắn unit và image vào từng ingredient
    for (var meal in meals) {
      for (var i = 0; i < meal.ingredients.length; i++) {
        final ing = meal.ingredients[i];
        final extra = ingredientsData[ing.name];
        if (extra != null) {
          meal.ingredients[i] = Ingredient(
            name: ing.name,
            amount: ing.amount,
            unit: extra['unit'] ?? '',
            image: extra['image'] ?? '',
          );
        }
      }
    }
    return meals;
  }

  Future<List<Ingredient>> fetchAvailableIngredients() async {
    final snapshot = await FirebaseFirestore.instance.collection('Ingredients').get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      return Ingredient(
        name: data['name'] ?? '',
        unit: data['unit'] ?? '',
        image: data['image'] ?? '',
        amount: 0,
      );
    }).toList();
  }


}
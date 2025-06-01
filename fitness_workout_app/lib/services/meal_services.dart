import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../model/ingredient_model.dart';
import '../model/meal_model.dart';
import '../model/nutrition_model.dart';
import '../model/simple_meal_model.dart';
import 'notification_services.dart';

class MealService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationServices notificationServices = NotificationServices();

  Future<int> countMealsByRecommend(String mealType) async {
    final querySnapshot = await _firestore
        .collection('Meals')
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
            nutri: Nutrition.fromMap(extra['nutri'] ?? {}),
          );
        }
      }
    }
    return meals;
  }

  Future<List<Meal>> fetchMealsWithRecommend(
      {required String recommend}) async {
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
        if (extra != null) {
          meal.ingredients[i] = Ingredient(
            name: ing.name,
            amount: ing.amount,
            unit: extra['unit'] ?? '',
            image: extra['image'] ?? '',
            nutri: Nutrition.fromMap(extra['nutri'] ?? {}),
          );
        }
      }
    }
    return meals;
  }

  Future<List<Meal>> fetchAllMeals() async {
    // Lấy danh sách meals trước
    QuerySnapshot snapshot =
        await FirebaseFirestore.instance.collection('Meals').get();
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
            nutri: Nutrition.fromMap(extra['nutri'] ?? {}),
          );
        }
      }
    }

    return meals;
  }

  Future<List<Meal>> fetchAllMealsByCate({required String cate}) async {
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
            nutri: Nutrition.fromMap(extra['nutri'] ?? {}),
          );
        }
      }
    }
    return meals;
  }

  Future<List<Ingredient>> fetchAvailableIngredients() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('Ingredients').get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      return Ingredient(
        name: data['name'] ?? '',
        unit: data['unit'] ?? '',
        image: data['image'] ?? '',
        amount: 0,
        nutri: Nutrition.fromMap(data['nutri'] ?? {}),
      );
    }).toList();
  }

  Future<String> checkMealSchedule({
    required DateTime date,
    required String mealType,
    required String hour,
  }) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final time = _parseTime(hour);

    if (!_isValidTimeForMealType(mealType, time)) {
      return "Thời gian không hợp lệ với bữa $mealType";
    }

    if (date.isBefore(today)) {
      return "fail";
    }

    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      final time = _parseTime(hour);
      final fullMealDateTime =
          DateTime(date.year, date.month, date.day, time.hour, time.minute);
      if (fullMealDateTime.isBefore(now)) {
        return "fail";
      }
    }

    return 'pass';
  }

  Future<String?> addMealSchedule({
    required String uid,
    required DateTime date,
    required String mealType, // breakfast, lunch, dinner, snack
    required List<SimpleMeal> meals,
  }) async {
    final docRef = FirebaseFirestore.instance
        .collection('MealSchedules')
        .doc('${uid}_${DateFormat('yyyy-MM-dd').format(date)}');

    final snapshot = await docRef.get();
    Map<String, dynamic> existingData = {};
    if (snapshot.exists) {
      existingData = snapshot.data()!;
      if (existingData.containsKey(mealType)) {
        final List oldMeals = existingData[mealType];
        for (var newMeal in meals) {
          if (oldMeals.any((m) => m['name'] == newMeal.name)) {
            return "Món '${newMeal.name}' đã có trong $mealType";
          }
        }
      }
    }

    final updatedMeals =
        (existingData[mealType] ?? []) + meals.map((m) => m.toMap()).toList();

    await docRef.set({
      'uid': uid,
      'date': DateFormat('yyyy-MM-dd').format(date),
      mealType: updatedMeals,
    }, SetOptions(merge: true));

    return null; // null nghĩa là thành công
  }

  Future<String?> updateMealSchedule({
    required String uid,
    required DateTime date,
    required String mealType, // breakfast, lunch, dinner, snack
    required SimpleMeal meal,
  }) async {
    final docRef = FirebaseFirestore.instance
        .collection('MealSchedules')
        .doc('${uid}_${DateFormat('yyyy-MM-dd').format(date)}');

    final snapshot = await docRef.get();

    if (!snapshot.exists) {
      return "Không tìm thấy lịch ăn cho ngày này.";
    }

    final data = snapshot.data()!;

    List<dynamic> meals = data[mealType];

    // Tìm index món ăn theo tên
    int index = meals.indexWhere((m) => m['name'] == meal.name);

    if (index == -1) {
      return "Không tìm thấy món '${meal.name}' trong bữa '$mealType'.";
    }

    // Cập nhật lại món đó
    meals[index] = meal.toMap();

    await docRef.set({
      mealType: meals,
    }, SetOptions(merge: true));

    return null; // null = thành công
  }

  Future<String?> deleteMealFromSchedule({
    required String uid,
    required DateTime date,
    required String mealType,
    required String mealName,
    required String id_notify,
  }) async {
    final docRef = FirebaseFirestore.instance
        .collection('MealSchedules')
        .doc('${uid}_${DateFormat('yyyy-MM-dd').format(date)}');

    final doc = await docRef.get();

    if (!doc.exists) {
      return "Không tìm thấy lịch ăn cho ngày này.";
    }

    final data = doc.data()!;

    List<dynamic> meals = data[mealType];

    meals.removeWhere((meal) => meal['name'] == mealName);

    await notificationServices.cancelNotificationById(int.parse(id_notify));

    await docRef.update({mealType: meals});
    return null;
  }

  DateTime _parseTime(String timeStr) {
    try {
      final format = DateFormat('hh:mm a');
      return format.parse(timeStr);
    } catch (e) {
      print("Lỗi parse giờ: $e");
      throw Exception("Giờ không hợp lệ: $timeStr");
    }
  }

  bool _isValidTimeForMealType(String mealType, DateTime time) {
    final hour = time.hour;
    switch (mealType.toLowerCase()) {
      case 'breakfast':
        return hour >= 5 && hour < 9;
      case 'lunch':
        return hour >= 10 && hour < 14;
      case 'dinner':
        return hour >= 16 && hour < 20;
      case 'snacks':
        return true;
      default:
        return false;
    }
  }

  Future<double> getTotalCaloriesInDay({
    required String uid,
    required DateTime date,
  }) async {
    final docId = '${uid}_${DateFormat('yyyy-MM-dd').format(date)}';
    final docRef =
        FirebaseFirestore.instance.collection('MealSchedules').doc(docId);
    final snapshot = await docRef.get();

    if (!snapshot.exists) return 0.0;

    final data = snapshot.data()!;
    double total = 0.0;

    for (var key in ['breakfast', 'lunch', 'dinner', 'snacks']) {
      if (data.containsKey(key)) {
        final List<dynamic> meals = data[key];
        for (var meal in meals) {
          total += (meal['totalCalories'] ?? 0.0);
        }
      }
    }
    return total;
  }

  Future<List<Map<String, dynamic>>> fetchMealScheduleList(String uid) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('MealSchedules')
        .where('uid', isEqualTo: uid)
        .get();

    final List<Map<String, dynamic>> result = [];

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final dateStr = data['date'] as String;
      final date = DateFormat('yyyy-MM-dd').parse(dateStr);

      for (final type in ['breakfast', 'lunch', 'dinner', 'snacks']) {
        if (data.containsKey(type)) {
          final List<dynamic> meals = data[type];
          double totalCalories = 0.0;

          final List<Map<String, dynamic>> mealList = [];

          for (final m in meals) {
            final name = m['name'] ?? '';
            final calories = (m['totalCalories'] ?? 0.0) as num;
            final carb = (m['totalCarb'] ?? 0.0) as num;
            final fat = (m['totalFat'] ?? 0.0) as num;
            final protein = (m['totalProtein'] ?? 0.0) as num;
            totalCalories += calories;

            // Lấy ingredients nếu có
            final ingredients = (m['ingredients'] as List<dynamic>?)
                    ?.map((i) => Map<String, dynamic>.from(i))
                    .toList() ??
                [];

            // 🔹 Truy vấn thêm dữ liệu `nutri` từ bảng Meals
            final mealQuery = await FirebaseFirestore.instance
                .collection('Meals')
                .where('name', isEqualTo: name)
                .limit(1)
                .get();

            Map<String, dynamic> nutri = {};
            if (mealQuery.docs.isNotEmpty) {
              nutri = mealQuery.docs.first.data()['nutri'] ?? {};
            }

            mealList.add({
              'name': name,
              'image': m['image'] ?? '',
              'time': m['time'] ?? '',
              'mealType': type,
              'date': date,
              'totalCalories': calories,
              'totalCarb': carb,
              'totalFat': fat,
              'totalProtein': protein,
              'id_notify': m['id_notify'] ?? '0',
              'notify': m['notify'] ?? true,
              'ingredients': ingredients,
              'nutri': nutri, // Gắn dữ liệu nutrition vào
            });
          }

          result.add({
            'mealType': type,
            'date': date,
            'meals': mealList,
            'totalCalories': totalCalories,
          });
        }
      }
    }
    return result;
  }

  Future<List<Map<String, dynamic>>> fetchMealScheduleForDate(
      String uid, DateTime date) async {
    final docId = '${uid}_${DateFormat('yyyy-MM-dd').format(date)}';
    final docRef =
        FirebaseFirestore.instance.collection('MealSchedules').doc(docId);
    final doc = await docRef.get();

    final List<Map<String, dynamic>> result = [];

    if (!doc.exists) return result;

    final data = doc.data()!;

    for (final type in ['breakfast', 'lunch', 'dinner', 'snacks']) {
      if (data.containsKey(type)) {
        final List<dynamic> meals = data[type];
        double totalCalories = 0.0;

        final List<Map<String, dynamic>> mealList = [];

        for (final m in meals) {
          final name = m['name'] ?? '';
          final calories = (m['totalCalories'] ?? 0.0) as num;
          totalCalories += calories;

          final ingredients = (m['ingredients'] as List<dynamic>?)
                  ?.map((i) => Map<String, dynamic>.from(i))
                  .toList() ??
              [];

          // Truy vấn thêm nutrition
          final mealQuery = await FirebaseFirestore.instance
              .collection('Meals')
              .where('name', isEqualTo: name)
              .limit(1)
              .get();

          Map<String, dynamic> nutri = {};
          if (mealQuery.docs.isNotEmpty) {
            nutri = mealQuery.docs.first.data()['nutri'] ?? {};
          }

          mealList.add({
            'name': name,
            'image': m['image'] ?? '',
            'time': m['time'] ?? '',
            'mealType': type,
            'date': date,
            'totalCalories': calories,
            'id_notify': m['id_notify'] ?? '0',
            'notify': m['notify'] ?? true,
            'ingredients': ingredients,
            'nutri': nutri,
          });
        }

        result.add({
          'mealType': type,
          'date': date,
          'meals': mealList,
          'totalCalories': totalCalories,
        });
      }
    }

    return result;
  }

  Future<Meal> getMealByName(String name) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('Meals')
        .where('name', isEqualTo: name)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      throw Exception('Meal not found');
    }

    final mealMap = snapshot.docs.first.data();
    Meal meal = Meal.fromMap(mealMap);

    final ingredientNames = <String>{};
    for (var ing in meal.ingredients) {
      ingredientNames.add(ing.name);
    }

    final ingredientsData = <String, Map<String, dynamic>>{};
    for (var name in ingredientNames) {
      final doc = await FirebaseFirestore.instance
          .collection('Ingredients')
          .doc(name)
          .get();
      if (doc.exists) {
        ingredientsData[name] = doc.data()!;
      }
    }

    for (var i = 0; i < meal.ingredients.length; i++) {
      final ing = meal.ingredients[i];
      final extra = ingredientsData[ing.name];

      if (extra != null) {
        meal.ingredients[i] = Ingredient(
          name: ing.name,
          amount: ing.amount,
          unit: extra['unit'] ?? '',
          image: extra['image'] ?? '',
          nutri: Nutrition.fromMap(extra['nutri'] ?? {}),
        );
      }
    }

    return meal;
  }

  Future<Meal> getMealWithScheduledIngredients(
    String name,
    List<dynamic> scheduledIngredientsRaw,
  ) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('Meals')
        .where('name', isEqualTo: name)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      throw Exception('Meal not found');
    }

    final mealMap = snapshot.docs.first.data();

    // Parse Meal từ database
    Meal originalMeal = Meal.fromMap(mealMap);

    // Parse lại ingredients từ schedule (đã được người dùng chỉnh)
    List<Ingredient> scheduledIngredients = scheduledIngredientsRaw
        .map((e) => Ingredient.fromMap(e as Map<String, dynamic>))
        .toList();

    // Ghi đè ingredients
    Meal updatedMeal = Meal(
      name: originalMeal.name,
      description: originalMeal.description,
      image: originalMeal.image,
      category: originalMeal.category,
      level: originalMeal.level,
      recipe: originalMeal.recipe,
      recommend: originalMeal.recommend,
      ingredients: scheduledIngredients, // GHI ĐÈ Ở ĐÂY
      nutri: originalMeal.nutri,
      size: originalMeal.size,
      time: originalMeal.time,
      id: originalMeal.id,
    );

    return updatedMeal;
  }

  Future<Map<String, List<FlSpot>>> generateWeeklyMealData({
    required String uid,
  }) async {
    DateTime now = DateTime.now();
    DateTime startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    DateTime endOfWeek = startOfWeek.add(Duration(days: 6));

    Map<int, double> caloriesByDay = {for (int i = 1; i <= 7; i++) i: 0};
    Map<int, double> carbByDay = {for (int i = 1; i <= 7; i++) i: 0};
    Map<int, double> fatByDay = {for (int i = 1; i <= 7; i++) i: 0};
    Map<int, double> proteinByDay = {for (int i = 1; i <= 7; i++) i: 0};

    QuerySnapshot mealSnapshot = await FirebaseFirestore.instance
        .collection('MealSchedules')
        .where('uid', isEqualTo: uid)
        .where('date',
            isGreaterThanOrEqualTo:
                DateFormat('yyyy-MM-dd').format(startOfWeek))
        .where('date',
            isLessThanOrEqualTo: DateFormat('yyyy-MM-dd').format(endOfWeek))
        .get();

    for (var doc in mealSnapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;

      DateTime date = DateTime.parse(data['date']);
      int weekday = date.weekday;

      // Danh sách bữa ăn trong ngày
      List<String> meals = ['breakfast', 'lunch', 'dinner', 'snacks'];

      for (var meal in meals) {
        if (data.containsKey(meal)) {
          List<dynamic> mealList = data[meal];

          for (var mealItem in mealList) {
            final totalCalories = (mealItem['totalCalories'] ?? 0).toDouble();
            final totalCarb = (mealItem['totalCarb'] ?? 0).toDouble();
            final totalFat = (mealItem['totalFat'] ?? 0).toDouble();
            final totalProtein = (mealItem['totalProtein'] ?? 0).toDouble();

            caloriesByDay[weekday] = caloriesByDay[weekday]! + totalCalories;
            carbByDay[weekday] = carbByDay[weekday]! + totalCarb;
            fatByDay[weekday] = fatByDay[weekday]! + totalFat;
            proteinByDay[weekday] = proteinByDay[weekday]! + totalProtein;
          }
        }
      }
    }

    // Chuyển về List<FlSpot> để vẽ biểu đồ
    List<FlSpot> calorieSpots = [];
    List<FlSpot> carbSpots = [];
    List<FlSpot> fatSpots = [];
    List<FlSpot> proteinSpots = [];

    for (int i = 1; i <= 7; i++) {
      calorieSpots.add(FlSpot(i.toDouble(), caloriesByDay[i]!));
      carbSpots.add(FlSpot(i.toDouble(), carbByDay[i]!));
      fatSpots.add(FlSpot(i.toDouble(), fatByDay[i]!));
      proteinSpots.add(FlSpot(i.toDouble(), proteinByDay[i]!));
    }

    return {
      'calories': calorieSpots,
      'carb': carbSpots,
      'fat': fatSpots,
      'protein': proteinSpots,
    };
  }
}

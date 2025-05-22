class NutritionCalculator {
  // Tính BMR
  static double calculateBMR({
    required double weight,         // in kg
    required double height,         // in cm
    required int age,
    required double bodyFatPercent,
  }) {
    final leanMass = weight * (1 - bodyFatPercent / 100);
    return 370 + (21.6 * leanMass);
  }

  // Hệ số hoạt động
  static double getActivityFactor(String level) {
    switch (level) {
      case "Sedentary":
        return 1.2;
      case "Lightly Active":
        return 1.375;
      case "Moderately Active":
        return 1.55;
      case "Very Active":
        return 1.725;
      case "Extra Active":
        return 1.9;
      default:
        return 1.2;
    }
  }

  // Điều chỉnh calo theo mục tiêu
  static double adjustCaloriesForGoal(double tdee, String goal) {
    switch (goal) {
      case "Improve Shape":
        return tdee * 1.15; // tăng cân nhẹ
      case "Lose a Fat":
        return tdee * 0.8;  // giảm cân nhẹ
      case "Lean & Tone":
      default:
        return tdee; // giữ cân
    }
  }

  static double calculateMaxCalories({
    required double weight,
    required double height,
    required int age,
    required String activityLevel,
    required String goal,
    required double bodyFatPercent,
  }) {
    final bmr = calculateBMR(
      weight: weight,
      height: height,
      age: age,
      bodyFatPercent: bodyFatPercent,
    );
    final tdee = bmr * getActivityFactor(activityLevel);
    return adjustCaloriesForGoal(tdee, goal);
  }

  static double calculateTDEE({
    required double weight,
    required double height,
    required int age,
    required String activityLevel,
    required double bodyFatPercent,
  }) {
    final bmr = calculateBMR(
      weight: weight,
      height: height,
      age: age,
      bodyFatPercent: bodyFatPercent,
    );
    return bmr * getActivityFactor(activityLevel);
  }

  // Các tỉ lệ macro theo mục tiêu
  static Map<String, double> getMacroRatio(String goal) {
    switch (goal) {
      case "Improve Shape":
        return {"carb": 0.5, "protein": 0.25, "fat": 0.25};
      case "Lose a Fat":
        return {"carb": 0.35, "protein": 0.4, "fat": 0.25};
      case "Lean & Tone":
      default:
        return {"carb": 0.45, "protein": 0.3, "fat": 0.25};
    }
  }

  static double calculateMaxCarb(double calories, String goal) {
    final ratio = getMacroRatio(goal)["carb"]!;
    return (calories * ratio) / 4; // 4 kcal/gram
  }

  static double calculateMaxProtein(double calories, String goal) {
    final ratio = getMacroRatio(goal)["protein"]!;
    return (calories * ratio) / 4; // 4 kcal/gram
  }

  static double calculateMaxFat(double calories, String goal) {
    final ratio = getMacroRatio(goal)["fat"]!;
    return (calories * ratio) / 9; // 9 kcal/gram
  }
}

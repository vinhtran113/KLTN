import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../common/colo_extension.dart';
import '../../common/nutrition_calculator.dart';
import '../../localization/app_localizations.dart';
import '../../main.dart';
import '../../model/user_model.dart';

class NutritionSummaryView extends StatefulWidget {
  final UserModel user;
  const NutritionSummaryView({super.key, required this.user});

  @override
  _NutritionSummaryViewState createState() => _NutritionSummaryViewState();
}

class _NutritionSummaryViewState extends State<NutritionSummaryView> {
  double bmr = 0;
  double tdee = 0;
  double cals = 0;
  double carb = 0;
  double protein = 0;
  double fat = 0;
  bool darkmode = darkModeNotifier.value;

  @override
  void initState() {
    super.initState();
    double weight = double.parse(widget.user.weight);
    double height = double.parse(widget.user.height);
    int age = widget.user.getAge();
    double bodyFatPercent = double.parse(widget.user.body_fat);
    String goal = widget.user.level;
    String activityLevel = widget.user.ActivityLevel;

    bmr = NutritionCalculator.calculateBMR(weight: weight, height: height, age: age, bodyFatPercent: bodyFatPercent);
    tdee = NutritionCalculator.calculateTDEE(weight: weight, height: height, age: age, activityLevel: activityLevel, bodyFatPercent: bodyFatPercent);
    cals = NutritionCalculator.adjustCaloriesForGoal(tdee, goal);
    carb = NutritionCalculator.calculateMaxCarb(cals, goal);
    protein = NutritionCalculator.calculateMaxProtein(cals, goal);
    fat = NutritionCalculator.calculateMaxFat(cals, goal);
  }

  String _getTooltipText(String label) {
    switch (label.toLowerCase()) {
      case "bmr":
        return "BMR (Basal Metabolic Rate): Lượng calo cơ thể cần để duy trì sự sống khi nghỉ ngơi.";
      case "tdee":
        return "TDEE (Total Daily Energy Expenditure): Tổng năng lượng bạn tiêu hao trong một ngày bao gồm cả vận động.";
      case "recommended intake":
        return "Lượng calo bạn nên nạp vào để đạt được mục tiêu giảm/cân bằng/tăng cân.";
      case "carbs":
        return "Carbs: Cung cấp năng lượng chính cho cơ thể. Nên chọn carbs tốt từ gạo lứt, rau củ, trái cây.";
      case "protein":
        return "Protein: Giúp xây dựng và phục hồi cơ bắp. Có nhiều trong thịt nạc, trứng, đậu, sữa.";
      case "fat":
        return "Fat: Chất béo tốt cần thiết cho hormone và hấp thụ vitamin. Nên dùng dầu oliu, hạt, cá.";
      case "goal":
        return "Mục tiêu của bạn như: giảm cân, duy trì, tăng cân.";
      default:
        return "Thông tin dinh dưỡng liên quan đến $label.";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: darkmode? Colors.blueGrey[900] : TColor.white,
        centerTitle: true,
        elevation: 0,
        leading: InkWell(
          onTap: () {
            Navigator.pop(context);
          },
          child: Container(
            margin: const EdgeInsets.all(8),
            height: 40,
            width: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                color: TColor.lightGray,
                borderRadius: BorderRadius.circular(10)),
            child: Image.asset(
              "assets/img/black_btn.png",
              width: 15,
              height: 15,
              fit: BoxFit.contain,
            ),
          ),
        ),
        title: Text(
          AppLocalizations.of(context)?.translate("Nutrition Summary") ?? "Nutrition Summary",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildSectionTitle("Your Goal"),
            _buildCard(
              icon: LucideIcons.target,
              label: "Goal",
              value: widget.user.level.toString(),
              color: Colors.orange.shade400,
            ),
            const SizedBox(height: 20),
            _buildSectionTitle("Calorie Summary"),
            Row(
              children: [
                Expanded(
                  child: _buildCard(
                    icon: LucideIcons.flame,
                    label: "BMR",
                    value: "${bmr.toStringAsFixed(0)} kcal",
                    color: Colors.redAccent,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildCard(
                    icon: LucideIcons.activity,
                    label: "TDEE",
                    value: "${tdee.toStringAsFixed(0)} kcal",
                    color: Colors.teal,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildCard(
              icon: LucideIcons.arrowDownUp,
              label: "Recommended Intake",
              value: "${cals.toStringAsFixed(0)} kcal/day",
              color: Colors.blueAccent,
            ),
            const SizedBox(height: 20),
            _buildSectionTitle("Macronutrient Distribution"),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildMacroCard("Carbs", carb, Colors.amber, "g"),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMacroCard("Protein", protein, Colors.lightBlue, "g"),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMacroCard("Fat", fat, Colors.pinkAccent, "g"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: Tooltip(
          message: _getTooltipText(label),
          child: Icon(icon, color: color, size: 30),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label),

            Tooltip(
              message: _getTooltipText(label),
              child: Icon(Icons.info_outline, size: 18, color: Colors.grey),
            ),
          ],
        ),
        subtitle: Text(value, style: const TextStyle(fontSize: 16)),
      ),
    );
  }

  Widget _buildMacroCard(String label, double value, Color color, String unit) {
    return Tooltip(
      message: _getTooltipText(label),
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
                const SizedBox(width: 4),
                Icon(Icons.info_outline, size: 16, color: Colors.grey),
              ],
            ),
            const SizedBox(height: 8),
            Text("${value.toStringAsFixed(1)} $unit", style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}

import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitness_workout_app/view/login/welcome_view.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../common/nutrition_calculator.dart';
import '../../common_widget/round_button.dart';
import '../../main.dart';
import '../../model/user_model.dart';
import '../../services/auth_services.dart';

class OverviewView extends StatefulWidget {
  const OverviewView({super.key});

  @override
  _OverviewViewState createState() => _OverviewViewState();
}

class _OverviewViewState extends State<OverviewView> {
  double bmr = 0;
  double tdee = 0;
  double cals = 0;
  double carb = 0;
  double protein = 0;
  double fat = 0;
  String goal = "";
  String name = "";
  String gender = "";
  double weight = 0;
  double height = 0;
  String dob = "";
  int age = 0;
  double bodyFatPercent = 0;
  String activityLevel = "";
  bool darkmode = darkModeNotifier.value;

  @override
  void initState() {
    super.initState();
    _getUser();
  }

  void _getUser() async {
    try {
      // Lấy thông tin người dùng
      UserModel? user = await AuthService().getUserInfo(FirebaseAuth.instance.currentUser!.uid);

      setState(() {
        weight = double.parse(user!.weight);
        height = double.parse(user.height);
        name = user.fname + " " + user.lname;
        gender = user.gender;
        dob = user.dateOfBirth;
        age = user.getAge();
        bodyFatPercent = double.parse(user.body_fat);
        activityLevel = user.ActivityLevel;
        goal = user.level;
        bmr = NutritionCalculator.calculateBMR(weight: weight, height: height, age: age, bodyFatPercent: bodyFatPercent);
        tdee = NutritionCalculator.calculateTDEE(weight: weight, height: height, age: age, activityLevel: activityLevel, bodyFatPercent: bodyFatPercent);
        cals = NutritionCalculator.adjustCaloriesForGoal(tdee, goal);
        carb = NutritionCalculator.calculateMaxCarb(cals, goal);
        protein = NutritionCalculator.calculateMaxProtein(cals, goal);
        fat = NutritionCalculator.calculateMaxFat(cals, goal);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi xảy ra: $e')),
      );
    }
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Text(
              "Overview",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            _buildSectionTitle("Personal Information"),
            _buildUserInfoCard(),
            const SizedBox(height: 20),
            _buildSectionTitle("Your Goal"),
            _buildCard(
              icon: LucideIcons.target,
              label: "Goal",
              value: goal,
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
            const SizedBox(height: 20),

            RoundButton(
                title: "Next >",
                onPressed: (){
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const WelcomeView(),
                    ),
                  );
                }
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserInfoCard() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildUserInfoRow("Name", name),
            _buildUserInfoRow("Gender", gender),
            _buildUserInfoRow("Date of Birth", dob),
            _buildUserInfoRow("Age", "$age yo"),
            _buildUserInfoRow("Weight", "$weight kg"),
            _buildUserInfoRow("Height", "$height cm"),
            _buildUserInfoRow("Body Fat %", "$bodyFatPercent %"),
            _buildUserInfoRow("Activity Level", activityLevel),
          ],
        ),
      ),
    );
  }

  Widget _buildUserInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          Text(value),
        ],
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

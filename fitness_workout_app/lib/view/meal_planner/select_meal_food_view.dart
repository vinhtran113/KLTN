import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitness_workout_app/common/colo_extension.dart';
import 'package:fitness_workout_app/view/meal_planner/select_detail_food_view.dart';
import 'package:flutter/material.dart';
import '../../common_widget/select_food_row.dart';
import '../../model/meal_model.dart';
import '../../services/meal_services.dart';
import '../../main.dart';
import '../../localization/app_localizations.dart';

class SelectMealFoodView extends StatefulWidget {
  const SelectMealFoodView({super.key});

  @override
  State<SelectMealFoodView> createState() => _SelectMealFoodViewState();
}

class _SelectMealFoodViewState extends State<SelectMealFoodView> {
  final MealService _mealService = MealService();
  List<Meal> allMealArr = [];
  List<Meal> filteredMeals = [];
  List<String> userMedicalHistory = [];
  final TextEditingController _searchController = TextEditingController();
  bool darkmode = darkModeNotifier.value;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAllMeals();
    _searchController.addListener(_onSearchChanged);
    _loadUserMedicalHistory();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _loadUserMedicalHistory() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final userDoc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final List<String> medicalHistory =
        List<String>.from(userDoc.data()?['medical_history'] ?? []);
    setState(() {
      userMedicalHistory = medicalHistory;
    });
  }

  void _loadAllMeals() async {
    try {
      setState(() {
        isLoading = true;
      });
      List<Meal> meals = await _mealService.fetchAllMeals();
      setState(() {
        allMealArr = meals;
        filteredMeals = meals;
        isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
      setState(() {
        isLoading = false;
      });
    }
  }

  void _onSearchChanged() {
    String keyword = _searchController.text.trim().toLowerCase();
    setState(() {
      if (keyword.isEmpty) {
        // Trở lại danh sách được recommend
        filteredMeals = allMealArr;
      } else {
        filteredMeals = allMealArr
            .where((meal) => meal.name.toLowerCase().contains(keyword))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;
    return Container(
      decoration:
          BoxDecoration(gradient: LinearGradient(colors: TColor.primaryG)),
      child: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              backgroundColor: Colors.transparent,
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
                AppLocalizations.of(context)?.translate("Food/Beverage List") ??
                    "Food/Beverage List",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
              ),
            ),
          ];
        },
        body: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
              color: darkmode ? Colors.blueGrey[900] : TColor.white,
              borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(25), topRight: Radius.circular(25))),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: SizedBox(
                      width: double.infinity,
                      child: TextField(
                        controller: _searchController,
                        style: TextStyle(
                            color: darkmode ? TColor.white : TColor.black),
                        decoration: InputDecoration(
                          hintText: AppLocalizations.of(context)
                                  ?.translate("Search...") ??
                              "Search...",
                          hintStyle: TextStyle(
                              color: darkmode
                                  ? Colors.white.withOpacity(0.7)
                                  : Colors.black.withOpacity(0.7)),
                          filled: true,
                          fillColor: Colors.grey.withOpacity(0.1),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 15, vertical: 10),
                        ),
                      ),
                    ),
                  ),
                  if (isLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (filteredMeals.isNotEmpty) ...[
                    ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 15.0),
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      itemCount: filteredMeals.length,
                      itemBuilder: (context, index) {
                        Meal fObj = filteredMeals[index];
                        return InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SelectDetailFoodView(
                                  dObj: fObj,
                                  onSelect: (selectedTitle) {
                                    Navigator.pop(context, selectedTitle);
                                  },
                                ),
                              ),
                            );
                          },
                          child: SelectFoodRow(
                            wObj: fObj,
                            onSelect: (selectedMeals) async {
                              final List<String> healthRisks =
                                  List<String>.from(fObj.healthRisks);
                              final List<String> warningRisks = healthRisks
                                  .where((risk) =>
                                      userMedicalHistory.contains(risk))
                                  .toList();

                              if (warningRisks.isNotEmpty) {
                                final shouldContinue = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text("Health Warning"),
                                    content: Text(
                                      "This food may not be suitable for your medical condition(s):\n${warningRisks.join(', ')}\n\nDo you want to continue?",
                                      style: const TextStyle(color: Colors.red),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                        child: const Text("Cancel"),
                                      ),
                                      ElevatedButton(
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                        child: const Text("Continue"),
                                      ),
                                    ],
                                  ),
                                );
                                if (shouldContinue != true) return;
                              }
                              Navigator.pop(context, selectedMeals);
                            },
                          ),
                        );
                      },
                    ),
                  ] else
                    Center(
                      child: Text(
                        AppLocalizations.of(context)?.translate("Not Found") ??
                            "Not Found",
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    ),
                  SizedBox(height: media.width * 0.1),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

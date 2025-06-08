import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitness_workout_app/common/colo_extension.dart';
import 'package:fitness_workout_app/common_widget/select_train_row.dart';
import 'package:flutter/material.dart';
import '../../services/workout_services.dart';
import '../../main.dart';
import '../../localization/app_localizations.dart';

class SelectWorkoutView extends StatefulWidget {
  const SelectWorkoutView({super.key});

  @override
  State<SelectWorkoutView> createState() => _SelectWorkoutViewState();
}

class _SelectWorkoutViewState extends State<SelectWorkoutView> {
  final WorkoutService _workoutService = WorkoutService();
  List<Map<String, dynamic>> whatArr = [];
  List<Map<String, dynamic>> filteredArr = [];
  List<String> userMedicalHistory = [];
  final TextEditingController _searchController = TextEditingController();
  bool darkmode = darkModeNotifier.value;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategoryWorkouts();
    _searchController.addListener(_filterWorkouts);
    _loadUserMedicalHistory();
  }

  @override
  void dispose() {
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

  Future<void> _loadCategoryWorkouts() async {
    setState(() {
      isLoading = true;
    });
    List<Map<String, dynamic>> workouts =
        await _workoutService.fetchWorkoutList();
    setState(() {
      whatArr = workouts;
      filteredArr = workouts;
      isLoading = false;
    });
  }

  void _filterWorkouts() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      filteredArr = whatArr.where((workout) {
        // Tìm kiếm dựa trên tên hoặc các thuộc tính khác
        return workout["title"].toLowerCase().contains(query);
      }).toList();
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
                AppLocalizations.of(context)?.translate("Workout List") ??
                    "Workout List",
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
                  else if (filteredArr.isNotEmpty) ...[
                    ListView.builder(
                        padding: EdgeInsets.zero,
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: filteredArr.length,
                        itemBuilder: (context, index) {
                          var wObj = filteredArr[index] as Map? ?? {};
                          return SelectTrainRow(
                            wObj: wObj,
                            onSelect: (selectedTitle) async {
                              final List<String> healthRisks =
                                  List<String>.from(wObj['health_risks'] ?? []);
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
                                      "This workout may not be suitable for your medical condition(s):\n${warningRisks.join(', ')}\n\nDo you want to continue?",
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
                              Navigator.pop(context, selectedTitle);
                            },
                          );
                        }),
                  ] else
                    Center(
                      child: Text(
                        AppLocalizations.of(context)?.translate("Not Found") ??
                            "Not Found",
                        style: const TextStyle(color: Colors.grey),
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

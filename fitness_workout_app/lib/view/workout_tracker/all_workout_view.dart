import 'package:fitness_workout_app/common/colo_extension.dart';
import 'package:flutter/material.dart';
import '../../common_widget/what_train_row.dart';
import '../../services/workout_services.dart';
import '../../main.dart';
import '../../localization/app_localizations.dart';

class AllWorkoutView extends StatefulWidget {
  const AllWorkoutView({super.key});

  @override
  State<AllWorkoutView> createState() => _AllWorkoutViewState();
}

class _AllWorkoutViewState extends State<AllWorkoutView> {
  final WorkoutService _workoutService = WorkoutService();
  List<Map<String, dynamic>> whatArr = [];
  List<Map<String, dynamic>> filteredArr = [];
  final TextEditingController _searchController = TextEditingController();
  bool darkmode = darkModeNotifier.value;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategoryWorkouts();
    _searchController.addListener(_filterWorkouts);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCategoryWorkouts() async {
    setState(() {
      isLoading = true;
    });
    List<Map<String, dynamic>> workouts =
        await _workoutService.fetchWorkoutList();
    setState(() {
      whatArr = workouts;
      filteredArr = workouts; // Hiển thị tất cả ban đầu
      isLoading = false;
    });
  }

  void _filterWorkouts() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      filteredArr = whatArr.where((workout) {
        // Tìm kiếm dựa trên tên hoặc các thuộc tính khác
        return workout["title"]
            .toLowerCase()
            .contains(query); // Giả sử mỗi phần tử có trường 'name'
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
                    borderRadius: BorderRadius.circular(10),
                  ),
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
                topLeft: Radius.circular(25), topRight: Radius.circular(25)),
          ),
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
                          fillColor: darkmode
                              ? Colors.white.withOpacity(0.1)
                              : Colors.grey.withOpacity(0.1),
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
                        return InkWell(
                          child: WhatTrainRow(wObj: wObj),
                        );
                      },
                    ),
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

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitness_workout_app/common/colo_extension.dart';
import 'package:fitness_workout_app/common_widget/icon_title_next_row.dart';
import 'package:fitness_workout_app/common_widget/round_button.dart';
import 'package:fitness_workout_app/view/workout_tracker/ready_view.dart';
import 'package:fitness_workout_app/view/workout_tracker/workout_review_view.dart';
import 'package:fitness_workout_app/view/workout_tracker/workout_schedule_view.dart';
import 'package:flutter/material.dart';

import '../../common_widget/exercises_row.dart';
import '../../model/exercise_model.dart';
import '../../services/workout_services.dart';
import '../../main.dart';
import '../../localization/app_localizations.dart';

class WorkoutDetailView extends StatefulWidget {
  final Map dObj;
  const WorkoutDetailView({super.key, required this.dObj});

  @override
  State<WorkoutDetailView> createState() => _WorkoutDetailViewState();
}

class _WorkoutDetailViewState extends State<WorkoutDetailView> {
  final TextEditingController selectedDifficulty = TextEditingController();
  final WorkoutService _workoutService = WorkoutService();
  List<Map<String, dynamic>> youArr = [];
  List<Exercise> exercisesArr = [];
  Map<String, String> listInfo = {};
  List<String> userMedicalHistory = [];
  List<String> warningRisks = [];
  bool darkmode = darkModeNotifier.value;

  // Thêm các biến cho review
  double avgRating = 0;
  int totalReviews = 0;

  @override
  void initState() {
    super.initState();
    _loadToolsForWorkout();
    selectedDifficulty.text = widget.dObj["difficulty"];
    _loadExercises();
    _loadCaloAndTime();
    _loadReviewInfo();
    _loadUserMedicalHistory();
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
      // So sánh với health_risks của bài tập
      final List<String> healthRisks =
          List<String>.from(widget.dObj['health_risks'] ?? []);
      warningRisks = healthRisks
          .where((risk) => userMedicalHistory.contains(risk))
          .toList();
    });
  }

  Future<void> _loadReviewInfo() async {
    final workoutId = widget.dObj["id"].toString();
    final snapshot = await FirebaseFirestore.instance
        .collection('Workouts')
        .doc(workoutId)
        .collection('Reviews')
        .get();

    double total = 0;
    int count = 0;

    for (var doc in snapshot.docs) {
      final data = doc.data();
      if (data['rating'] != null) {
        total += (data['rating'] as num).toDouble();
        count++;
      }
    }
    setState(() {
      avgRating = count > 0 ? total / count : 0;
      totalReviews = count;
    });
  }

  void _loadToolsForWorkout() async {
    String workoutId = widget.dObj["id"].toString();
    List<Map<String, dynamic>> tools =
        await _workoutService.fetchToolsForWorkout(workoutId);
    setState(() {
      youArr = tools;
    });
  }

  void _loadCaloAndTime() async {
    String workoutId = widget.dObj["id"].toString();
    Map<String, String> list = await _workoutService.fetchTimeAndCalo(
      categoryId: workoutId,
      difficulty: selectedDifficulty.text.trim(),
    );
    setState(() {
      listInfo = list;
    });
  }

  void _loadExercises() async {
    String workoutId = widget.dObj["id"].toString();
    List<Exercise> exercises = await _workoutService.fetchExercisesFromWorkout(
      workoutId: workoutId,
    );
    setState(() {
      exercisesArr = exercises;
    });
  }

  void _showDifficultySelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: ["Beginner", "Normal", "Professional"].map((difficulty) {
              return ListTile(
                title: Text(
                  AppLocalizations.of(context)?.translate(difficulty) ??
                      difficulty,
                  style: TextStyle(
                      color: darkmode ? TColor.white : TColor.black,
                      fontSize: 14),
                ),
                onTap: () {
                  setState(() {
                    selectedDifficulty.text = difficulty;
                    _loadExercises();
                    _loadCaloAndTime();
                  });
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  void _createHistory() async {
    // Tạo một WorkoutHistory rỗng
    String historyId = await _workoutService.createEmptyWorkoutHistory(
      uid: FirebaseAuth.instance.currentUser!.uid,
      idCate: widget.dObj["id"].toString(),
      exercisesArr: exercisesArr,
      difficulty: selectedDifficulty.text,
    );

    // Chuyển sang trang ReadyView
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReadyView(
          exercises: exercisesArr,
          historyId: historyId,
          index: 0,
          diff: selectedDifficulty.text.trim(), // Truyền Id để cập nhật sau
        ),
      ),
    );
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
            ),
            SliverAppBar(
              backgroundColor: Colors.transparent,
              centerTitle: true,
              elevation: 0,
              leadingWidth: 0,
              leading: Container(),
              expandedHeight: media.width * 0.5,
              flexibleSpace: Align(
                alignment: Alignment.center,
                child: Image.network(
                  widget.dObj["image"].toString(),
                  width: media.width * 0.75,
                  height: media.width * 0.8,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.error,
                      color: Colors.red,
                      size: 90,
                    );
                  },
                ),
              ),
            ),
          ];
        },
        body: Container(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          decoration: BoxDecoration(
              color: darkmode ? Colors.blueGrey[900] : TColor.white,
              borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(25), topRight: Radius.circular(25))),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: Stack(
              children: [
                SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(
                        height: 10,
                      ),
                      Container(
                        width: 50,
                        height: 4,
                        decoration: BoxDecoration(
                            color: TColor.gray.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(3)),
                      ),
                      SizedBox(
                        height: media.width * 0.05,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (warningRisks.isNotEmpty)
                                  Container(
                                    margin:
                                        const EdgeInsets.symmetric(vertical: 8),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.red),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.warning,
                                            color: Colors.red),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            "Warning: This workout may not be suitable for your medical condition(s): ${warningRisks.join(', ')}",
                                            style: const TextStyle(
                                                color: Colors.red,
                                                fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                Text(
                                  widget.dObj["title"].toString(),
                                  style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700),
                                ),
                                Text(
                                  "${exercisesArr.length.toString()} ${AppLocalizations.of(context)?.translate("exercise") ?? "Exercises"} | "
                                  "${listInfo["time"].toString()} ${AppLocalizations.of(context)?.translate("Mins") ?? "Mins"} | "
                                  "${listInfo["calo"].toString()} ${AppLocalizations.of(context)?.translate("Calories Burned") ?? "Calories Burned"}",
                                  style: TextStyle(
                                      color: TColor.gray, fontSize: 12),
                                ),
                                Row(
                                  children: [
                                    Icon(Icons.star,
                                        color: Colors.amber, size: 18),
                                    SizedBox(width: 4),
                                    Text(
                                      avgRating.toStringAsFixed(1),
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    SizedBox(width: 12),
                                    Icon(Icons.comment,
                                        color: Colors.grey, size: 18),
                                    SizedBox(width: 4),
                                    Text(
                                      '$totalReviews comments',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                    Spacer(),
                                    TextButton(
                                      onPressed: () async {
                                        final result = await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                WorkoutReviewView(
                                              workoutId:
                                                  widget.dObj["id"].toString(),
                                            ),
                                          ),
                                        );
                                        if (result == true) {
                                          _loadReviewInfo();
                                        }
                                      },
                                      child: Text('See All',
                                          style: TextStyle(
                                              color: TColor.gray,
                                              fontSize: 12)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(
                        height: media.width * 0.01,
                      ),
                      InkWell(
                        onTap: () {
                          _showDifficultySelector(context);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 8, horizontal: 15),
                          decoration: BoxDecoration(
                            color: TColor.primary,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                width: 30,
                                height: 30,
                                alignment: Alignment.center,
                                child: Image.asset(
                                  "assets/img/difficulity.png",
                                  width: 16,
                                  height: 16,
                                  fit: BoxFit.contain,
                                ),
                              ),

                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  AppLocalizations.of(context)
                                          ?.translate("Difficulty") ??
                                      "Difficulty",
                                  style: TextStyle(
                                      color:
                                          darkmode ? TColor.white : TColor.gray,
                                      fontSize: 12),
                                ),
                              ),

                              SizedBox(
                                width: 120,
                                child: Text(
                                  selectedDifficulty.text,
                                  textAlign: TextAlign.right,
                                  style: TextStyle(
                                      color:
                                          darkmode ? TColor.white : TColor.gray,
                                      fontSize: 12),
                                ),
                              ),
                              // Icon hiển thị ở bên phải
                              Container(
                                width: 25,
                                height: 25,
                                alignment: Alignment.center,
                                child: Image.asset(
                                  "assets/img/p_next.png",
                                  width: 12,
                                  height: 12,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(
                        height: media.width * 0.02,
                      ),
                      IconTitleNextRow(
                          icon: "assets/img/time.png",
                          title: AppLocalizations.of(context)
                                  ?.translate("Workout Schedule") ??
                              "Workout Schedule",
                          time: AppLocalizations.of(context)
                                  ?.translate("Add to Schedule") ??
                              "Add to Schedule",
                          color: darkmode
                              ? TColor.white.withOpacity(0.8)
                              : TColor.primaryColor2.withOpacity(0.3),
                          onPressed: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        const WorkoutScheduleView()));
                          }),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            AppLocalizations.of(context)
                                    ?.translate("You'll Need") ??
                                "You'll Need",
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                          TextButton(
                            onPressed: () {},
                            child: Text(
                              "${youArr.length} ${AppLocalizations.of(context)?.translate("Items") ?? "Items"}",
                              style:
                                  TextStyle(color: TColor.gray, fontSize: 12),
                            ),
                          )
                        ],
                      ),
                      SizedBox(
                        height: media.width * 0.5,
                        child: ListView.builder(
                            padding: EdgeInsets.zero,
                            scrollDirection: Axis.horizontal,
                            shrinkWrap: true,
                            itemCount: youArr.length,
                            itemBuilder: (context, index) {
                              var yObj = youArr[index] as Map? ?? {};
                              return Container(
                                  margin: const EdgeInsets.all(8),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        height: media.width * 0.35,
                                        width: media.width * 0.35,
                                        decoration: BoxDecoration(
                                            color: TColor.lightGray,
                                            borderRadius:
                                                BorderRadius.circular(15)),
                                        alignment: Alignment.center,
                                        child: Image.network(
                                          yObj["image"].toString(),
                                          width: media.width * 0.2,
                                          height: media.width * 0.2,
                                          fit: BoxFit.contain,
                                          loadingBuilder: (context, child,
                                              loadingProgress) {
                                            if (loadingProgress == null) {
                                              return child;
                                            }
                                            return Center(
                                              child: CircularProgressIndicator(
                                                value: loadingProgress
                                                            .expectedTotalBytes !=
                                                        null
                                                    ? loadingProgress
                                                            .cumulativeBytesLoaded /
                                                        loadingProgress
                                                            .expectedTotalBytes!
                                                    : null,
                                              ),
                                            );
                                          },
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                            return Icon(
                                              Icons.error,
                                              color: Colors.red,
                                              size: 90,
                                            );
                                          },
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Text(
                                          yObj["title"].toString(),
                                          style: TextStyle(fontSize: 12),
                                        ),
                                      )
                                    ],
                                  ));
                            }),
                      ),
                      SizedBox(
                        height: media.width * 0.001,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            AppLocalizations.of(context)
                                    ?.translate("Exercises") ??
                                "Exercises",
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                          TextButton(
                            onPressed: () {},
                            child: Text(
                              "${exercisesArr.length.toString()} ${AppLocalizations.of(context)?.translate("exercise") ?? "Exercises"}",
                              style:
                                  TextStyle(color: TColor.gray, fontSize: 12),
                            ),
                          )
                        ],
                      ),
                      ListView.builder(
                        padding: EdgeInsets.zero,
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: exercisesArr.length,
                        itemBuilder: (context, index) {
                          Exercise eObj = exercisesArr[index];
                          return ExercisesRow(
                            eObj: eObj,
                            diff: selectedDifficulty.text.trim(),
                          );
                        },
                      ),
                      SizedBox(
                        height: media.width * 0.1,
                      ),
                    ],
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 15),
                          child: RoundButton(
                              title: AppLocalizations.of(context)
                                      ?.translate("Start Workout") ??
                                  "Start Workout",
                              onPressed: _createHistory),
                        ),
                      ],
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

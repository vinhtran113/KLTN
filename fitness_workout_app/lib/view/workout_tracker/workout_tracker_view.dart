import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitness_workout_app/common/colo_extension.dart';
import 'package:fitness_workout_app/view/workout_tracker/all_history_workout_view.dart';
import 'package:fitness_workout_app/view/workout_tracker/workout_schedule_view.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../common_widget/round_button.dart';
import '../../common_widget/upcoming_workout_row.dart';
import '../../common_widget/what_train_row.dart';
import '../../common_widget/workout_row.dart';
import '../../model/user_model.dart';
import '../../model/workout_schedule_model.dart';
import '../../services/auth_services.dart';
import '../../services/workout_services.dart';
import '../main_tab/main_tab_view.dart';
import 'all_workout_view.dart';
import '../../main.dart';
import '../../localization/app_localizations.dart';

class WorkoutTrackerView extends StatefulWidget {
  const WorkoutTrackerView({super.key});

  @override
  State<WorkoutTrackerView> createState() => _WorkoutTrackerViewState();
}

class _WorkoutTrackerViewState extends State<WorkoutTrackerView> {
  final WorkoutService _workoutService = WorkoutService();
  List<Map<String, dynamic>> whatArr = [];
  List<WorkoutSchedule> latestArr = [];
  List<Map<String, dynamic>> lastWorkoutArr = [];
  List<FlSpot> calorieSpots = [];
  List<FlSpot> durationSpots = [];
  bool darkmode = darkModeNotifier.value;
  bool isLoading = true;
  bool isLoading1 = true;

  @override
  void initState() {
    super.initState();
    _loadCategoryWorkoutsWithLevel();
    _loadHistoryWorkout();
    _loadClosestWorkoutSchedules();
    _loadFLSpot();
  }

  void _loadCategoryWorkoutsWithLevel() async {
    setState(() {
      isLoading1 = true;
    });
    UserModel? user =
        await AuthService().getUserInfo(FirebaseAuth.instance.currentUser!.uid);
    if (user != null) {
      String level = user.level;
      List<Map<String, dynamic>> workouts =
          await _workoutService.fetchWorkoutsByLevel(level: level);
      setState(() {
        whatArr = workouts;
        isLoading1 = false;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Có lỗi xảy ra')),
      );
    }
  }

  void _loadHistoryWorkout() async {
    List<Map<String, dynamic>> lastWorkout = await _workoutService
        .fetchWorkoutHistory(uid: FirebaseAuth.instance.currentUser!.uid);
    setState(() {
      lastWorkoutArr = lastWorkout;
    });
  }

  void _loadClosestWorkoutSchedules() async {
    setState(() {
      isLoading = true;
    });
    List<WorkoutSchedule> list =
        await _workoutService.getClosestWorkoutSchedules(
            uid: FirebaseAuth.instance.currentUser!.uid);
    setState(() {
      latestArr = list;
      isLoading = false;
    });
  }

  void _loadFLSpot() async {
    Map<String, List<FlSpot>> data = await _workoutService.generateWeeklyData(
        uid: FirebaseAuth.instance.currentUser!.uid);
    setState(() {
      calorieSpots = data['calories']!;
      durationSpots = data['duration']!;
    });
  }

  void getUserInfo() async {
    try {
      // Lấy thông tin người dùng
      UserModel? user = await AuthService()
          .getUserInfo(FirebaseAuth.instance.currentUser!.uid);

      if (user != null) {
        // Điều hướng đến HomeView với user
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => MainTabView(user: user, initialTab: 1),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Có lỗi xảy ra')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi xảy ra: $e')),
      );
    }
  }

  void _confirmDeleteSchedule(String Id) async {
    String res = await _workoutService.deleteWorkoutSchedule(scheduleId: Id);
    if (res == "success") {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Workout schedule deleted successfully')));

      _loadClosestWorkoutSchedules();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res)),
      );
    }
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
                onTap: getUserInfo,
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
                AppLocalizations.of(context)?.translate("Workout Tracker") ??
                    "Workout Tracker",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
              ),
            ),
            SliverAppBar(
              backgroundColor: Colors.transparent,
              centerTitle: true,
              elevation: 0,
              leadingWidth: 0,
              leading: const SizedBox(),
              expandedHeight: media.width * 0.5,
              flexibleSpace: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                height: media.width * 0.5,
                width: double.maxFinite,
                child: LineChart(
                  LineChartData(
                    lineTouchData: LineTouchData(
                      enabled: true,
                      handleBuiltInTouches: true,
                      touchTooltipData: LineTouchTooltipData(
                        tooltipRoundedRadius: 10,
                        getTooltipItems: (List<LineBarSpot> touchedSpots) {
                          return touchedSpots.map((spot) {
                            // Xác định loại dữ liệu (calo hoặc thời gian)
                            String valueSuffix;
                            String valueLabel;

                            // Nếu là calo
                            if (spot.barIndex == 0) {
                              valueSuffix = 'KCal';
                              valueLabel =
                                  'Calo: ${spot.y.toStringAsFixed(2)} $valueSuffix';
                            }
                            // Nếu là thời gian, chia cho 60 để có phút
                            else {
                              valueSuffix = 'Mins';
                              double minutes = spot.y / 60;
                              valueLabel =
                                  'Time: ${minutes.toStringAsFixed(2)} $valueSuffix';
                            }

                            return LineTooltipItem(
                              valueLabel,
                              const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            );
                          }).toList();
                        },
                      ),
                    ),
                    lineBarsData: lineBarsData1,
                    minY: -0.5,
                    maxY: 3000,
                    titlesData: FlTitlesData(
                        show: true,
                        leftTitles: AxisTitles(),
                        topTitles: AxisTitles(),
                        bottomTitles: AxisTitles(
                          sideTitles: bottomTitles,
                        ),
                        rightTitles: AxisTitles(
                          sideTitles: rightTitles,
                        )),
                    gridData: FlGridData(
                      show: true,
                      drawHorizontalLine: true,
                      horizontalInterval: 25,
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (value) {
                        return FlLine(
                          color: TColor.white.withOpacity(0.15),
                          strokeWidth: 2,
                        );
                      },
                    ),
                    borderData: FlBorderData(
                      show: true,
                      border: Border.all(
                        color: Colors.transparent,
                      ),
                    ),
                  ),
                ),
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
                  Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 15, horizontal: 15),
                    decoration: BoxDecoration(
                      color: TColor.primaryColor2.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          AppLocalizations.of(context)
                                  ?.translate("Daily Workout Schedule") ??
                              "Daily Workout Schedule",
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w700),
                        ),
                        SizedBox(
                          width: 80,
                          height: 30,
                          child: RoundButton(
                            title: AppLocalizations.of(context)
                                    ?.translate("Check") ??
                                "Check",
                            type: RoundButtonType.bgGradient,
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const WorkoutScheduleView(),
                                ),
                              );
                            },
                          ),
                        )
                      ],
                    ),
                  ),
                  SizedBox(
                    height: media.width * 0.03,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppLocalizations.of(context)
                                ?.translate("Upcoming Workout") ??
                            "Upcoming Workout",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: media.width * 0.03,
                  ),
                  if (isLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (latestArr.isNotEmpty) ...[
                    ListView.builder(
                      padding: EdgeInsets.zero,
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      itemCount: latestArr.length,
                      itemBuilder: (context, index) {
                        WorkoutSchedule wObj = latestArr[index];
                        return Dismissible(
                          key: Key(wObj.id), // Mỗi mục cần một key duy nhất
                          direction:
                              DismissDirection.endToStart, // Chỉ kéo sang trái
                          background: Container(
                            color: Colors.red,
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child:
                                const Icon(Icons.delete, color: Colors.white),
                          ),
                          confirmDismiss: (direction) async {
                            // Hiển thị hộp thoại xác nhận trước khi xoá
                            bool? confirm = await showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: Text(AppLocalizations.of(context)
                                          ?.translate("Confirm Delete") ??
                                      "Confirm Delete"),
                                  content: Text(AppLocalizations.of(context)
                                          ?.translate("Confirm Delete des") ??
                                      "Are you sure you want to delete this workout schedule?"),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(false),
                                      child: Text(AppLocalizations.of(context)
                                              ?.translate("Cancel") ??
                                          "Cancel"),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(true),
                                      child: Text(AppLocalizations.of(context)
                                              ?.translate("Delete") ??
                                          "Delete"),
                                    ),
                                  ],
                                );
                              },
                            );
                            // Nếu người dùng xác nhận, cho phép xoá
                            return confirm == true;
                          },
                          onDismissed: (direction) {
                            // Gọi hàm xác nhận xoá (nếu xác nhận, sẽ xoá phần tử)
                            _confirmDeleteSchedule(wObj.id);
                          },
                          child: UpcomingWorkoutRow(
                            wObj: wObj,
                            onRefresh: () {
                              _loadClosestWorkoutSchedules();
                            },
                          ),
                        );
                      },
                    ),
                  ] else
                    Center(
                      child: Text(
                        AppLocalizations.of(context)
                                ?.translate("Not Scheduled") ??
                            "Not Scheduled",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  if (lastWorkoutArr.isNotEmpty) ...[
                    SizedBox(
                      height: media.width * 0.03,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          AppLocalizations.of(context)
                                  ?.translate("Latest Workout") ??
                              "Latest Workout",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const AllHistoryWorkoutView(),
                              ),
                            );
                          },
                          child: Text(
                            AppLocalizations.of(context)
                                    ?.translate("See More") ??
                                "See More",
                            style: TextStyle(
                              color: TColor.gray,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        )
                      ],
                    ),
                    ListView.builder(
                      padding: EdgeInsets.zero,
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      itemCount: lastWorkoutArr.length.clamp(0, 2),
                      // Hiển thị tối đa 2 phần tử
                      itemBuilder: (context, index) {
                        var wObj = lastWorkoutArr[index] as Map? ?? {};
                        return InkWell(
                          child: WorkoutRow(wObj: wObj),
                        );
                      },
                    )
                  ],
                  SizedBox(
                    height: media.width * 0.03,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppLocalizations.of(context)
                                ?.translate("Recommended for you") ??
                            "Recommended for you",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AllWorkoutView(),
                            ),
                          );
                        },
                        child: Text(
                          AppLocalizations.of(context)
                                  ?.translate("See Full Exercise") ??
                              "See Full Exercise",
                          style: TextStyle(
                              color: TColor.gray,
                              fontSize: 14,
                              fontWeight: FontWeight.w700),
                        ),
                      )
                    ],
                  ),
                  if (isLoading1)
                    const Center(child: CircularProgressIndicator())
                  else if (whatArr.isNotEmpty) ...[
                    ListView.builder(
                        padding: EdgeInsets.zero,
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: whatArr.length,
                        itemBuilder: (context, index) {
                          var wObj = whatArr[index] as Map? ?? {};
                          return InkWell(child: WhatTrainRow(wObj: wObj));
                        }),
                  ] else
                    Center(
                      child: Text(
                        AppLocalizations.of(context)?.translate("Not Found") ??
                            "Not Found",
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ),
                  SizedBox(
                    height: media.width * 0.1,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String getDayLabel(double x) {
    const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return days[x.toInt() - 1];
  }

  List<LineChartBarData> get lineBarsData1 => [
        lineChartBarData1_1,
        lineChartBarData1_2,
      ];

  LineChartBarData get lineChartBarData1_1 => LineChartBarData(
      isCurved: true,
      color: TColor.white,
      barWidth: 4,
      isStrokeCapRound: true,
      dotData: FlDotData(show: true),
      belowBarData: BarAreaData(show: false),
      spots: calorieSpots);

  LineChartBarData get lineChartBarData1_2 => LineChartBarData(
      isCurved: true,
      color: TColor.white.withOpacity(0.5),
      barWidth: 2,
      isStrokeCapRound: true,
      dotData: FlDotData(show: true),
      belowBarData: BarAreaData(
        show: false,
      ),
      spots: durationSpots);

  SideTitles get rightTitles => SideTitles(
        getTitlesWidget: rightTitleWidgets,
        showTitles: true,
        interval: 20,
        reservedSize: 40,
      );

  Widget rightTitleWidgets(double value, TitleMeta meta) {
    String text;
    switch (value.toInt()) {
      case 0:
        text = '0 KCal';
        break;
      case 500:
        text = '500';
        break;
      case 1000:
        text = '10k';
        break;
      case 1500:
        text = '15k';
        break;
      case 2000:
        text = '20k';
        break;
      case 2500:
        text = '25k';
        break;
      case 3000:
        text = '30k';
        break;
      default:
        return Container();
    }

    return Text(text,
        style: TextStyle(
          color: TColor.white,
          fontSize: 12,
        ),
        textAlign: TextAlign.center);
  }

  SideTitles get bottomTitles => SideTitles(
        showTitles: true,
        reservedSize: 32,
        interval: 1,
        getTitlesWidget: bottomTitleWidgets,
      );

  Widget bottomTitleWidgets(double value, TitleMeta meta) {
    var style = TextStyle(
      color: TColor.white,
      fontSize: 12,
    );
    Widget text;
    switch (value.toInt()) {
      case 1:
        text = Text(AppLocalizations.of(context)?.translate("Mon") ?? "Mon",
            style: style);
        break;
      case 2:
        text = Text(AppLocalizations.of(context)?.translate("Tue") ?? "Tue",
            style: style);
        break;
      case 3:
        text = Text(AppLocalizations.of(context)?.translate("Wed") ?? "Wed",
            style: style);
        break;
      case 4:
        text = Text(AppLocalizations.of(context)?.translate("Thu") ?? "Thu",
            style: style);
        break;
      case 5:
        text = Text(AppLocalizations.of(context)?.translate("Fri") ?? "Fri",
            style: style);
        break;
      case 6:
        text = Text(AppLocalizations.of(context)?.translate("Sat") ?? "Sat",
            style: style);
        break;
      case 7:
        text = Text(AppLocalizations.of(context)?.translate("Sun") ?? "Sun",
            style: style);
        break;
      default:
        text = const Text('');
        break;
    }

    return SideTitleWidget(
      meta: meta,
      space: 10,
      child: text,
    );
  }
}

import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitness_workout_app/main.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../common/colo_extension.dart';
import '../../common_widget/find_eat_cell.dart';
import '../../common_widget/round_button.dart';
import '../../common_widget/today_meal_row.dart';
import '../../localization/app_localizations.dart';
import '../../model/user_model.dart';
import '../../services/auth_services.dart';
import '../main_tab/main_tab_view.dart';
import 'meal_schedule_view.dart';
import '../../services/meal_services.dart';

class MealPlannerView extends StatefulWidget {
  const MealPlannerView({super.key});

  @override
  State<MealPlannerView> createState() => _MealPlannerViewState();
}

class _MealPlannerViewState extends State<MealPlannerView> {
  final MealService _mealService = MealService();
  String selectedType = "Breakfast";
  List<Map<String, dynamic>> todayMealList = [];
  List<FlSpot> calorieSpots = [];
  List<FlSpot> carbSpots = [];
  List<FlSpot> proteinSpots = [];
  List<FlSpot> fatSpots = [];
  bool darkmode = darkModeNotifier.value;
  Map<String, List<Map<String, dynamic>>> allMealListByType = {
    'breakfast': [],
    'lunch': [],
    'dinner': [],
    'snacks': [],
  };
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMealCounts();
    _loadTodayMeals();
    _loadFLSpot();
  }

  List<Map<String, dynamic>> mealTypes = [
    {"name": "Breakfast", "image": "assets/img/breakfast_icon.png"},
    {"name": "Lunch", "image": "assets/img/lunch_icon.png"},
    {"name": "Dinner", "image": "assets/img/m_4.png"},
    {"name": "Snack", "image": "assets/img/m_3.png"},
  ];

  Future<void> _loadMealCounts() async {
    for (var meal in mealTypes) {
      int count = await _mealService.countMealsByRecommend(meal['name']);
      setState(() {
        meal['number'] = "$count Foods";
      });
    }
  }

  void _loadTodayMeals() async {
    setState(() {
      isLoading = true;
    });
    final allMeals = await _mealService.fetchMealScheduleForDate(
        FirebaseAuth.instance.currentUser!.uid, DateTime.now());

    final Map<String, List<Map<String, dynamic>>> temp = {
      'breakfast': [],
      'lunch': [],
      'dinner': [],
      'snacks': [],
    };

    for (var e in allMeals) {
      temp[e['mealType']] = List<Map<String, dynamic>>.from(e['meals']);
    }

    setState(() {
      allMealListByType = temp;
      todayMealList = temp[selectedType.toLowerCase()] ?? [];
      isLoading = false;
    });
  }

  void _loadFLSpot() async {
    Map<String, List<FlSpot>> data = await _mealService.generateWeeklyMealData(
        uid: FirebaseAuth.instance.currentUser!.uid);
    setState(() {
      calorieSpots = data['calories']!;
      carbSpots = data['carb']!;
      proteinSpots = data['protein']!;
      fatSpots = data['fat']!;
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

  Future<void> _handleDeleteMeal(String name, String idNotify) async {
    final result = await _mealService.deleteMealFromSchedule(
      uid: FirebaseAuth.instance.currentUser!.uid,
      date: DateTime.now(),
      mealType: selectedType.toLowerCase(),
      mealName: name,
      id_notify: idNotify,
    );

    if (result != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(result)));
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Xoá món ăn thành công')));
      _loadTodayMeals();
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
                AppLocalizations.of(context)?.translate("Meal Planner") ??
                    "Meal Planner",
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

                            if (spot.barIndex == 0) {
                              valueSuffix = 'KCal';
                              valueLabel =
                                  'Calo: ${spot.y.toStringAsFixed(2)} $valueSuffix';
                            } else if (spot.barIndex == 1) {
                              valueSuffix = 'g';
                              valueLabel =
                                  'Carb: ${spot.y.toStringAsFixed(2)} $valueSuffix';
                            } else if (spot.barIndex == 2) {
                              valueSuffix = 'g';
                              valueLabel =
                                  'Protein: ${spot.y.toStringAsFixed(2)} $valueSuffix';
                            } else {
                              valueSuffix = 'g';
                              valueLabel =
                                  'Fat: ${spot.y.toStringAsFixed(2)} $valueSuffix';
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
                mainAxisAlignment: MainAxisAlignment.start,
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
                                    ?.translate("Daily Meal Schedule") ??
                                "Daily Meal Schedule",
                            style: TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w700)),
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
                                      const MealScheduleView(),
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
                                  ?.translate("Today Meals") ??
                              "Today Meals",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700)),
                      Container(
                          height: 30,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: TColor.primaryG),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton(
                              items: [
                                "Breakfast",
                                "Lunch",
                                "Dinner",
                                "Snacks",
                              ]
                                  .map((name) => DropdownMenuItem(
                                      value: name,
                                      child: Text(
                                        name,
                                        style: TextStyle(
                                            color: TColor.gray, fontSize: 14),
                                      )))
                                  .toList(),
                              onChanged: (value) {
                                setState(() {
                                  selectedType = value!;
                                  todayMealList = allMealListByType[
                                          selectedType.toLowerCase()] ??
                                      [];
                                });
                              },
                              icon:
                                  Icon(Icons.expand_more, color: TColor.white),
                              hint: Text(
                                selectedType,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: TColor.white, fontSize: 12),
                              ),
                            ),
                          )),
                    ],
                  ),
                  SizedBox(
                    height: media.width * 0.03,
                  ),
                  if (isLoading)
                    const Center(child: CircularProgressIndicator())
                  else
                    ListView.builder(
                      padding: EdgeInsets.zero,
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      itemCount:
                          todayMealList.isEmpty ? 1 : todayMealList.length,
                      itemBuilder: (context, index) {
                        if (todayMealList.isEmpty) {
                          return const Center(
                            child: Text(
                              "Not Scheduled",
                              style: TextStyle(color: Colors.grey),
                            ),
                          );
                        }
                        var wObj = todayMealList[index] as Map? ?? {};
                        return Dismissible(
                          key: Key(wObj["name"]),
                          direction: DismissDirection.endToStart,
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
                                          ?.translate("Confirm Delete des 1") ??
                                      "Are you sure you want to delete this meal schedule?"),
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
                            _handleDeleteMeal(wObj["name"], wObj["id_notify"]);
                          },
                          child: TodayMealRow(
                            mObj: wObj,
                            onRefresh: () {
                              _loadTodayMeals();
                            },
                          ),
                        );
                      },
                    ),
                  SizedBox(
                    height: media.width * 0.05,
                  ),
                  Row(
                    children: [
                      Text(
                        "Find Something to Eat",
                        style: TextStyle(
                            color: TColor.black,
                            fontSize: 16,
                            fontWeight: FontWeight.w700),
                        textAlign: TextAlign.left,
                      ),
                    ],
                  ),
                  SizedBox(
                    height: media.width * 0.55,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 15.0),
                      scrollDirection: Axis.horizontal,
                      itemCount: mealTypes.length,
                      itemBuilder: (context, index) {
                        var fObj = mealTypes[index] as Map? ?? {};
                        return FindEatCell(
                          fObj: fObj,
                          index: index,
                        );
                      },
                    ),
                  ),
                  SizedBox(
                    height: media.width * 0.05,
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
        lineChartBarData1_3,
        lineChartBarData1_4,
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
        spots: carbSpots,
      );

  LineChartBarData get lineChartBarData1_3 => LineChartBarData(
      isCurved: true,
      color: TColor.white.withOpacity(0.5),
      barWidth: 2,
      isStrokeCapRound: true,
      dotData: FlDotData(show: true),
      belowBarData: BarAreaData(
        show: false,
      ),
      spots: proteinSpots);

  LineChartBarData get lineChartBarData1_4 => LineChartBarData(
      isCurved: true,
      color: TColor.white.withOpacity(0.5),
      barWidth: 2,
      isStrokeCapRound: true,
      dotData: FlDotData(show: true),
      belowBarData: BarAreaData(
        show: false,
      ),
      spots: fatSpots);

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

  SideTitles get rightTitles => SideTitles(
        getTitlesWidget: rightTitleWidgets,
        showTitles: true,
        interval: 20,
        reservedSize: 40,
      );

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

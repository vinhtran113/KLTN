import 'package:firebase_auth/firebase_auth.dart';
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
  Map<String, List<Map<String, dynamic>>> allMealListByType = {
    'breakfast': [],
    'lunch': [],
    'dinner': [],
    'snacks': [],
  };


  @override
  void initState() {
    super.initState();
    _loadMealCounts();
    _loadTodayMeals();
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
    final allMeals = await _mealService.fetchMealScheduleForDate(FirebaseAuth.instance.currentUser!.uid, DateTime.now());

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
    });
  }

  void getUserInfo() async {
    try {
      // Lấy thông tin người dùng
      UserModel? user = await AuthService().getUserInfo(
          FirebaseAuth.instance.currentUser!.uid);

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

  Future<void> _handleDeleteMeal(String name, String id_notify) async {
    final result = await _mealService.deleteMealFromSchedule(
      uid: FirebaseAuth.instance.currentUser!.uid,
      date: DateTime.now(),
      mealType: selectedType.toLowerCase(),
      mealName: name,
      id_notify: id_notify,
    );

    if (result != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result)));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Xoá món ăn thành công')));
      _loadTodayMeals();
    }
  }

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: TColor.white,
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
          "Meal Planner",
          style: TextStyle(
              color: TColor.black, fontSize: 22, fontWeight: FontWeight.w700),
        ),
      ),
      backgroundColor: TColor.white,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Meal Nutritions",
                        style: TextStyle(
                            color: TColor.black,
                            fontSize: 16,
                            fontWeight: FontWeight.w700),
                      ),
                      Container(
                          height: 30,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: TColor.primaryG),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton(
                              items: ["Weekly", "Monthly"]
                                  .map((name) => DropdownMenuItem(
                                value: name,
                                child: Text(
                                  name,
                                  style: TextStyle(
                                      color: TColor.gray, fontSize: 14),
                                ),
                              ))
                                  .toList(),
                              onChanged: (value) {},
                              icon:
                              Icon(Icons.expand_more, color: TColor.white),
                              hint: Text(
                                "Weekly",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: TColor.white, fontSize: 12),
                              ),
                            ),
                          )),
                    ],
                  ),
                  SizedBox(
                    height: media.width * 0.05,
                  ),
                  Container(
                      padding: const EdgeInsets.only(left: 15),
                      height: media.width * 0.5,
                      width: double.maxFinite,
                      child: LineChart(
                        LineChartData(
                          // showingTooltipIndicators:
                          //     showingTooltipOnSpots.map((index) {
                          //   return ShowingTooltipIndicators([
                          //     LineBarSpot(
                          //       tooltipsOnBar,
                          //       lineBarsData.indexOf(tooltipsOnBar),
                          //       tooltipsOnBar.spots[index],
                          //     ),
                          //   ]);
                          // }).toList(),
                          lineTouchData: LineTouchData(
                            enabled: true,
                            handleBuiltInTouches: false,
                            touchCallback: (FlTouchEvent event,
                                LineTouchResponse? response) {
                              // if (response == null || response.lineBarSpots == null) {
                              //   return;
                              // }
                              // if (event is FlTapUpEvent) {
                              //   final spotIndex =
                              //       response.lineBarSpots!.first.spotIndex;
                              //   showingTooltipOnSpots.clear();
                              //   setState(() {
                              //     showingTooltipOnSpots.add(spotIndex);
                              //   });
                              // }
                            },
                            mouseCursorResolver: (FlTouchEvent event,
                                LineTouchResponse? response) {
                              if (response == null ||
                                  response.lineBarSpots == null) {
                                return SystemMouseCursors.basic;
                              }
                              return SystemMouseCursors.click;
                            },
                            getTouchedSpotIndicator: (LineChartBarData barData,
                                List<int> spotIndexes) {
                              return spotIndexes.map((index) {
                                return TouchedSpotIndicatorData(
                                  FlLine(
                                    color: Colors.transparent,
                                  ),
                                  FlDotData(
                                    show: true,
                                    getDotPainter:
                                        (spot, percent, barData, index) =>
                                        FlDotCirclePainter(
                                          radius: 3,
                                          color: Colors.white,
                                          strokeWidth: 3,
                                          strokeColor: TColor.secondaryColor1,
                                        ),
                                  ),
                                );
                              }).toList();
                            },
                            touchTooltipData: LineTouchTooltipData(
                              getTooltipColor: (touchedBarSpot) => TColor.secondaryColor1,
                              tooltipRoundedRadius: 20,
                              getTooltipItems:
                                  (List<LineBarSpot> lineBarsSpot) {
                                return lineBarsSpot.map((lineBarSpot) {
                                  return LineTooltipItem(
                                    "${lineBarSpot.x.toInt()} mins ago",
                                    const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  );
                                }).toList();
                              },
                            ),
                          ),
                          lineBarsData: lineBarsData1,
                          minY: -0.5,
                          maxY: 110,
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
                                color: TColor.gray.withOpacity(0.15),
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
                      )),
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
                          "Daily Meal Schedule",
                          style: TextStyle(
                              color: TColor.black,
                              fontSize: 14,
                              fontWeight: FontWeight.w700)),
                        SizedBox(
                          width: 80,
                          height: 30,
                          child: RoundButton(
                            title: "Check",
                            type: RoundButtonType.bgGradient,
                            fontSize: 14,
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
                    height: media.width * 0.05,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Today Meals",
                        style: TextStyle(
                            color: TColor.black,
                            fontSize: 16,
                            fontWeight: FontWeight.w700)),
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
                              ].map((name) => DropdownMenuItem(
                                value: name,
                                child: Text(
                                  name,
                                  style: TextStyle(color: TColor.gray, fontSize: 14),
                                ))).toList(),
                              onChanged: (value){
                                setState(() {
                                  selectedType = value!;
                                  todayMealList = allMealListByType[selectedType.toLowerCase()] ?? [];
                                });
                              },
                              icon: Icon(Icons.expand_more, color: TColor.white),
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
                  ListView.builder(
                    padding: EdgeInsets.zero,
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: todayMealList.isEmpty ? 1 : todayMealList.length,
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
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        confirmDismiss: (direction) async {
                          // Hiển thị hộp thoại xác nhận trước khi xoá
                          bool? confirm = await showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: Text(AppLocalizations.of(context)?.translate("Confirm Delete") ?? "Confirm Delete"),
                                content: Text(
                                    AppLocalizations.of(context)?.translate("Confirm Delete des 1") ?? "Are you sure you want to delete this meal schedule?"
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(false),
                                    child: Text(AppLocalizations.of(context)?.translate("Cancel") ?? "Cancel"),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(true),
                                    child: Text(AppLocalizations.of(context)?.translate("Delete") ?? "Delete"),
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
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Text(
                "Find Something to Eat",
                style: TextStyle(
                    color: TColor.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w700),
              ),
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
    );
  }

  List<LineChartBarData> get lineBarsData1 => [
    lineChartBarData1_1,
  ];

  LineChartBarData get lineChartBarData1_1 => LineChartBarData(
    isCurved: true,
    gradient: LinearGradient(colors: [
      TColor.primaryColor2,
      TColor.primaryColor1,
    ]),
    barWidth: 2,
    isStrokeCapRound: true,
    dotData: FlDotData(
      show: true,
      getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
        radius: 3,
        color: Colors.white,
        strokeWidth: 1,
        strokeColor: TColor.primaryColor2,
      ),
    ),
    belowBarData: BarAreaData(show: false),
    spots: const [
      FlSpot(1, 35),
      FlSpot(2, 70),
      FlSpot(3, 40),
      FlSpot(4, 80),
      FlSpot(5, 25),
      FlSpot(6, 70),
      FlSpot(7, 35),
    ],
  );

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
        text = '0%';
        break;
      case 20:
        text = '20%';
        break;
      case 40:
        text = '40%';
        break;
      case 60:
        text = '60%';
        break;
      case 80:
        text = '80%';
        break;
      case 100:
        text = '100%';
        break;
      default:
        return Container();
    }

    return Text(text,
        style: TextStyle(
          color: TColor.gray,
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
      color: TColor.gray,
      fontSize: 12,
    );
    Widget text;
    switch (value.toInt()) {
      case 1:
        text = Text('Sun', style: style);
        break;
      case 2:
        text = Text('Mon', style: style);
        break;
      case 3:
        text = Text('Tue', style: style);
        break;
      case 4:
        text = Text('Wed', style: style);
        break;
      case 5:
        text = Text('Thu', style: style);
        break;
      case 6:
        text = Text('Fri', style: style);
        break;
      case 7:
        text = Text('Sat', style: style);
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
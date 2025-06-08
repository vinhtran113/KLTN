import 'package:dotted_dashed_line/dotted_dashed_line.dart';
import 'package:fitness_workout_app/common/nutrition_calculator.dart';
import 'package:fitness_workout_app/common_widget/round_button.dart';
import 'package:fitness_workout_app/services/alarm_services.dart';
import 'package:fitness_workout_app/services/meal_services.dart';
import 'package:fitness_workout_app/services/workout_services.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:simple_animation_progress_bar/simple_animation_progress_bar.dart';
import 'package:simple_circular_progress_bar/simple_circular_progress_bar.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../common/colo_extension.dart';
import '../../main.dart';
import 'notification_view.dart';
import 'package:fitness_workout_app/model/user_model.dart';
import '../../localization/app_localizations.dart';

class HomeView extends StatefulWidget {
  final UserModel user;

  const HomeView({super.key, required this.user});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  List<int> showingTooltipOnSpots = [21];
  late ValueNotifier<double> percentNotifier;

  List<Map<String, dynamic>> caloMealArr = [
    {"title": "Breakfast", "subtitle": "0kCal"},
    {"title": "Lunch", "subtitle": "0kCal"},
    {"title": "Dinner", "subtitle": "0kCal"},
    {"title": "Snacks", "subtitle": "0kCal"},
  ];

  final AlarmService _alarmService = AlarmService();
  final WorkoutService _workoutService = WorkoutService();
  final MealService _mealService = MealService();
  String totalTime = '0 hours 0 minutes';
  double BMI = 0.0;
  int caloToday = 0;
  double tdee = 0;
  double cals = 0;
  List<FlSpot> calorieSpots = [];
  List<FlSpot> calorieSpots1 = [];

  bool darkmode = darkModeNotifier.value;

  @override
  void initState() {
    super.initState();
    double weight = double.parse(widget.user.weight);
    double height = double.parse(widget.user.height);
    int age = widget.user.getAge();
    double bodyFatPercent = double.parse(widget.user.body_fat);
    String activityLevel = widget.user.ActivityLevel;
    String goal = widget.user.level;
    percentNotifier = ValueNotifier(percent);

    tdee = NutritionCalculator.calculateTDEE(
        weight: weight,
        height: height,
        age: age,
        activityLevel: activityLevel,
        bodyFatPercent: bodyFatPercent);
    cals = NutritionCalculator.adjustCaloriesForGoal(tdee, goal);
    _calculateBMI();
    _loadTimeSleepLastNight();
    _calculateTodayCalories();
    _loadCaloMealArr();
    _loadFLSpot();
  }

  @override
  void dispose() {
    percentNotifier.dispose();
    super.dispose();
  }

  void _loadFLSpot() async {
    Map<String, List<FlSpot>> data =
        await _workoutService.generateWeeklyData(uid: widget.user.uid);
    Map<String, List<FlSpot>> data1 =
        await _mealService.generateWeeklyMealData(uid: widget.user.uid);
    setState(() {
      calorieSpots = data['calories']!;
      calorieSpots1 = data1['calories']!;
    });
  }

  void _loadCaloMealArr() async {
    final arr = await _mealService.getCaloriesPerMeal(
      uid: widget.user.uid,
      date: DateTime.now(),
    );
    setState(() {
      caloMealArr = arr;
    });
  }

  String _getStatus(double bmi) {
    String bmiStatus;

    if (bmi < 18.5) {
      bmiStatus = "You are underweight";
    } else if (bmi >= 18.5 && bmi < 24.9) {
      bmiStatus = "You have a normal weight";
    } else if (bmi >= 25 && bmi < 29.9) {
      bmiStatus = "You are overweight";
    } else if (bmi >= 30 && bmi < 34.9) {
      bmiStatus = "You are level 1 obese";
    } else {
      bmiStatus = "You are obese level 2 or higher";
    }
    return bmiStatus;
  }

  void _calculateBMI() async {
    try {
      // Chuyển đổi height và weight từ String sang double
      double height = double.parse(widget.user.height);
      double weight = double.parse(widget.user.weight);

      // Kiểm tra nếu giá trị hợp lệ
      if (height <= 0 || weight <= 0) {
        throw Exception("Height and weight must be greater than zero.");
      }
      // Công thức tính BMI: weight (kg) / (height (m) ^ 2)
      height = height / 100;
      double bmi = weight / (height * height);
      bmi = double.parse(bmi.toStringAsFixed(1));
      setState(() {
        BMI = bmi;
      });
    } catch (e) {
      print("Error calculating BMI: $e");
    }
  }

  void _loadTimeSleepLastNight() async {
    int total =
        await _alarmService.calculateTotalSleepTime(uid: widget.user.uid);

    setState(() {
      int hours = total ~/ 60;
      int minutes = total % 60;
      totalTime = '$hours hours $minutes minutes';
    });
  }

  Future<void> _calculateTodayCalories() async {
    int calo = await _workoutService.calculateTodayCalories(widget.user.uid);

    setState(() {
      caloToday = calo;
      percentNotifier.value = percent;
    });
  }

  double get percent {
    if (tdee > 0) {
      double p = (caloToday / tdee) * 100;
      if (p > 100) p = 100;
      if (p < 0) p = 0;
      return p;
    }
    return 0;
  }

  double get caloriesIntakeRatio {
    double totalIntake = 0;
    for (var meal in caloMealArr) {
      // Loại bỏ "kCal" và chuyển thành double
      String subtitle =
          meal["subtitle"].toString().replaceAll("kCal", "").trim();
      double value = double.tryParse(subtitle) ?? 0;
      totalIntake += value;
    }
    if (cals > 0) {
      double ratio = totalIntake / cals;
      if (ratio > 1) ratio = 1;
      if (ratio < 0) ratio = 0;
      return ratio;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;

    return Scaffold(
      body: SingleChildScrollView(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context)
                                  ?.translate("Welcome Back") ??
                              "Welcome Back,",
                          style: TextStyle(color: TColor.gray, fontSize: 12),
                        ),
                        Text(
                          "${widget.user.fname} ${widget.user.lname}",
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    IconButton(
                      onPressed: () async {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const NotificationView(),
                          ),
                        );
                      },
                      icon: Image.asset(
                        "assets/img/notification_inactive.png",
                        width: 25,
                        height: 25,
                        fit: BoxFit.fitHeight,
                        color: darkmode ? TColor.white : TColor.black,
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  height: media.width * 0.05,
                ),
                Container(
                  height: media.width * 0.4,
                  decoration: BoxDecoration(
                      gradient: LinearGradient(colors: TColor.primaryG),
                      borderRadius: BorderRadius.circular(media.width * 0.075)),
                  child: Stack(alignment: Alignment.center, children: [
                    Image.asset(
                      "assets/img/bg_dots.png",
                      height: media.width * 0.4,
                      width: double.maxFinite,
                      fit: BoxFit.fitHeight,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 25, horizontal: 25),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                height: media.width * 0.025,
                              ),
                              Text(
                                AppLocalizations.of(context)
                                        ?.translate("BMI") ??
                                    "BMI (Body Mass Index)",
                                style: TextStyle(
                                    color: TColor.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700),
                              ),
                              Text(
                                _getStatus(BMI),
                                style: TextStyle(
                                    color: TColor.white.withOpacity(0.7),
                                    fontSize: 16),
                              ),
                              SizedBox(
                                height: media.width * 0.05,
                              ),
                              SizedBox(
                                width: 120,
                                height: 35,
                                child: RoundButton(
                                  title: AppLocalizations.of(context)
                                          ?.translate("View More") ??
                                      "View More",
                                  type: RoundButtonType.bgSGradient,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                  onPressed: () async {
                                    final url = Uri.parse(
                                        'https://my.clevelandclinic.org/health/articles/9464-body-mass-index-bmi');
                                    if (!await launchUrl(url,
                                        mode: LaunchMode.externalApplication)) {
                                      await launchUrl(url);
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                          AspectRatio(
                            aspectRatio: 1,
                            child: PieChart(
                              PieChartData(
                                pieTouchData: PieTouchData(
                                  touchCallback:
                                      (FlTouchEvent event, pieTouchResponse) {},
                                ),
                                startDegreeOffset: 250,
                                borderData: FlBorderData(
                                  show: false,
                                ),
                                sectionsSpace: 1,
                                centerSpaceRadius: 0,
                                sections: showingSections(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  ]),
                ),
                SizedBox(
                  height: media.width * 0.05,
                ),
                Text(
                  AppLocalizations.of(context)?.translate("Activity Status") ??
                      "Activity Status",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                SizedBox(
                  height: media.width * 0.02,
                ),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: media.width * 0.95,
                        padding: const EdgeInsets.symmetric(
                            vertical: 25, horizontal: 20),
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(25),
                            boxShadow: const [
                              BoxShadow(color: Colors.black12, blurRadius: 2)
                            ]),
                        child: Row(
                          children: [
                            SimpleAnimationProgressBar(
                              height: media.width * 0.85,
                              width: media.width * 0.07,
                              backgroundColor: Colors.grey.shade100,
                              foregroundColor: Colors.purple,
                              ratio: caloriesIntakeRatio,
                              direction: Axis.vertical,
                              curve: Curves.fastLinearToSlowEaseIn,
                              duration: const Duration(seconds: 3),
                              borderRadius: BorderRadius.circular(15),
                              gradientColor: LinearGradient(
                                  colors: TColor.primaryG,
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter),
                            ),
                            const SizedBox(
                              width: 10,
                            ),
                            Expanded(
                                child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppLocalizations.of(context)
                                          ?.translate("Calories Intake") ??
                                      "Calories Intake",
                                  style: TextStyle(
                                      color: TColor.black,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700),
                                ),
                                ShaderMask(
                                  blendMode: BlendMode.srcIn,
                                  shaderCallback: (bounds) {
                                    return LinearGradient(
                                            colors: TColor.primaryG,
                                            begin: Alignment.centerLeft,
                                            end: Alignment.centerRight)
                                        .createShader(Rect.fromLTRB(
                                            0, 0, bounds.width, bounds.height));
                                  },
                                  child: Text(
                                    "${cals.toStringAsFixed(0)} kCal",
                                    style: TextStyle(
                                        color: TColor.white.withOpacity(0.7),
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14),
                                  ),
                                ),
                                const SizedBox(
                                  height: 10,
                                ),
                                Text(
                                  AppLocalizations.of(context)
                                          ?.translate("Real time updates") ??
                                      "Real time updates",
                                  style: TextStyle(
                                    color: TColor.gray,
                                    fontSize: 12,
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: caloMealArr.map((wObj) {
                                    var isLast = wObj == caloMealArr.last;
                                    return Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            Container(
                                              margin:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 4),
                                              width: 10,
                                              height: 10,
                                              decoration: BoxDecoration(
                                                color: TColor.secondaryColor1
                                                    .withOpacity(0.5),
                                                borderRadius:
                                                    BorderRadius.circular(5),
                                              ),
                                            ),
                                            if (!isLast)
                                              DottedDashedLine(
                                                  height: media.width * 0.078,
                                                  width: 0,
                                                  dashColor: TColor
                                                      .secondaryColor1
                                                      .withOpacity(0.5),
                                                  axis: Axis.vertical)
                                          ],
                                        ),
                                        const SizedBox(
                                          width: 10,
                                        ),
                                        Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              wObj["title"].toString(),
                                              style: TextStyle(
                                                color: TColor.gray,
                                                fontSize: 10,
                                              ),
                                            ),
                                            ShaderMask(
                                              blendMode: BlendMode.srcIn,
                                              shaderCallback: (bounds) {
                                                return LinearGradient(
                                                        colors:
                                                            TColor.secondaryG,
                                                        begin: Alignment
                                                            .centerLeft,
                                                        end: Alignment
                                                            .centerRight)
                                                    .createShader(Rect.fromLTRB(
                                                        0,
                                                        0,
                                                        bounds.width,
                                                        bounds.height));
                                              },
                                              child: Text(
                                                wObj["subtitle"].toString(),
                                                style: TextStyle(
                                                    color: TColor.white
                                                        .withOpacity(0.7),
                                                    fontSize: 12),
                                              ),
                                            ),
                                          ],
                                        )
                                      ],
                                    );
                                  }).toList(),
                                )
                              ],
                            ))
                          ],
                        ),
                      ),
                    ),
                    SizedBox(
                      width: media.width * 0.05,
                    ),
                    Expanded(
                        child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: double.maxFinite,
                          height: media.width * 0.45,
                          padding: const EdgeInsets.symmetric(
                              vertical: 25, horizontal: 20),
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(25),
                              boxShadow: const [
                                BoxShadow(color: Colors.black12, blurRadius: 2)
                              ]),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppLocalizations.of(context)
                                          ?.translate("Total Sleep Hours") ??
                                      "Total Sleep Hours",
                                  style: TextStyle(
                                      color: TColor.black,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700),
                                ),
                                ShaderMask(
                                  blendMode: BlendMode.srcIn,
                                  shaderCallback: (bounds) {
                                    return LinearGradient(
                                            colors: TColor.primaryG,
                                            begin: Alignment.centerLeft,
                                            end: Alignment.centerRight)
                                        .createShader(Rect.fromLTRB(
                                            0, 0, bounds.width, bounds.height));
                                  },
                                  child: Text(
                                    totalTime,
                                    style: TextStyle(
                                        color: TColor.white.withOpacity(0.7),
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14),
                                  ),
                                ),
                                const Spacer(),
                                Image.asset("assets/img/sleep_grap.png",
                                    width: double.maxFinite,
                                    fit: BoxFit.fitWidth)
                              ]),
                        ),
                        SizedBox(
                          height: media.width * 0.05,
                        ),
                        Container(
                          width: double.maxFinite,
                          height: media.width * 0.45,
                          padding: const EdgeInsets.symmetric(
                              vertical: 25, horizontal: 20),
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(25),
                              boxShadow: const [
                                BoxShadow(color: Colors.black12, blurRadius: 2)
                              ]),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppLocalizations.of(context)
                                          ?.translate("Calories Burned") ??
                                      "Calories Burned",
                                  style: TextStyle(
                                      color: TColor.black,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700),
                                ),
                                ShaderMask(
                                  blendMode: BlendMode.srcIn,
                                  shaderCallback: (bounds) {
                                    return LinearGradient(
                                            colors: TColor.primaryG,
                                            begin: Alignment.centerLeft,
                                            end: Alignment.centerRight)
                                        .createShader(Rect.fromLTRB(
                                            0, 0, bounds.width, bounds.height));
                                  },
                                  child: Text(
                                    "${tdee.toStringAsFixed(0)} kCal",
                                    style: TextStyle(
                                        color: TColor.white.withOpacity(0.7),
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14),
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  alignment: Alignment.center,
                                  child: SizedBox(
                                    width: media.width * 0.2,
                                    height: media.width * 0.2,
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        Container(
                                          width: media.width * 0.15,
                                          height: media.width * 0.15,
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                                colors: TColor.primaryG),
                                            borderRadius: BorderRadius.circular(
                                                media.width * 0.075),
                                          ),
                                          child: FittedBox(
                                            child: Text(
                                              "${caloToday.toStringAsFixed(0)} kCal\nleft",
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                  color: TColor.white,
                                                  fontSize: 11),
                                            ),
                                          ),
                                        ),
                                        SimpleCircularProgressBar(
                                          progressStrokeWidth: 10,
                                          backStrokeWidth: 10,
                                          progressColors: TColor.primaryG,
                                          backColor: Colors.grey.shade100,
                                          valueNotifier: percentNotifier,
                                          startAngle: -180,
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              ]),
                        ),
                      ],
                    ))
                  ],
                ),
                SizedBox(
                  height: media.width * 0.05,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppLocalizations.of(context)
                              ?.translate("Progress This Week") ??
                          "Progress This Week",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
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
                      lineTouchData: LineTouchData(
                        enabled: true,
                        handleBuiltInTouches: true,
                        touchTooltipData: LineTouchTooltipData(
                          tooltipRoundedRadius: 10,
                          getTooltipItems: (List<LineBarSpot> touchedSpots) {
                            return touchedSpots.map((spot) {
                              String label;
                              if (spot.barIndex == 0) {
                                label =
                                    'Workout: ${spot.y.toStringAsFixed(0)} KCal';
                              } else {
                                label =
                                    'Meal: ${spot.y.toStringAsFixed(0)} KCal';
                              }
                              return LineTooltipItem(
                                label,
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
                      maxY: 3001,
                      titlesData: FlTitlesData(
                        show: true,
                        leftTitles: AxisTitles(),
                        topTitles: AxisTitles(),
                        bottomTitles: AxisTitles(
                          sideTitles: bottomTitles,
                        ),
                        rightTitles: AxisTitles(
                          sideTitles: rightTitles,
                        ),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawHorizontalLine: true,
                        horizontalInterval: 500,
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
    );
  }

  List<PieChartSectionData> showingSections() {
    return List.generate(
      2,
      (i) {
        var color0 = TColor.secondaryColor1;

        switch (i) {
          case 0:
            return PieChartSectionData(
                color: color0,
                value: BMI,
                title: '',
                radius: 55,
                titlePositionPercentageOffset: 0.55,
                badgeWidget: Text(
                  BMI.toString(),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700),
                ));
          case 1:
            return PieChartSectionData(
              color: Colors.white,
              value: 100 - BMI,
              title: '',
              radius: 45,
              titlePositionPercentageOffset: 0.55,
            );

          default:
            throw Error();
        }
      },
    );
  }

  LineTouchData get lineTouchData1 => LineTouchData(
        handleBuiltInTouches: true,
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (touchedBarSpot) => Colors.blueGrey.withOpacity(0.8),
        ),
      );

  List<LineChartBarData> get lineBarsData1 => [
        lineChartBarData1_1,
        lineChartBarData1_2,
      ];

  FlSpot? getPeakSpot(List<FlSpot> spots) {
    if (spots.isEmpty) return null;
    return spots.reduce((a, b) => a.y > b.y ? a : b);
  }

  LineChartBarData get lineChartBarData1_1 => LineChartBarData(
        isCurved: true,
        gradient: LinearGradient(colors: [
          TColor.primaryColor2.withOpacity(0.5),
          TColor.primaryColor1.withOpacity(0.5),
        ]),
        barWidth: 4,
        isStrokeCapRound: true,
        dotData: FlDotData(show: true),
        belowBarData: BarAreaData(show: false),
        spots: calorieSpots,
      );

  LineChartBarData get lineChartBarData1_2 => LineChartBarData(
        isCurved: true,
        gradient: LinearGradient(colors: [
          TColor.secondaryColor2.withOpacity(0.5),
          TColor.secondaryColor1.withOpacity(0.5),
        ]),
        barWidth: 2,
        isStrokeCapRound: true,
        dotData: FlDotData(
          show: true,
        ),
        belowBarData: BarAreaData(
          show: false,
        ),
        spots: calorieSpots1,
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

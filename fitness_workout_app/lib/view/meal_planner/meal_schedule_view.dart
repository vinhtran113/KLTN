import 'package:calendar_agenda/calendar_agenda.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../common/colo_extension.dart';
import '../../common/common.dart';
import '../../common/nutrition_calculator.dart';
import '../../common_widget/meal_food_schedule_row.dart';
import '../../common_widget/nutritions_row.dart';
import '../../model/user_model.dart';
import '../../services/auth_services.dart';
import '../../services/meal_services.dart';
import '../../view/meal_planner/add_meal_schedule_view.dart';
import 'edit_meal_schedule_view.dart';
import 'meal_planner_view.dart';

class MealScheduleView extends StatefulWidget {
  const MealScheduleView({super.key});

  @override
  State<MealScheduleView> createState() => _MealScheduleViewState();
}

class _MealScheduleViewState extends State<MealScheduleView> {
  final CalendarAgendaController _calendarAgendaControllerAppBar =
      CalendarAgendaController();
  final MealService _mealService = MealService();
  late DateTime _selectedDateAppBBar;

  List<Map<String, dynamic>> mealEventArr = [];
  List<Map<String, dynamic>> selectedMealList = [];

  List<Map<String, dynamic>> breakfastArr = [];
  List<Map<String, dynamic>> lunchArr = [];
  List<Map<String, dynamic>> dinnerArr = [];
  List<Map<String, dynamic>> snacksArr = [];

  List nutritionArr = [];

  double breakfastCalories = 0.0;
  double lunchCalories = 0.0;
  double dinnerCalories = 0.0;
  double snacksCalories = 0.0;

  double tdee = 1;
  double cals = 1;
  double carb = 1;
  double protein = 1;
  double fat = 1;

  @override
  void initState() {
    super.initState();
    _selectedDateAppBBar = DateTime.now();
    _getUser();
    _loadMealSchedule();
    _setDayMealList();
  }

  void _loadMealSchedule() async {
    String uid = FirebaseAuth.instance.currentUser!.uid;
    List<Map<String, dynamic>> schedule =
        await _mealService.fetchMealScheduleList(uid);
    setState(() {
      mealEventArr = schedule;
    });
    _setDayMealList();
  }

  void _getUser() async {
    try {
      // Lấy thông tin người dùng
      UserModel? user = await AuthService()
          .getUserInfo(FirebaseAuth.instance.currentUser!.uid);
      double weight = double.parse(user!.weight);
      double height = double.parse(user.height);
      int age = user.getAge();
      double bodyFatPercent = double.parse(user.body_fat);
      String activityLevel = user.ActivityLevel;
      String goal = user.level;

      setState(() {
        tdee = NutritionCalculator.calculateTDEE(
            weight: weight,
            height: height,
            age: age,
            activityLevel: activityLevel,
            bodyFatPercent: bodyFatPercent);
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

  void _setDayMealList() {
    var date = dateToStartDate(_selectedDateAppBBar);

    final dayMeals = mealEventArr.where((mObj) {
      return dateToStartDate(mObj["date"]) == date;
    }).toList();

    breakfastArr = [];
    lunchArr = [];
    dinnerArr = [];
    snacksArr = [];

    breakfastCalories = 0.0;
    lunchCalories = 0.0;
    dinnerCalories = 0.0;
    snacksCalories = 0.0;

    for (var m in dayMeals) {
      String type = m['mealType'];
      double totalCalories = m['totalCalories'] ?? 0.0;
      List<Map<String, dynamic>> meals = (m['meals'] as List<dynamic>)
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      switch (type) {
        case 'breakfast':
          breakfastArr = meals;
          breakfastCalories = totalCalories;
          break;
        case 'lunch':
          lunchArr = meals;
          lunchCalories = totalCalories;
          break;
        case 'dinner':
          dinnerArr = meals;
          dinnerCalories = totalCalories;
          break;
        case 'snacks':
          snacksArr = meals;
          snacksCalories = totalCalories;
          break;
      }
    }

    Map<String, double> dailyNutrition = {
      "calories": 0.0,
      "protein": 0.0,
      "fat": 0.0,
      "carb": 0.0,
    };

    for (var mealGroup in [breakfastArr, lunchArr, dinnerArr, snacksArr]) {
      for (var meal in mealGroup) {
        final nutri = Map<String, dynamic>.from(meal['nutri'] ?? {});

        dailyNutrition['calories'] = dailyNutrition['calories']! +
            (meal['totalCalories'] ?? 0).toDouble();
        dailyNutrition['protein'] =
            dailyNutrition['protein']! + (meal['totalProtein'] ?? 0).toDouble();
        dailyNutrition['fat'] =
            dailyNutrition['fat']! + (meal['totalFat'] ?? 0).toDouble();
        dailyNutrition['carb'] =
            dailyNutrition['carb']! + (meal['totalCarb'] ?? 0).toDouble();
      }
    }

    nutritionArr = [
      {
        "title": "Calories",
        "image": "assets/img/burn.png",
        "unit_name": "kCal",
        "value": dailyNutrition["calories"]!.toStringAsFixed(0),
        "max_value": cals.toStringAsFixed(0),
      },
      {
        "title": "Proteins",
        "image": "assets/img/proteins.png",
        "unit_name": "g",
        "value": dailyNutrition["protein"]!.toStringAsFixed(0),
        "max_value": protein.toStringAsFixed(0),
      },
      {
        "title": "Fats",
        "image": "assets/img/egg.png",
        "unit_name": "g",
        "value": dailyNutrition["fat"]!.toStringAsFixed(0),
        "max_value": fat.toStringAsFixed(0),
      },
      {
        "title": "Carb",
        "image": "assets/img/carbo.png",
        "unit_name": "g",
        "value": dailyNutrition["carb"]!.toStringAsFixed(0),
        "max_value": carb.toStringAsFixed(0),
      },
    ];

    setState(() {});
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
          onTap: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const MealPlannerView(),
              ),
            );
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
          "Meal  Schedule",
          style: TextStyle(
              color: TColor.black, fontSize: 22, fontWeight: FontWeight.w700),
        ),
      ),
      backgroundColor: TColor.white,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CalendarAgenda(
            controller: _calendarAgendaControllerAppBar,
            appbar: false,
            selectedDayPosition: SelectedDayPosition.center,
            leading: IconButton(
                onPressed: () {},
                icon: Image.asset(
                  "assets/img/ArrowLeft.png",
                  width: 15,
                  height: 15,
                )),
            training: IconButton(
                onPressed: () {},
                icon: Image.asset(
                  "assets/img/ArrowRight.png",
                  width: 15,
                  height: 15,
                )),
            weekDay: WeekDay.short,
            dayNameFontSize: 12,
            dayNumberFontSize: 16,
            dayBGColor: Colors.grey.withOpacity(0.15),
            titleSpaceBetween: 15,
            backgroundColor: Colors.transparent,
            // fullCalendar: false,
            fullCalendarScroll: FullCalendarScroll.horizontal,
            fullCalendarDay: WeekDay.short,
            selectedDateColor: Colors.white,
            dateColor: Colors.black,
            locale: 'en',

            initialDate: DateTime.now(),
            calendarEventColor: TColor.primaryColor2,
            firstDate: DateTime.now().subtract(const Duration(days: 140)),
            lastDate: DateTime.now().add(const Duration(days: 60)),

            onDateSelected: (date) {
              _selectedDateAppBBar = date;
              _setDayMealList();
            },
            selectedDayLogo: Container(
              width: double.maxFinite,
              height: double.maxFinite,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                    colors: TColor.primaryG,
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter),
                borderRadius: BorderRadius.circular(10.0),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "BreakFast",
                          style: TextStyle(
                              color: TColor.black,
                              fontSize: 16,
                              fontWeight: FontWeight.w700),
                        ),
                        TextButton(
                          onPressed: () {},
                          child: Text(
                            "${breakfastArr.length} Items | ${breakfastCalories.toStringAsFixed(0)} kCal",
                            style: TextStyle(color: TColor.gray, fontSize: 12),
                          ),
                        )
                      ],
                    ),
                  ),
                  breakfastArr.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            child: Text(
                              "Not Scheduled",
                              style:
                                  TextStyle(fontSize: 13, color: Colors.grey),
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 15),
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          itemCount: breakfastArr.length,
                          itemBuilder: (context, index) {
                            var mObj = breakfastArr[index] as Map? ?? {};
                            return InkWell(
                              onTap: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => EditMealScheduleView(
                                      bObj: mObj,
                                    ),
                                  ),
                                );
                                if (result == true) {
                                  _loadMealSchedule();
                                }
                              },
                              child: MealFoodScheduleRow(
                                mObj: mObj,
                                index: index,
                              ),
                            );
                          }),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Lunch",
                          style: TextStyle(
                              color: TColor.black,
                              fontSize: 16,
                              fontWeight: FontWeight.w700),
                        ),
                        TextButton(
                          onPressed: () {},
                          child: Text(
                            "${lunchArr.length} Items | ${lunchCalories.toStringAsFixed(0)} kCal",
                            style: TextStyle(color: TColor.gray, fontSize: 12),
                          ),
                        )
                      ],
                    ),
                  ),
                  lunchArr.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            child: Text(
                              "Not Scheduled",
                              style:
                                  TextStyle(fontSize: 13, color: Colors.grey),
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 15),
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          itemCount: lunchArr.length,
                          itemBuilder: (context, index) {
                            var mObj = lunchArr[index] as Map? ?? {};
                            return InkWell(
                              onTap: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => EditMealScheduleView(
                                      bObj: mObj,
                                    ),
                                  ),
                                );
                                if (result == true) {
                                  _loadMealSchedule();
                                }
                              },
                              child: MealFoodScheduleRow(
                                mObj: mObj,
                                index: index,
                              ),
                            );
                          }),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Dinner",
                          style: TextStyle(
                              color: TColor.black,
                              fontSize: 16,
                              fontWeight: FontWeight.w700),
                        ),
                        TextButton(
                          onPressed: () {},
                          child: Text(
                            "${dinnerArr.length} Items | ${dinnerCalories.toStringAsFixed(0)} kCal",
                            style: TextStyle(color: TColor.gray, fontSize: 12),
                          ),
                        )
                      ],
                    ),
                  ),
                  dinnerArr.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            child: Text(
                              "Not Scheduled",
                              style:
                                  TextStyle(fontSize: 13, color: Colors.grey),
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 15),
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          itemCount: dinnerArr.length,
                          itemBuilder: (context, index) {
                            var mObj = dinnerArr[index] as Map? ?? {};
                            return InkWell(
                              onTap: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => EditMealScheduleView(
                                      bObj: mObj,
                                    ),
                                  ),
                                );
                                if (result == true) {
                                  _loadMealSchedule();
                                }
                              },
                              child: MealFoodScheduleRow(
                                mObj: mObj,
                                index: index,
                              ),
                            );
                          }),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Snacks",
                          style: TextStyle(
                              color: TColor.black,
                              fontSize: 16,
                              fontWeight: FontWeight.w700),
                        ),
                        TextButton(
                          onPressed: () {},
                          child: Text(
                            "${snacksArr.length} Items | ${snacksCalories.toStringAsFixed(0)} kCal",
                            style: TextStyle(color: TColor.gray, fontSize: 12),
                          ),
                        )
                      ],
                    ),
                  ),
                  snacksArr.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            child: Text(
                              "Not Scheduled",
                              style:
                                  TextStyle(fontSize: 13, color: Colors.grey),
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 15),
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          itemCount: snacksArr.length,
                          itemBuilder: (context, index) {
                            var mObj = snacksArr[index] as Map? ?? {};
                            return InkWell(
                              onTap: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => EditMealScheduleView(
                                      bObj: mObj,
                                    ),
                                  ),
                                );
                                if (result == true) {
                                  _loadMealSchedule();
                                }
                              },
                              child: MealFoodScheduleRow(
                                mObj: mObj,
                                index: index,
                              ),
                            );
                          }),
                  SizedBox(
                    height: media.width * 0.05,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Nutritions Of The Day",
                          style: TextStyle(
                              color: TColor.black,
                              fontSize: 16,
                              fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                  ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      itemCount: nutritionArr.length,
                      itemBuilder: (context, index) {
                        var nObj = nutritionArr[index] as Map? ?? {};
                        return NutritionRow(
                          nObj: nObj,
                        );
                      }),
                  SizedBox(
                    height: media.width * 0.12,
                  )
                ],
              ),
            ),
          )
        ],
      ),
      floatingActionButton: InkWell(
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  AddMealScheduleView(date: _selectedDateAppBBar),
            ),
          );
          if (result == true) {
            _loadMealSchedule();
          }
        },
        child: Container(
          width: 55,
          height: 55,
          decoration: BoxDecoration(
              gradient: LinearGradient(colors: TColor.secondaryG),
              borderRadius: BorderRadius.circular(27.5),
              boxShadow: const [
                BoxShadow(
                    color: Colors.black12, blurRadius: 5, offset: Offset(0, 2))
              ]),
          alignment: Alignment.center,
          child: Icon(
            Icons.add,
            size: 20,
            color: TColor.white,
          ),
        ),
      ),
    );
  }
}

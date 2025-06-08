import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../common/colo_extension.dart';
import '../../common/nutrition_calculator.dart';
import '../../common_widget/delete_button.dart';
import '../../common_widget/icon_edit_food_row.dart';
import '../../common_widget/icon_title_next_row.dart';
import '../../common_widget/round_button.dart';
import '../../localization/app_localizations.dart';
import '../../main.dart';
import '../../model/meal_model.dart';
import '../../model/simple_meal_model.dart';
import '../../model/user_model.dart';
import '../../services/auth_services.dart';
import '../../services/meal_services.dart';
import '../../services/notification_services.dart';

class EditMealScheduleView extends StatefulWidget {
  final Map bObj;
  const EditMealScheduleView({super.key, required this.bObj});

  @override
  State<EditMealScheduleView> createState() => _EditMealScheduleViewState();
}

class _EditMealScheduleViewState extends State<EditMealScheduleView> {
  TextEditingController selectedMealType = TextEditingController();
  final MealService _mealService = MealService();
  final NotificationServices _notificationServices = NotificationServices();
  Meal selectedFood = Meal.empty();
  final inputFormat = DateFormat('yyyy-MM-dd');

  DateTime date = DateTime.now();

  bool isNotificationEnabled = true;
  String selectedTime = "";
  bool isLoading = false;
  bool isHide = false;

  File? selectedImage;
  bool darkmode = darkModeNotifier.value;

  double tdee = 1;
  double cals = 1;

  @override
  void initState() {
    super.initState();
    _getUser();
    // Kiểm tra nếu là String thì parse, còn nếu là DateTime thì gán trực tiếp
    final rawDate = widget.bObj['date'];
    if (rawDate is String) {
      date = inputFormat.parse(rawDate);
    } else if (rawDate is DateTime) {
      date = rawDate;
    }
    selectedMealType.text = widget.bObj['mealType'] ?? '';
    selectedTime = widget.bObj['time'] ?? '';
    isNotificationEnabled = widget.bObj['notify'] ?? true;
    _checkHideNotify();
    _loadMealDetail();
  }

  @override
  void dispose() {
    super.dispose();
    selectedMealType.dispose();
  }

  void _loadMealDetail() async {
    String name = widget.bObj['name'];
    List<dynamic> ingredientRawList = widget.bObj['ingredients'];
    Meal loadMeal = await _mealService.getMealWithScheduledIngredients(
        name, ingredientRawList);
    setState(() {
      selectedFood = loadMeal;
    });
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
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi xảy ra: $e')),
      );
    }
  }

  void _checkHideNotify() async {
    String check = await _mealService.checkMealSchedule(
      date: date,
      mealType: selectedMealType.text,
      hour: selectedTime,
    );
    if (check == 'fail') {
      setState(() {
        isHide = true;
        isNotificationEnabled = false;
      });
    }
  }

  Future<void> _handleEditMealSchedule() async {
    if (selectedFood.name.isEmpty ||
        selectedTime == '' ||
        selectedMealType.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Vui lòng nhập đầy đủ thông tin")),
      );
      return;
    }
    String check = await _mealService.checkMealSchedule(
      date: date,
      mealType: selectedMealType.text,
      hour: selectedTime,
    );
    if (check != 'pass' && check != 'fail') {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(check)));
      return;
    }
    setState(() {
      isLoading = true;
    });

    final uid = FirebaseAuth.instance.currentUser!.uid;

    // Tính calo mới
    double newCalories = selectedFood.ingredients.fold<double>(
      0.0,
      (sum, ing) => sum + (ing.amount * (ing.nutri.values['calories'] ?? 0.0)),
    );

    double newCarb = selectedFood.ingredients.fold<double>(
      0.0,
      (sum, ing) => sum + (ing.amount * (ing.nutri.values['carb'] ?? 0.0)),
    );

    double newFat = selectedFood.ingredients.fold<double>(
      0.0,
      (sum, ing) => sum + (ing.amount * (ing.nutri.values['fat'] ?? 0.0)),
    );

    double newProtein = selectedFood.ingredients.fold<double>(
      0.0,
      (sum, ing) => sum + (ing.amount * (ing.nutri.values['protein'] ?? 0.0)),
    );

    // Lấy tổng calories trong ngày
    double totalCaloriesSoFar = await _mealService.getTotalCaloriesInDay(
      uid: uid,
      date: date,
    );

    // Trừ đi calo của món cũ đang chỉnh sửa
    double oldCalories = widget.bObj['totalCalories'].toDouble();
    double adjustedCalories = totalCaloriesSoFar - oldCalories + newCalories;

    double allowedCalories = cals;

    // Nếu vượt mức thì cảnh báo
    if (adjustedCalories > allowedCalories) {
      bool proceed = await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Vượt quá mức calo khuyến nghị'),
          content: Text(
              'Món ăn sau khi chỉnh sửa sẽ vượt quá $allowedCalories kcal. Bạn có chắc chắn muốn tiếp tục?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Huỷ'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('Tiếp tục'),
            ),
          ],
        ),
      );
      if (!proceed) {
        setState(() {
          isLoading = false;
        });
        return;
      }
    }

    String idNotify = widget.bObj['id_notify'];
    await _notificationServices.cancelNotificationById(int.parse(idNotify));
    await _notificationServices.removeMealNotifications(idNotify);

    if (isNotificationEnabled) {
      final DateFormat hourFormat = DateFormat('hh:mm a');
      DateTime selectedDay = date;
      DateTime selectedHour = hourFormat.parse(selectedTime);

      DateTime selectedDateTime = DateTime(
        selectedDay.year,
        selectedDay.month,
        selectedDay.day,
        selectedHour.hour,
        selectedHour.minute,
      );
      String id = selectedFood.name + selectedDateTime.toString();

      idNotify = await _notificationServices.scheduleMealNotification(
        id: id,
        mealType: selectedMealType.text,
        Time: selectedDateTime,
        Name: selectedFood.name,
        pic: selectedFood.image,
      );
    }

    SimpleMeal updatedMeal = SimpleMeal(
      name: selectedFood.name,
      image: selectedFood.image,
      totalCalories: newCalories,
      totalCarb: newCarb,
      totalFat: newFat,
      totalProtein: newProtein,
      time: selectedTime,
      notify: isNotificationEnabled,
      id_notify: idNotify,
      ingredients: selectedFood.ingredients,
    );

    // Gọi API chỉnh sửa
    final result = await _mealService.updateMealSchedule(
      uid: FirebaseAuth.instance.currentUser!.uid,
      date: date,
      mealType: selectedMealType.text.toLowerCase(),
      meal: updatedMeal,
    );

    setState(() {
      isLoading = false;
    });

    if (result != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(result)));
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Chỉnh sửa bữa ăn thành công")));
      Navigator.pop(context, true);
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    TimeOfDay initialTime = TimeOfDay.now();
    if (selectedTime.isNotEmpty) {
      final DateTime parsedTime = DateFormat('hh:mm a').parse(selectedTime);
      initialTime = TimeOfDay(hour: parsedTime.hour, minute: parsedTime.minute);
    }

    TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (BuildContext context, Widget? child) {
        return Localizations.override(
          context: context,
          locale: const Locale('en', 'US'),
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
            child: child!,
          ),
        );
      },
    );

    if (pickedTime != null) {
      final now = DateTime.now();

      final formattedTime = DateFormat('hh:mm a').format(
        DateTime(
            now.year, now.month, now.day, pickedTime.hour, pickedTime.minute),
      );

      setState(() {
        selectedTime = formattedTime;
      });
    }
  }

  Future<void> _handleDeleteMeal() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Xác nhận xoá'),
        content: Text(
            'Bạn có chắc chắn muốn xoá món "${widget.bObj['name']}" khỏi lịch không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Huỷ'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Xoá'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      isLoading = true;
    });

    final result = await _mealService.deleteMealFromSchedule(
      uid: FirebaseAuth.instance.currentUser!.uid,
      date: date,
      mealType: selectedMealType.text.toLowerCase(),
      mealName: widget.bObj['name'],
      id_notify: widget.bObj['id_notify'],
    );

    setState(() {
      isLoading = false;
    });

    if (result != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(result)));
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Xoá món ăn thành công')));
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: darkmode ? Colors.blueGrey[900] : TColor.white,
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
              "assets/img/closed_btn.png",
              width: 15,
              height: 15,
              fit: BoxFit.contain,
            ),
          ),
        ),
        title: Text(
          AppLocalizations.of(context)?.translate("Edit Meal Schedule") ??
              "Edit Meal Schedule",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Date: ${DateFormat('E, dd MMM yyyy').format(date)}"),
                SizedBox(
                  height: media.width * 0.03,
                ),
                InkWell(
                  onTap: () {},
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 15),
                    decoration: BoxDecoration(
                      color: TColor.lightGray.withOpacity(
                          0.3), // Nhạt hơn để tạo cảm giác bị vô hiệu
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
                            color: Colors.grey, // Làm xám icon
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            AppLocalizations.of(context)
                                    ?.translate("Meal Type") ??
                                "Meal Type",
                            style: TextStyle(
                                color: Colors.grey.shade600, fontSize: 12),
                          ),
                        ),
                        SizedBox(
                          width: 120,
                          child: Text(
                            selectedMealType.text,
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(
                  height: media.width * 0.03,
                ),
                IconTitleNextRow(
                  icon: "assets/img/clock_icon.png",
                  title: AppLocalizations.of(context)?.translate(
                        "Time",
                      ) ??
                      "Time",
                  time: selectedTime,
                  color: TColor.lightGray,
                  onPressed: () => _selectTime(context),
                ),
                SizedBox(
                  height: media.width * 0.03,
                ),
                IconEditFoodRow(
                  icon: "assets/img/choose_food_icon.png",
                  title: AppLocalizations.of(context)
                          ?.translate("Choose Food/Beverage") ??
                      "Choose Food/Beverage",
                  selectedMeal: selectedFood, // đối tượng Meal cần chỉnh sửa
                  color: TColor.lightGray, // màu nền
                  onIngredientAmountChanged: (ingredientIndex, newAmount) {
                    setState(() {
                      selectedFood.ingredients[ingredientIndex].amount =
                          newAmount;
                    });
                  },
                ),
                // RepetitionsRow(
                //   icon: "assets/img/Repeat.png",
                //   title: AppLocalizations.of(context)?.translate(
                //       "Custom Repetitions") ?? "Custom Repetitions",
                //   color: TColor.lightGray,
                //   repetitionController: selectedRepetition,
                // ),
                // SizedBox(
                //   height: media.width * 0.03,
                // ),
                Visibility(
                  visible: !isHide,
                  child: Column(
                    children: [
                      SizedBox(height: media.width * 0.03),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            AppLocalizations.of(context)
                                    ?.translate("Enable Notifications") ??
                                "Enable Notifications",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Switch(
                            value: isNotificationEnabled,
                            activeColor: TColor.primaryColor1,
                            onChanged: (value) {
                              setState(() {
                                isNotificationEnabled = value;
                              });
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
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
                    child: Column(
                      children: [
                        RoundButton(
                          title:
                              AppLocalizations.of(context)?.translate("Save") ??
                                  "Save",
                          onPressed: _handleEditMealSchedule,
                        ),
                        SizedBox(height: media.width * 0.03),
                        DeleteButton(
                          title: AppLocalizations.of(context)
                                  ?.translate("Delete") ??
                              "Delete",
                          onPressed: _handleDeleteMeal,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedOpacity(
            opacity: isLoading ? 1.0 : 0.0,
            duration: Duration(milliseconds: 300),
            child: IgnorePointer(
              ignoring: !isLoading,
              child: Container(
                color: Colors.black.withOpacity(0.5),
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

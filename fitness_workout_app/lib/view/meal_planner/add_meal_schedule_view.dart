import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitness_workout_app/services/roboflow_service.dart';
import 'package:fitness_workout_app/view/meal_planner/select_meal_food_view.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../common/colo_extension.dart';
import '../../common/nutrition_calculator.dart';
import '../../common_widget/icon_select_food_row.dart';
import '../../common_widget/icon_title_next_row.dart';
import '../../common_widget/round_button.dart';
import '../../localization/app_localizations.dart';
import '../../main.dart';
import '../../model/ingredient_model.dart';
import '../../model/meal_model.dart';
import '../../model/simple_meal_model.dart';
import '../../model/user_model.dart';
import '../../services/auth_services.dart';
import '../../services/meal_services.dart';
import '../../services/notification_services.dart';

class AddMealScheduleView extends StatefulWidget {
  final DateTime date;
  final Meal? initialMeal;
  final String? initialMealType;

  const AddMealScheduleView({
    super.key,
    required this.date,
    this.initialMeal,
    this.initialMealType,
  });

  @override
  State<AddMealScheduleView> createState() => _AddMealScheduleViewState();
}

class _AddMealScheduleViewState extends State<AddMealScheduleView> {
  final MealService _mealService = MealService();
  final NotificationServices _notificationServices = NotificationServices();
  List<Meal> selectedFoods = [];
  late final TextEditingController selectedMealType;

  bool isNotificationEnabled = true;
  String selectedTime = "";
  bool isLoading = false;
  //File? selectedImage;
  bool darkmode = darkModeNotifier.value;

  double tdee = 1;
  double cals = 1;

  @override
  void initState() {
    super.initState();
    _getUser();

    selectedMealType = TextEditingController(
      text: widget.initialMealType ?? '',
    );

    if (widget.initialMeal != null) {
      selectedFoods.add(widget.initialMeal!);
    }
  }

  @override
  void dispose() {
    selectedMealType.dispose();
    super.dispose();
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

  Future<void> _handleAddMealSchedule() async {
    if (selectedFoods.isEmpty ||
        selectedTime == '' ||
        selectedMealType.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Vui lòng nhập đầy đủ thông tin")),
      );
      return;
    }

    String check = await _mealService.checkMealSchedule(
      date: widget.date,
      mealType: selectedMealType.text,
      hour: selectedTime,
    );

    if (check != 'pass' && check != 'fail') {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(check)));
      return;
    } else if (check == 'fail') {
      setState(() {
        isNotificationEnabled = false;
      });
    }

    setState(() {
      isLoading = true;
    });

    // Tính tổng calories của các món mới
    double newCalories = selectedFoods.fold(0.0, (sum, meal) {
      return sum +
          meal.ingredients.fold(
              0.0,
              (s, ing) =>
                  s + (ing.amount * (ing.nutri.values['calories'] ?? 0.0)));
    });

    // Gọi dịch vụ kiểm tra tổng calories trong ngày
    double totalCaloriesSoFar = await _mealService.getTotalCaloriesInDay(
      uid: FirebaseAuth.instance.currentUser!.uid,
      date: widget.date,
    );

    double allowedCalories = cals;

    if (totalCaloriesSoFar + newCalories > allowedCalories) {
      bool proceed = await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Vượt quá mức calo khuyến nghị'),
          content: Text(
              'Món ăn sau khi thêm sẽ vượt quá $allowedCalories kcal. Bạn có chắc chắn muốn tiếp tục?'),
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

    // Kiểm tra xem món có phù hợp với bữa ăn không
    final incompatibleMeals = selectedFoods.where((meal) {
      return !(meal.recommend.contains(selectedMealType.text.toLowerCase()) ??
          true);
    }).toList();

    if (incompatibleMeals.isNotEmpty) {
      bool proceed = await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Món ăn không phù hợp'),
          content: Text(
            'Một số món không phù hợp cho bữa "${selectedMealType.text}":\n'
            '${incompatibleMeals.map((m) => "- ${m.name}").join("\n")}\n\nBạn có chắc muốn tiếp tục?',
          ),
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

    final simpleMeals = await Future.wait(selectedFoods.map((meal) async {
      final totalCal = meal.ingredients.fold<double>(
          0.0,
          (sum, ing) =>
              sum + (ing.amount * (ing.nutri.values['calories'] ?? 0.0)));

      final totalCarb = meal.ingredients.fold<double>(0.0,
          (sum, ing) => sum + (ing.amount * (ing.nutri.values['carb'] ?? 0.0)));

      final totalFat = meal.ingredients.fold<double>(0.0,
          (sum, ing) => sum + (ing.amount * (ing.nutri.values['fat'] ?? 0.0)));

      final totalProtein = meal.ingredients.fold<double>(
          0.0,
          (sum, ing) =>
              sum + (ing.amount * (ing.nutri.values['protein'] ?? 0.0)));

      String idNotify = '0';

      if (isNotificationEnabled) {
        final DateFormat hourFormat = DateFormat('hh:mm a');
        DateTime selectedDay = widget.date;
        DateTime selectedHour = hourFormat.parse(selectedTime);

        DateTime selectedDateTime = DateTime(
          selectedDay.year,
          selectedDay.month,
          selectedDay.day,
          selectedHour.hour,
          selectedHour.minute,
        );
        String id = meal.name + selectedDateTime.toString();

        idNotify = await _notificationServices.scheduleMealNotification(
          id: id,
          mealType: selectedMealType.text,
          Time: selectedDateTime,
          Name: meal.name,
          pic: meal.image,
        );
      }

      return SimpleMeal(
        name: meal.name,
        image: meal.image,
        totalCalories: totalCal,
        totalCarb: totalCarb,
        totalFat: totalFat,
        totalProtein: totalProtein,
        time: selectedTime,
        notify: isNotificationEnabled,
        id_notify: idNotify,
        ingredients: meal.ingredients,
      );
    }).toList());

    final result = await _mealService.addMealSchedule(
      uid: FirebaseAuth.instance.currentUser!.uid,
      date: widget.date,
      mealType: selectedMealType.text.toLowerCase(),
      meals: simpleMeals,
    );

    setState(() {
      isLoading = false;
    });

    if (result != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(result)));
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Thêm bữa ăn thành công")));
      Navigator.pop(context, true);
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(Icons.camera_alt),
            title: Text("Chụp ảnh"),
            onTap: () {
              Navigator.pop(context);
              _pickImage(ImageSource.camera);
            },
          ),
          ListTile(
            leading: Icon(Icons.photo),
            title: Text("Chọn từ thư viện"),
            onTap: () {
              Navigator.pop(context);
              _pickImage(ImageSource.gallery);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: source);

    if (image != null) {
      final file = File(image.path);
      setState(() {
        //selectedImage = file;
        isLoading = true;
      });

      final foodNames = await RoboflowService.detectFoodItems(file);

      if (foodNames.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Không nhận diện được món ăn nào")),
        );
        setState(() {
          isLoading = false;
        });
        return;
      }

      int addedCount = 0;

      for (final name in foodNames) {
        try {
          final futures = foodNames.map((name) =>
              // ignore: invalid_return_type_for_catch_error
              MealService().getMealByName(name).catchError((_) => null));
          final meals = await Future.wait(futures);
          for (final meal in meals) {
            if (!selectedFoods.any((m) => m.name == meal.name)) {
              setState(() {
                selectedFoods.add(meal);
              });
              addedCount++;
            }
          }
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Không tìm thấy món: $name")),
          );
          setState(() {
            isLoading = false;
          });
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                "Đã thêm $addedCount/${foodNames.length} món vào danh sách")),
      );
      setState(() {
        isLoading = false;
      });
    }
  }

  void _showMealTypeSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children:
                ["Breakfast", "Lunch", "Dinner", "Snacks"].map((mealtype) {
              return ListTile(
                title: Text(
                  AppLocalizations.of(context)?.translate(mealtype) ?? mealtype,
                  style: TextStyle(
                      color: darkmode ? TColor.white : TColor.black,
                      fontSize: 14),
                ),
                onTap: () {
                  setState(() {
                    selectedMealType.text = mealtype;
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
          AppLocalizations.of(context)?.translate("Add Meal Schedule") ??
              "Add Meal Schedule",
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
                Text(
                    "Date: ${DateFormat('E, dd MMM yyyy').format(widget.date)}"),
                SizedBox(
                  height: media.width * 0.03,
                ),
                InkWell(
                  onTap: () {
                    _showMealTypeSelector(context);
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 15),
                    decoration: BoxDecoration(
                      color: TColor.lightGray,
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
                                    ?.translate("Meal Type") ??
                                "Meal Type",
                            style: TextStyle(color: TColor.gray, fontSize: 12),
                          ),
                        ),
                        SizedBox(
                          width: 120,
                          child: Text(
                            selectedMealType.text,
                            textAlign: TextAlign.right,
                            style: TextStyle(color: TColor.gray, fontSize: 12),
                          ),
                        ),
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
                IconSelectFoodRow(
                  icon: "assets/img/choose_food_icon.png",
                  title: AppLocalizations.of(context)
                          ?.translate("Choose Food/Beverage") ??
                      "Choose Food/Beverage",
                  selectedMeals: selectedFoods,
                  color: TColor.lightGray,
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SelectMealFoodView(),
                      ),
                    );
                    if (result != null &&
                        result is Meal &&
                        !selectedFoods
                            .any((meal) => meal.name == result.name)) {
                      setState(() {
                        selectedFoods.add(result);
                      });
                    }
                  },
                  onRemove: (index) {
                    setState(() {
                      selectedFoods.removeAt(index);
                    });
                  },
                  onIngredientAmountChanged: (mealIndex, ingIndex, newAmount) {
                    setState(() {
                      final oldIng =
                          selectedFoods[mealIndex].ingredients[ingIndex];
                      selectedFoods[mealIndex].ingredients[ingIndex] =
                          Ingredient(
                        name: oldIng.name,
                        amount: newAmount,
                        unit: oldIng.unit,
                        image: oldIng.image,
                        nutri: oldIng.nutri,
                      );
                    });
                  },
                ),
                SizedBox(
                  height: media.width * 0.03,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppLocalizations.of(context)
                              ?.translate("Enable Notifications") ??
                          "Enable Notifications",
                      style: TextStyle(
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
                SizedBox(
                  height: media.width * 0.01,
                ),
                // Nút chọn ảnh và hiển thị ảnh đã chọn
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _showImageSourceDialog,
                      icon: const Icon(Icons.camera_alt_outlined, size: 28),
                      label: const Text("Automatic Food Recognition"),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        textStyle: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w500),
                        side:
                            BorderSide(color: TColor.secondaryColor1, width: 2),
                        foregroundColor: TColor.secondaryColor1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                    ),
                  ),
                )
                // SizedBox(
                //   height: media.width * 0.03,
                // ),
                // selectedImage != null
                //     ? Column(
                //         children: [
                //           ClipRRect(
                //             borderRadius: BorderRadius.circular(10),
                //             child: Image.file(
                //               selectedImage!,
                //               height: 400,
                //               width: double.infinity,
                //               fit: BoxFit.cover,
                //             ),
                //           ),
                //         ],
                //       )
                //     : SizedBox(height: media.width * 0.8),
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
                        title:
                            AppLocalizations.of(context)?.translate("Save") ??
                                "Save",
                        onPressed: _handleAddMealSchedule),
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

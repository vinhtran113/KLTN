import 'dart:io';
import 'package:fitness_workout_app/view/meal_planner/select_meal_food_view.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../common/colo_extension.dart';
import '../../common_widget/icon_select_food_row.dart';
import '../../common_widget/repetition_row.dart';
import '../../common_widget/round_button.dart';
import '../../localization/app_localizations.dart';
import '../../main.dart';
import '../../model/meal_model.dart';

class AddMealScheduleView extends StatefulWidget {
  final DateTime date;
  const AddMealScheduleView({super.key, required this.date});

  @override
  State<AddMealScheduleView> createState() => _AddMealScheduleViewState();
}

class _AddMealScheduleViewState extends State<AddMealScheduleView> {
  final TextEditingController selectedMealType = TextEditingController();
  final TextEditingController selectedFood = TextEditingController();
  final TextEditingController selectedDrink = TextEditingController();
  final TextEditingController selectedRepetition = TextEditingController(
      text: "no");
  List<Meal> selectedFoods = [];
  String hour = "";
  bool isNotificationEnabled = true;
  bool isLoading = false;
  File? selectedImage;
  bool darkmode = darkModeNotifier.value;

  @override
  void initState() {
    super.initState();
    hour = DateFormat('h:mm a').format(DateTime.now());
  }

  void _onTimeChanged(DateTime newDate) {
    setState(() {
      hour = DateFormat('h:mm a').format(newDate);
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: source);

    if (image != null) {
      setState(() {
        selectedImage = File(image.path);
      });

      // TODO: Gọi AI/Model để phân tích ảnh ở đây
      // Ví dụ: gửi ảnh tới API -> nhận lại tên món ăn / đồ uống -> set vào controller
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (_) =>
          Column(
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

  void _showSelectionDialog(
      {required String title, required TextEditingController controller, required List<
          String> options}) {
    showModalBottomSheet(
      context: context,
      builder: (_) =>
          Column(
            mainAxisSize: MainAxisSize.min,
            children: options.map((item) {
              return ListTile(
                title: Text(item),
                onTap: () {
                  controller.text = item;
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ),
    );
  }

  void _handleAddMealSchedule() async {
    setState(() => isLoading = true);
    await Future.delayed(Duration(seconds: 2)); // Giả lập loading
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Meal scheduled successfully")));
    Navigator.pop(context, true);
    setState(() => isLoading = false);
  }

  void _showMealTypeSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: ["Breakfast", "Lunch", "Dinner", "Snack"].map((mealtype) {
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
    var media = MediaQuery
        .of(context)
        .size;
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
                Text("Date: ${DateFormat('E, dd MMM yyyy').format(
                    widget.date)}"),
                SizedBox(
                  height: media.width * 0.03,
                ),
                InkWell(
                  onTap: () {
                    _showMealTypeSelector(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 8, horizontal: 15),
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
                            AppLocalizations.of(context)?.translate(
                                "Meal Type") ?? "Meal Type",
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
                IconSelectFoodRow(
                  icon: "assets/img/choose_workout.png",
                  title: AppLocalizations.of(context)?.translate(
                      "Choose Food/Beverage") ?? "Choose Food/Beverage",
                  selectedMeals: selectedFoods,
                  color: TColor.lightGray,
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SelectMealFoodView(),
                      ),
                    );
                    if (result != null && result is Meal &&
                        !selectedFoods.any((meal) => meal.name ==
                            result.name)) {
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
                      selectedFoods[mealIndex].ingredients[ingIndex] =
                          Ingredient(
                            name: selectedFoods[mealIndex].ingredients[ingIndex]
                                .name,
                            amount: newAmount,
                            unit: selectedFoods[mealIndex].ingredients[ingIndex]
                                .unit,
                            image: selectedFoods[mealIndex]
                                .ingredients[ingIndex].image,
                          );
                    });
                  },
                ),
                SizedBox(
                  height: media.width * 0.03,
                ),
                RepetitionsRow(
                  icon: "assets/img/Repeat.png",
                  title: AppLocalizations.of(context)?.translate(
                      "Custom Repetitions") ?? "Custom Repetitions",
                  color: TColor.lightGray,
                  repetitionController: selectedRepetition,
                ),
                SizedBox(
                  height: media.width * 0.03,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppLocalizations.of(context)?.translate(
                          "Enable Notifications") ?? "Enable Notifications",
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
                OutlinedButton.icon(
                  onPressed: _showImageSourceDialog,
                  icon: Icon(Icons.camera_alt_outlined),
                  label: Text("Chụp hoặc chọn ảnh món ăn"),
                ),
                SizedBox(height: media.width * 0.03,),
                selectedImage != null ? Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.file(
                        selectedImage!,
                        height: 400,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    SizedBox(height: media.width * 0.03),
                  ],
                ) : SizedBox(height: media.width * 0.85),
                RoundButton(
                    title: AppLocalizations.of(context)?.translate("Save") ?? "Save",
                    onPressed: _handleAddMealSchedule
                ),
                const SizedBox(
                  height: 20,
                ),
              ],
            ),
          ),
          if (isLoading)
            Container(
              color: Colors.black.withOpacity(0.4),
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}

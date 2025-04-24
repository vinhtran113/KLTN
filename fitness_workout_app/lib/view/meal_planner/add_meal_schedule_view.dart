import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

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
  final TextEditingController selectedRepetition = TextEditingController(text: "no");
  String hour = "";
  bool isNotificationEnabled = true;
  bool isLoading = false;
  File? selectedImage;

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

  void _showSelectionDialog({required String title, required TextEditingController controller, required List<String> options}) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Column(
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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Meal scheduled successfully")));
    Navigator.pop(context, true);
    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        title: Text("Add Meal Schedule"),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Date: ${DateFormat('E, dd MMM yyyy').format(widget.date)}"),
                SizedBox(height: 20),
                ListTile(
                  tileColor: Colors.grey.shade200,
                  title: Text("Meal Type"),
                  subtitle: Text(selectedMealType.text.isEmpty ? "Select meal" : selectedMealType.text),
                  onTap: () => _showSelectionDialog(
                    title: "Meal Type",
                    controller: selectedMealType,
                    options: ["Breakfast", "Lunch", "Dinner", "Snack"],
                  ),
                ),
                SizedBox(height: 10),
                ListTile(
                  tileColor: Colors.grey.shade200,
                  title: Text("Food"),
                  subtitle: Text(selectedFood.text.isEmpty ? "Choose food" : selectedFood.text),
                  onTap: () => _showSelectionDialog(
                    title: "Select Food",
                    controller: selectedFood,
                    options: ["Rice", "Noodles", "Salad", "Grilled Chicken"],
                  ),
                ),
                SizedBox(height: 10),
                ListTile(
                  tileColor: Colors.grey.shade200,
                  title: Text("Drink"),
                  subtitle: Text(selectedDrink.text.isEmpty ? "Choose drink" : selectedDrink.text),
                  onTap: () => _showSelectionDialog(
                    title: "Select Drink",
                    controller: selectedDrink,
                    options: ["Water", "Juice", "Tea", "Coffee"],
                  ),
                ),
                SizedBox(height: 10),
                ListTile(
                  tileColor: Colors.grey.shade200,
                  title: Text("Repeat"),
                  subtitle: Text(selectedRepetition.text),
                  onTap: () => _showSelectionDialog(
                    title: "Repetition",
                    controller: selectedRepetition,
                    options: ["no", "Everyday", "Weekdays", "Weekends"],
                  ),
                ),
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Enable Notification"),
                    Switch(
                      value: isNotificationEnabled,
                      onChanged: (val) => setState(() => isNotificationEnabled = val),
                    ),
                  ],
                ),
                SizedBox(height: 10),

                // ✅ Nút chọn ảnh và hiển thị ảnh đã chọn
                OutlinedButton.icon(
                  onPressed: _showImageSourceDialog,
                  icon: Icon(Icons.camera_alt_outlined),
                  label: Text("Chụp hoặc chọn ảnh món ăn"),
                ),
                SizedBox(height: 10),
                if (selectedImage != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(
                      selectedImage!,
                      height: 150,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                const Spacer(),
                ElevatedButton(
                  onPressed: _handleAddMealSchedule,
                  style: ElevatedButton.styleFrom(minimumSize: Size.fromHeight(50)),
                  child: Text("Save"),
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

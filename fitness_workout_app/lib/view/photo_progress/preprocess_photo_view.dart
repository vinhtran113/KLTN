import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

import '../../common/colo_extension.dart';
import '../../common_widget/GenderDropdown.dart';
import '../../common_widget/icon_title_next_row_2.dart';
import '../../common_widget/round_button.dart';
import '../../common_widget/round_textfield.dart';
import '../../common_widget/selectDate.dart';
import '../../localization/app_localizations.dart';
import '../../main.dart';
import '../../model/user_model.dart';
import '../../services/auth_services.dart';
import '../../services/photo_service.dart';
import '../main_tab/main_tab_view.dart';
import '../profile/change_body_fat_view.dart';

class PreprocessPhotoView extends StatefulWidget {
  final File imageFile;
  final String userHeight;
  final String userWeight;
  final String userBodyFat;

  const PreprocessPhotoView({super.key,required this.imageFile, required this.userHeight, required this.userWeight, required this.userBodyFat});

  @override
  State<PreprocessPhotoView> createState() => _PreprocessPhotoViewState();
}

class _PreprocessPhotoViewState extends State<PreprocessPhotoView> {
  late TextEditingController heightController;
  late TextEditingController weightController;
  late TextEditingController bodyFatController;
  bool darkmode = darkModeNotifier.value;
  bool isLoading = false;
  final TextEditingController selectedStyle = TextEditingController();
  TextEditingController selectDateController = TextEditingController();
  Timestamp? selectedDate;

  @override
  void initState() {
    super.initState();
    selectedStyle.text = "";
    heightController = TextEditingController(text: widget.userHeight.toString());
    weightController = TextEditingController(text: widget.userWeight.toString());
    bodyFatController = TextEditingController(text: widget.userBodyFat.toString());
    // Gán ngày hôm nay cho controller
    DateTime now = DateTime.now();
    selectDateController.text = "${now.day}/${now.month}/${now.year}";

    // Gán Timestamp hiện tại
    selectedDate = Timestamp.fromDate(DateTime(now.year, now.month, now.day));
  }

  @override
  void dispose() {
    heightController.dispose();
    weightController.dispose();
    bodyFatController.dispose();
    super.dispose();
  }

  Future<String> uploadImageToFirebase(File imageFile) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final fileName = DateTime.now().millisecondsSinceEpoch.toString();
    final ref = FirebaseStorage.instance.ref().child("body_progress/$uid/$fileName.jpg");
    final downloadUrl = await ref.getDownloadURL();
    return downloadUrl;
  }

  Future<void> _saveData() async {
    setState(() {
      isLoading = true;
    });
    final result = await PhotoService.savePhoto(
      context: context,
      uid: FirebaseAuth.instance.currentUser!.uid,
      imageFile: widget.imageFile,
      weight: weightController.text,
      height: heightController.text,
      bodyFat: bodyFatController.text,
      style: selectedStyle.text,
        date: selectedDate!
    );

    if (result != "success") {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result)));
      setState(() {
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
      _getUserInfo();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Photo saved & information updated successfully')),
      );
    }
  }

  void _getUserInfo() async {
    try {
      UserModel? user = await AuthService().getUserInfo(
          FirebaseAuth.instance.currentUser!.uid);

      if (user != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => MainTabView(user: user, initialTab: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An error occurred.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: $e')),
      );
    }
  }

  void exit() async {
      bool? shouldSave = await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text("Photo not saved"),
          content: Text("You do not want to save this image?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text("Exit"),
            ),
          ],
        ),
      );
      if (shouldSave == true) {
        Navigator.pop(context);
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
          onTap: exit,
          child: Container(
            margin: const EdgeInsets.all(8),
            height: 40,
            width: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: TColor.lightGray,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Image.asset(
              "assets/img/closed_btn.png",
              width: 15,
              height: 15,
              fit: BoxFit.contain,
            ),
          ),
        ),
        title: Text(
          AppLocalizations.of(context)?.translate("Add Your Progress") ?? "Add Your Progress",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                Image.file(widget.imageFile, height: 500, fit: BoxFit.cover),
                SizedBox(height: media.width * 0.05),
                InkWell(
                  onTap: () async {
                    final pickedTimestamp =
                    await DatePickerHelper.selectDate2(context, selectDateController);
                    if (pickedTimestamp != null) {
                      setState(() {
                        selectedDate = pickedTimestamp; // dùng biến này để lưu vào Firestore
                      });
                    }
                  },
                  child: IgnorePointer(
                    child: RoundTextField(
                      controller: selectDateController,
                      labelText: "Date",
                      icon: "assets/img/date.png",
                    ),
                  ),
                ),
                SizedBox(height: media.width * 0.04),
                GenderDropdown(
                  icon: "assets/img/difficulity.png",
                  labelText:"Choose Style",
                  options: ["Front Facing", "Back Facing", "Left Facing", "Right Facing"],
                  controller: selectedStyle,
                ),
                SizedBox(height: media.width * 0.04),
                Row(
                  children: [
                    Expanded(
                      child: RoundTextField(
                        controller: weightController,
                        labelText: AppLocalizations.of(context)?.translate("Your Weight") ?? "Your Weight",
                        icon: "assets/img/weight.png",
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 50,
                      height: 50,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: TColor.secondaryG),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Text("KG", style: TextStyle(color: TColor.white, fontSize: 12)),
                    ),
                  ],
                ),
                SizedBox(height: media.width * 0.04),
                Row(
                  children: [
                    Expanded(
                      child: RoundTextField(
                        controller: heightController,
                        labelText: AppLocalizations.of(context)?.translate("Your Height") ?? "Your Height",
                        icon: "assets/img/hight.png",
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 50,
                      height: 50,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: TColor.secondaryG),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Text("CM", style: TextStyle(color: TColor.white, fontSize: 12)),
                    ),
                  ],
                ),
                SizedBox(height: media.width * 0.04),
                IconTitleNextRow2(
                  icon: "assets/img/body_icon.png",
                  title: AppLocalizations.of(context)?.translate("Body Fat(%)") ?? "Body Fat(%)",
                  time: bodyFatController.text,
                  color: TColor.lightGray,
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChangeBodyFatView(value: bodyFatController.text),
                      ),
                    );
                    if (result != null && result is String) {
                      setState(() {
                        bodyFatController.text = result;
                      });
                    }
                  },
                ),
                SizedBox(height: media.width * 0.1),
                RoundButton(
                  title: AppLocalizations.of(context)?.translate("Save") ?? "Save",
                  onPressed: _saveData,
                ),
              ],
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

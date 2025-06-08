import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:fitness_workout_app/common/colo_extension.dart';
import 'package:fitness_workout_app/common_widget/icon_title_next_row_2.dart';
import 'package:fitness_workout_app/view/main_tab/main_tab_view.dart';
import 'package:fitness_workout_app/view/profile/change_activity_level_view.dart';
import 'package:fitness_workout_app/view/profile/change_body_fat_view.dart';
import 'package:fitness_workout_app/view/profile/change_medical_history_view.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../common_widget/GenderDropdown.dart';
import '../../common_widget/round_button.dart';
import '../../common_widget/round_textfield.dart';
import '../../common_widget/round_textfield_2.dart';
import '../../common_widget/selectDate.dart';
import '../../model/user_model.dart';
import '../../services/auth_services.dart';
import 'change_goal_view.dart';
import 'change_password_view.dart';
import '../../main.dart';
import '../../localization/app_localizations.dart';

class EditProfileView extends StatefulWidget {
  final UserModel user;
  const EditProfileView({super.key, required this.user});
  @override
  State<EditProfileView> createState() => _EditProfileViewState();
}

class _EditProfileViewState extends State<EditProfileView> {
  final TextEditingController selectDate = TextEditingController();
  final TextEditingController selectedGender = TextEditingController();
  final TextEditingController selectWeight = TextEditingController();
  final TextEditingController selectHeight = TextEditingController();
  final TextEditingController fnameController = TextEditingController();
  final TextEditingController lnameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passController = TextEditingController();
  final TextEditingController selectedGoal = TextEditingController();
  final TextEditingController selectedActivityLevel = TextEditingController();
  final TextEditingController selectedBodyFat = TextEditingController();
  String currentPic = '';
  final ImagePicker _picker = ImagePicker();

  bool isLoading = false;
  bool darkmode = darkModeNotifier.value;
  late Map<String, String> initialData;

  @override
  void initState() {
    super.initState();
    fnameController.text = widget.user.fname;
    lnameController.text = widget.user.lname;
    selectWeight.text = widget.user.weight;
    selectHeight.text = widget.user.height;
    selectDate.text = widget.user.dateOfBirth;
    selectedGender.text = widget.user.gender;
    emailController.text = widget.user.email;
    passController.text = widget.user.pass;
    selectedGoal.text = widget.user.level;
    selectedActivityLevel.text = widget.user.ActivityLevel;
    selectedBodyFat.text = widget.user.body_fat;
    currentPic =
        widget.user.pic.isNotEmpty ? widget.user.pic : "assets/img/u2.png";

    // Lưu dữ liệu gốc để so sánh sau
    initialData = {
      'fname': widget.user.fname,
      'lname': widget.user.lname,
      'weight': widget.user.weight,
      'height': widget.user.height,
      'dateOfBirth': widget.user.dateOfBirth,
      'gender': widget.user.gender,
      'level': widget.user.level,
      'activityLevel': widget.user.ActivityLevel,
      'body_fat': widget.user.body_fat,
    };
  }

  @override
  void dispose() {
    fnameController.dispose();
    lnameController.dispose();
    selectWeight.dispose();
    selectHeight.dispose();
    selectDate.dispose();
    selectedGender.dispose();
    emailController.dispose();
    passController.dispose();
    selectedGoal.dispose();
    selectedActivityLevel.dispose();
    selectedBodyFat.dispose();
    super.dispose();
  }

  bool hasUnsavedChanges() {
    return fnameController.text != initialData['fname'] ||
        lnameController.text != initialData['lname'] ||
        selectWeight.text != initialData['weight'] ||
        selectHeight.text != initialData['height'] ||
        selectDate.text != initialData['dateOfBirth'] ||
        selectedGender.text != initialData['gender'] ||
        selectedGoal.text != initialData['level'] ||
        selectedActivityLevel.text != initialData['activityLevel'] ||
        selectedBodyFat.text != initialData['body_fat'];
  }

  void uploadImage() async {
    setState(() {
      isLoading = true;
    });

    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      try {
        String uid = widget.user.uid;
        String filePath = 'users/$uid/profile_images/${widget.user.uid}.png';
        File file = File(image.path);

        // Upload ảnh lên Firebase
        TaskSnapshot snapshot =
            await FirebaseStorage.instance.ref(filePath).putFile(file);
        String downloadUrl = await snapshot.ref.getDownloadURL();

        // Gán ảnh trên Firebase vào người dùng
        await AuthService().updateUserProfileImage(uid, downloadUrl);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload successful!')),
        );

        // Cập nhật ảnh trong trạng thái hiện tại
        setState(() {
          currentPic = downloadUrl;
          isLoading = false;
        });
      } catch (e) {
        // Xử lý lỗi
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
        setState(() {
          isLoading = false;
        });
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No image selected.')),
      );
      setState(() {
        isLoading = false;
      });
    }
  }

  void getUserInfo() async {
    // Kiểm tra nếu có thay đổi chưa lưu
    if (hasUnsavedChanges()) {
      bool? shouldSave = await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text("Chưa lưu thay đổi"),
          content: Text("Bạn có muốn lưu thay đổi trước khi rời đi?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false), // Không lưu
              child: Text("Không lưu"),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true), // Lưu
              child: Text("Lưu"),
            ),
          ],
        ),
      );

      if (shouldSave == true) {
        // Nếu người dùng chọn "Lưu", thì lưu lại trước
        await updateUserProfile();
      }
      // Nếu chọn "Không lưu", vẫn tiếp tục rời đi
    }

    try {
      // Lấy lại thông tin người dùng
      UserModel? user = await AuthService()
          .getUserInfo(FirebaseAuth.instance.currentUser!.uid);

      if (user != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => MainTabView(user: user, initialTab: 3),
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

  Future<void> updateUserProfile() async {
    setState(() {
      isLoading = true;
    });
    String uid = widget.user.uid;

    String res = await AuthService().updateUserProfile(
      uid: uid,
      fname: fnameController.text,
      lname: lnameController.text,
      dateOfBirth: selectDate.text,
      gender: selectedGender.text,
      weight: selectWeight.text,
      height: selectHeight.text,
      level: selectedGoal.text,
      ActivityLevel: selectedActivityLevel.text,
      body_fat: selectedBodyFat.text,
    );

    if (res == "success") {
      initialData = {
        'fname': fnameController.text,
        'lname': lnameController.text,
        'weight': selectWeight.text,
        'height': selectHeight.text,
        'dateOfBirth': selectDate.text,
        'gender': selectedGender.text,
        'level': selectedGoal.text,
        'activityLevel': selectedActivityLevel.text,
        'body_fat': selectedBodyFat.text,
      };
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Complete update your profile')),
      );
      setState(() {
        isLoading = false;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $res')),
      );
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: darkmode ? Colors.blueGrey[900] : TColor.white,
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
              borderRadius: BorderRadius.circular(10),
            ),
            child: Image.asset(
              "assets/img/black_btn.png",
              width: 15,
              height: 15,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(15.0),
                child: Column(
                  children: [
                    Text(
                      AppLocalizations.of(context)?.translate("Hey there,") ??
                          "Hey there,",
                      style: TextStyle(color: TColor.gray, fontSize: 16),
                    ),
                    Text(
                      AppLocalizations.of(context)
                              ?.translate("Edit Your Profile") ??
                          "Edit Your Profile",
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                    ),
                    SizedBox(
                      height: media.width * 0.05,
                    ),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(media.width * 0.2),
                      child: currentPic.startsWith('http')
                          ? Image.network(
                              currentPic,
                              width: media.width * 0.35,
                              height: media.width * 0.35,
                              fit: BoxFit.cover,
                            )
                          : Image.asset(
                              currentPic,
                              width: media.width * 0.35,
                              height: media.width * 0.35,
                              fit: BoxFit.cover,
                            ),
                    ),
                    SizedBox(
                      height: media.width * 0.05,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 15.0),
                      child: Column(
                        children: [
                          RoundTextField(
                            labelText: AppLocalizations.of(context)
                                    ?.translate("First Name") ??
                                "First Name",
                            icon: "assets/img/user_text.png",
                            controller: fnameController,
                          ),
                          SizedBox(
                            height: media.width * 0.04,
                          ),
                          RoundTextField(
                            labelText: AppLocalizations.of(context)
                                    ?.translate("Last Name") ??
                                "Last Name",
                            icon: "assets/img/user_text.png",
                            controller: lnameController,
                          ),
                          SizedBox(
                            height: media.width * 0.04,
                          ),
                          RoundTextField2(
                            labelText: "Email",
                            icon: "assets/img/email.png",
                            controller: emailController,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          SizedBox(
                            height: media.width * 0.04,
                          ),
                          GenderDropdown(
                            icon: "assets/img/gender.png",
                            labelText: "Choose Gender",
                            options: ["Male", "Female"],
                            controller: selectedGender,
                          ),
                          SizedBox(
                            height: media.width * 0.04,
                          ),
                          InkWell(
                            onTap: () {
                              DatePickerHelper.selectDate(context, selectDate);
                            },
                            child: IgnorePointer(
                              child: RoundTextField(
                                controller: selectDate,
                                labelText: AppLocalizations.of(context)
                                        ?.translate("Date of Birth") ??
                                    "Date of Birth",
                                icon: "assets/img/date.png",
                              ),
                            ),
                          ),
                          SizedBox(
                            height: media.width * 0.04,
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: RoundTextField(
                                  controller: selectWeight,
                                  labelText: AppLocalizations.of(context)
                                          ?.translate("Your Weight") ??
                                      "Your Weight",
                                  icon: "assets/img/weight.png",
                                ),
                              ),
                              const SizedBox(
                                width: 8,
                              ),
                              Container(
                                width: 50,
                                height: 50,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: TColor.secondaryG,
                                  ),
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: Text(
                                  "KG",
                                  style: TextStyle(
                                      color: TColor.white, fontSize: 12),
                                ),
                              )
                            ],
                          ),
                          SizedBox(
                            height: media.width * 0.04,
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: RoundTextField(
                                  controller: selectHeight,
                                  labelText: AppLocalizations.of(context)
                                          ?.translate("Your Height") ??
                                      "Your Height",
                                  icon: "assets/img/hight.png",
                                ),
                              ),
                              const SizedBox(
                                width: 8,
                              ),
                              Container(
                                width: 50,
                                height: 50,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: TColor.secondaryG,
                                  ),
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: Text(
                                  "CM",
                                  style: TextStyle(
                                      color: TColor.white, fontSize: 12),
                                ),
                              )
                            ],
                          ),
                          SizedBox(
                            height: media.width * 0.04,
                          ),
                          IconTitleNextRow2(
                            icon: "assets/img/body_icon.png",
                            title: AppLocalizations.of(context)
                                    ?.translate("Body Fat(%)") ??
                                "Body Fat(%)",
                            time: selectedBodyFat.text,
                            color: TColor.lightGray,
                            onPressed: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => ChangeBodyFatView(
                                        value: selectedBodyFat.text)),
                              );
                              if (result != null && result is String) {
                                setState(() {
                                  selectedBodyFat.text = result;
                                });
                              }
                            },
                          ),
                          SizedBox(
                            height: media.width * 0.04,
                          ),
                          IconTitleNextRow2(
                            icon: "assets/img/cup_icon.png",
                            title: AppLocalizations.of(context)
                                    ?.translate("Goal") ??
                                "Goal",
                            time: selectedGoal.text,
                            color: TColor.lightGray,
                            onPressed: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => ChangeGoalView(
                                        goal: selectedGoal.text)),
                              );
                              if (result != null && result is String) {
                                setState(() {
                                  selectedGoal.text = result;
                                });
                              }
                            },
                          ),
                          SizedBox(
                            height: media.width * 0.04,
                          ),
                          IconTitleNextRow2(
                            icon: "assets/img/choose_workout.png",
                            title: AppLocalizations.of(context)
                                    ?.translate("Activity Level") ??
                                "Activity Level",
                            time: selectedActivityLevel.text,
                            color: TColor.lightGray,
                            onPressed: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        ChangeActivityLevelView(
                                            goal: selectedActivityLevel.text)),
                              );
                              if (result != null && result is String) {
                                setState(() {
                                  selectedActivityLevel.text = result;
                                });
                              }
                            },
                          ),
                          SizedBox(
                            height: media.width * 0.04,
                          ),
                          IconTitleNextRow2(
                            icon: "assets/img/health_history.png",
                            title: "Medical History",
                            time: "",
                            color: TColor.lightGray,
                            onPressed: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const ChangeMedicalHistoryView(),
                                ),
                              );
                            },
                          ),
                          SizedBox(
                            height: media.width * 0.04,
                          ),
                          SizedBox(
                            height: media.width * 0.06,
                          ),
                          RoundButton(
                            title: AppLocalizations.of(context)
                                    ?.translate("Upload your image") ??
                                "Upload your image",
                            onPressed: uploadImage,
                          ),
                          SizedBox(
                            height: media.width * 0.04,
                          ),
                          RoundButton(
                            title: AppLocalizations.of(context)
                                    ?.translate("Save") ??
                                "Save",
                            onPressed: updateUserProfile,
                          ),
                          SizedBox(
                            height: media.width * 0.04,
                          ),
                          Visibility(
                            visible: passController.text.isNotEmpty,
                            child: RoundButton(
                              title: AppLocalizations.of(context)
                                      ?.translate("Change password") ??
                                  "Change password",
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const ChangePasswordView(),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
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

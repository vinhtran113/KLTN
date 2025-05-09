import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:fitness_workout_app/common/colo_extension.dart';
import 'package:fitness_workout_app/view/main_tab/main_tab_view.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../common_widget/GenderDropdown.dart';
import '../../common_widget/round_button.dart';
import '../../common_widget/round_textfield.dart';
import '../../common_widget/round_textfield_2.dart';
import '../../common_widget/selectDate.dart';
import '../../model/user_model.dart';
import '../../services/auth_services.dart';
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
  String currentPic = '';
  final ImagePicker _picker = ImagePicker();

  bool isLoading = false;
  bool darkmode = darkModeNotifier.value;

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
    currentPic = widget.user.pic.isNotEmpty ? widget.user.pic : "assets/img/u2.png";
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
    super.dispose();
  }

  void uploadImage() async {
    setState(() {
      isLoading = true;
    });

    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      try {
        String filePath = 'profile_images/${widget.user.uid}.png';
        File file = File(image.path);

        // Upload ảnh lên Firebase
        TaskSnapshot snapshot = await FirebaseStorage.instance.ref(filePath)
            .putFile(file);
        String downloadUrl = await snapshot.ref.getDownloadURL();

        // Gán ảnh trên Firebase vào người dùng
        String uid = widget.user.uid;
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
    try {
      // Lấy thông tin người dùng
      UserModel? user = await AuthService().getUserInfo(
          FirebaseAuth.instance.currentUser!.uid);

      if (user != null) {
        // Điều hướng đến HomeView với user
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

  void updateUserProfile() async {
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
    );

    if (res == "success") {
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
    var media = MediaQuery
        .of(context)
        .size;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: darkmode? Colors.blueGrey[900] : TColor.white,
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
                      AppLocalizations.of(context)?.translate("Hey there,") ?? "Hey there,",
                      style: TextStyle(color: TColor.gray, fontSize: 16),
                    ),
                    Text(
                      AppLocalizations.of(context)?.translate("Edit Your Profile") ?? "Edit Your Profile",
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700),
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
                            labelText: AppLocalizations.of(context)?.translate("First Name") ?? "First Name",
                            icon: "assets/img/user_text.png",
                            controller: fnameController,
                          ),
                          SizedBox(
                            height: media.width * 0.04,
                          ),
                          RoundTextField(
                            labelText: AppLocalizations.of(context)?.translate("Last Name") ?? "Last Name",
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
                            labelText:"Choose Gender",
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
                                labelText: AppLocalizations.of(context)?.translate("Date of Birth") ?? "Date of Birth",
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
                                  labelText: AppLocalizations.of(context)?.translate("Your Weight") ?? "Your Weight",
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
                                  style:
                                  TextStyle(color: TColor.white, fontSize: 12),
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
                                  labelText: AppLocalizations.of(context)?.translate("Your Height") ?? "Your Height",
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
                                  style:
                                  TextStyle(color: TColor.white, fontSize: 12),
                                ),
                              )
                            ],
                          ),
                          SizedBox(
                            height: media.width * 0.06,
                          ),
                          RoundButton(
                            title: AppLocalizations.of(context)?.translate("Upload your image") ?? "Upload your image",
                            onPressed: uploadImage,
                          ),
                          SizedBox(
                            height: media.width * 0.04,
                          ),
                          RoundButton(
                            title: AppLocalizations.of(context)?.translate("Save") ?? "Save",
                            onPressed: updateUserProfile,
                          ),
                          SizedBox(
                            height: media.width * 0.04,
                          ),
                          Visibility(
                            visible: passController.text.isNotEmpty,
                            child: RoundButton(
                              title: AppLocalizations.of(context)?.translate("Change password") ?? "Change password",
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const ChangePasswordView(),
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

          if (isLoading)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.5),
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
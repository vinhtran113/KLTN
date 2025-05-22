import 'package:carousel_slider/carousel_slider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../common/colo_extension.dart';
import '../../common_widget/round_button.dart';
import '../../model/user_model.dart';
import '../../services/auth_services.dart';
import '../main_tab/main_tab_view.dart';
import '../../main.dart';
import '../../localization/app_localizations.dart';

class ChangeActivityLevelView extends StatefulWidget {
  final String goal;
  const ChangeActivityLevelView({super.key, required this.goal});

  @override
  State<ChangeActivityLevelView> createState() => _ChangeActivityLevelViewState();
}

class _ChangeActivityLevelViewState extends State<ChangeActivityLevelView> {
  CarouselSliderController buttonCarouselController = CarouselSliderController();
  String selectedGoal = "";
  int currentIndex = 0;
  bool darkmode = darkModeNotifier.value;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  List goalArr = [
    {
      "image": "assets/img/ActivityLevel_1.png",
      "title": "Sedentary",
      "subtitle":
      "I spend most of my day sitting.\nMovement is minimal,\nand workouts are rare."
    },
    {
      "image": "assets/img/ActivityLevel_2.png",
      "title": "Lightly Active",
      "subtitle":
      "I take light walks or\nexercise a few days a week.\nI'm starting to move more."
    },
    {
      "image": "assets/img/ActivityLevel_3.png",
      "title": "Moderately Active",
      "subtitle":
      "I work out occasionally,\nabout 3–5 days a week.\nMy lifestyle balances rest and effort."
    },
    {
      "image": "assets/img/ActivityLevel_4.png",
      "title": "Very Active",
      "subtitle":
      "I work out regularly,\nabout 5–7 days a week.\nMy body is used to challenge,\nand I thrive on movement"
    },
    {
      "image": "assets/img/ActivityLevel_5.png",
      "title": "Extra Active",
      "subtitle":
      "I push my limits daily,\neither through tough training or\na physically demanding job.\nMy engine is always running."
    },
  ];

  void _loadData() async {
    selectedGoal = widget.goal;
    if(widget.goal == "Lightly Active"){currentIndex = 1;}
    if(widget.goal == "Moderately Active"){currentIndex = 2;}
    if(widget.goal == "Very Active"){currentIndex = 3;}
    if(widget.goal == "Extra Active"){currentIndex = 4;}
  }

  void changeGoal() async {
    try {
      Navigator.pop(context, selectedGoal);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi xảy ra: $e')),
      );
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
      body: SafeArea(
          child: Stack(
            children: [
              Center(
                child: CarouselSlider(
                  items: goalArr.map((gObj) =>
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                              colors: TColor.primaryG,
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight),
                          borderRadius: BorderRadius.circular(25),
                        ),
                        padding: EdgeInsets.symmetric(
                            vertical: media.width * 0.1, horizontal: 25),
                        alignment: Alignment.center,
                        child: FittedBox(
                          child: Column(
                            children: [
                              Image.asset(
                                gObj["image"].toString(),
                                width: media.width * 0.5,
                                fit: BoxFit.fitWidth,
                              ),
                              SizedBox(
                                height: media.width * 0.1,
                              ),
                              Text(
                                AppLocalizations.of(context)?.translate(gObj["title"].toString()) ?? gObj["title"].toString(),
                                style: TextStyle(
                                    color: TColor.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700),
                              ),
                              Container(
                                width: media.width * 0.1,
                                height: 1,
                                color: TColor.white,
                              ),
                              SizedBox(
                                height: media.width * 0.02,
                              ),
                              Text(
                                AppLocalizations.of(context)?.translate(gObj["subtitle"].toString()) ?? gObj["subtitle"].toString(),
                                textAlign: TextAlign.center,
                                style:
                                TextStyle(
                                    color: TColor.white, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ).toList(),
                  carouselController: buttonCarouselController,
                  options: CarouselOptions(
                    autoPlay: false,
                    enlargeCenterPage: true,
                    viewportFraction: 0.7,
                    aspectRatio: 0.74,
                    initialPage: currentIndex,
                    onPageChanged: (index, reason) {
                      setState(() {
                        currentIndex = index; // Cập nhật chỉ số hiện tại
                        selectedGoal = goalArr[index]["title"]; // Cập nhật selectedGoal
                      });
                    },
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                width: media.width,
                child: Column(
                  children: [
                    SizedBox(
                      height: media.width * 0.05,
                    ),
                    Text(
                      AppLocalizations.of(context)?.translate("What goal") ?? "What is your goal ?",
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700),
                    ),
                    Text(
                      AppLocalizations.of(context)?.translate("What goal des") ?? "It will help us to choose a best\nprogram for you",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: TColor.gray, fontSize: 12),
                    ),
                    const Spacer(),
                    RoundButton(
                        title: AppLocalizations.of(context)?.translate("Confirm") ?? "Confirm",
                        onPressed: changeGoal),
                    SizedBox(
                      height: media.width * 0.05,
                    ),
                  ],
                ),
              )
            ],
          )),
    );
  }
}


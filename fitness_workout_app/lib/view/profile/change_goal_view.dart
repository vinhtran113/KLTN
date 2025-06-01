import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';

import '../../common/colo_extension.dart';
import '../../common_widget/round_button.dart';
import '../../main.dart';
import '../../localization/app_localizations.dart';

class ChangeGoalView extends StatefulWidget {
  final String goal;
  const ChangeGoalView({super.key, required this.goal});

  @override
  State<ChangeGoalView> createState() => _ChangeGoalViewState();
}

class _ChangeGoalViewState extends State<ChangeGoalView> {
  CarouselSliderController buttonCarouselController =
      CarouselSliderController();
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
      "image": "assets/img/goal_1.png",
      "title": "Improve Shape",
      "subtitle":
          "I have a low amount of body fat\nand need/want to build more\nmuscle"
    },
    {
      "image": "assets/img/goal_2.png",
      "title": "Lean & Tone",
      "subtitle":
          "I’m “skinny fat”. look thin but have\nno shape. I want to add learn\nmuscle in the right way"
    },
    {
      "image": "assets/img/goal_3.png",
      "title": "Lose a Fat",
      "subtitle": "I want to drop all this fat and\ngain muscle mass"
    },
  ];

  void _loadData() async {
    selectedGoal = widget.goal;
    if (widget.goal == "Lose a Fat") {
      currentIndex = 2;
    }
    if (widget.goal == "Lean & Tone") {
      currentIndex = 1;
    }
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
    var media = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: darkmode ? Colors.blueGrey[900] : TColor.white,
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
              items: goalArr
                  .map(
                    (gObj) => Container(
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
                              AppLocalizations.of(context)
                                      ?.translate(gObj["title"].toString()) ??
                                  gObj["title"].toString(),
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
                              AppLocalizations.of(context)?.translate(
                                      gObj["subtitle"].toString()) ??
                                  gObj["subtitle"].toString(),
                              textAlign: TextAlign.center,
                              style:
                                  TextStyle(color: TColor.white, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                  .toList(),
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
                    selectedGoal =
                        goalArr[index]["title"]; // Cập nhật selectedGoal
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
                  AppLocalizations.of(context)?.translate("What goal") ??
                      "What is your goal ?",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
                Text(
                  AppLocalizations.of(context)?.translate("What goal des") ??
                      "It will help us to choose a best\nprogram for you",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: TColor.gray, fontSize: 12),
                ),
                const Spacer(),
                RoundButton(
                    title: AppLocalizations.of(context)?.translate("Confirm") ??
                        "Confirm",
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

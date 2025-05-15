import 'package:carousel_slider/carousel_slider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitness_workout_app/view/login/welcome_view.dart';
import 'package:flutter/material.dart';
import '../../common/colo_extension.dart';
import '../../common_widget/round_button.dart';
import '../../services/auth_services.dart';
import 'activate_account.dart';

class ChooseActivityLevelView extends StatefulWidget {
  const ChooseActivityLevelView({super.key});

  @override
  State<ChooseActivityLevelView> createState() => _ChooseActivityLevelViewState();
}

class _ChooseActivityLevelViewState extends State<ChooseActivityLevelView> {
  CarouselSliderController buttonCarouselController = CarouselSliderController();
  String selectedGoal = "Sedentary";
  int currentIndex = 0;

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

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery
        .of(context)
        .size;
    return Scaffold(
      backgroundColor: TColor.white,
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
                                gObj["subtitle"].toString(),
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
                      "What is your activity level?",
                      style: TextStyle(
                          color: TColor.black,
                          fontSize: 20,
                          fontWeight: FontWeight.w700),
                    ),
                    Text(
                      "It will help us to choose a best\nprogram for you",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: TColor.gray, fontSize: 12),
                    ),
                    const Spacer(),
                    RoundButton(
                        title: "Confirm",
                        onPressed: () async {
                          String result = await AuthService()
                              .updateUserActivityLevel(
                              FirebaseAuth.instance.currentUser!.uid,
                              selectedGoal);
                          if (result == "success") {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const WelcomeView(),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Lỗi xảy ra: $result')),
                            );
                          }
                        }),
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


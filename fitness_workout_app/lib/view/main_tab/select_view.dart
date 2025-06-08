import 'package:fitness_workout_app/common_widget/round_button.dart';
import 'package:fitness_workout_app/view/meal_planner/meal_planner_view.dart';
import 'package:fitness_workout_app/view/sleep_tracker/sleep_schedule_view.dart';
import 'package:fitness_workout_app/view/workout_tracker/workout_tracker_view.dart';
import 'package:flutter/material.dart';

import '../../chatbox/screens/chat/chat_screen.dart';
import '../../common/colo_extension.dart';
import '../../main.dart';
import '../tips/tips_view.dart';
import '../../localization/app_localizations.dart';

class SelectView extends StatefulWidget {
  const SelectView({super.key});
  @override
  State<SelectView> createState() => _SelectViewState();
}

class _SelectViewState extends State<SelectView> {
  bool darkmode = darkModeNotifier.value;
  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: darkmode ? Colors.blueGrey[900] : Colors.white,
        centerTitle: true,
        elevation: 0,
        leadingWidth: 0,
        leading: const SizedBox(),
        title: Text(
          AppLocalizations.of(context)?.translate("Select Activity") ??
              "Select Activity",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
              child: Container(
                width: double.maxFinite,
                padding: const EdgeInsets.all(20),
                height: media.width * 0.4,
                decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [
                      TColor.primaryColor2.withOpacity(0.4),
                      TColor.primaryColor1.withOpacity(0.4)
                    ]),
                    borderRadius: BorderRadius.circular(20)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(
                            height: 15,
                          ),
                          Text(
                            AppLocalizations.of(context)
                                    ?.translate("Workout Tracker") ??
                                "Workout Tracker",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            AppLocalizations.of(context)
                                    ?.translate("Train your body") ??
                                "Train your body",
                            style: TextStyle(
                                color: TColor.primaryColor2,
                                fontSize: 14,
                                fontWeight: FontWeight.w500),
                          ),
                          const Spacer(),
                          SizedBox(
                            width: 110,
                            height: 35,
                            child: RoundButton(
                                title: AppLocalizations.of(context)
                                        ?.translate("Start") ??
                                    "Start",
                                fontSize: 12,
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const WorkoutTrackerView(),
                                    ),
                                  );
                                }),
                          )
                        ]),
                    Image.asset(
                      "assets/img/welcome.png",
                      width: media.width * 0.35,
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 0.01),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
              child: Container(
                width: double.maxFinite,
                padding: const EdgeInsets.all(20),
                height: media.width * 0.4,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    TColor.primaryColor2.withOpacity(0.4),
                    TColor.primaryColor1.withOpacity(0.4)
                  ]),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Image.asset(
                      "assets/img/MealPlan.png",
                      width: media.width * 0.35,
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(
                          height: 15,
                        ),
                        Text(
                          AppLocalizations.of(context)
                                  ?.translate("Meal Tracker") ??
                              "Meal Tracker",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          AppLocalizations.of(context)
                                  ?.translate("Manage your meal") ??
                              "Manage your meal",
                          style: TextStyle(
                            color: TColor.primaryColor2,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        SizedBox(
                          width: 110,
                          height: 35,
                          child: RoundButton(
                            title: AppLocalizations.of(context)
                                    ?.translate("Start") ??
                                "Start",
                            fontSize: 12,
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const MealPlannerView(),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 0.01),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
              child: Container(
                width: double.maxFinite,
                padding: const EdgeInsets.all(20),
                height: media.width * 0.4,
                decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [
                      TColor.primaryColor2.withOpacity(0.4),
                      TColor.primaryColor1.withOpacity(0.4)
                    ]),
                    borderRadius: BorderRadius.circular(20)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(
                            height: 15,
                          ),
                          Text(
                            AppLocalizations.of(context)
                                    ?.translate("Sleep Tracker") ??
                                "Sleep Tracker",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            AppLocalizations.of(context)
                                    ?.translate("Manage your sleep") ??
                                "Manage your sleep",
                            style: TextStyle(
                                color: TColor.primaryColor2,
                                fontSize: 14,
                                fontWeight: FontWeight.w500),
                          ),
                          const Spacer(),
                          SizedBox(
                            width: 110,
                            height: 35,
                            child: RoundButton(
                                title: AppLocalizations.of(context)
                                        ?.translate("Start") ??
                                    "Start",
                                fontSize: 12,
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const SleepScheduleView(),
                                    ),
                                  );
                                }),
                          )
                        ]),
                    Image.asset(
                      "assets/img/SleepTracker.png",
                      width: media.width * 0.35,
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 0.01),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
              child: Container(
                width: double.maxFinite,
                padding: const EdgeInsets.all(20),
                height: media.width * 0.4,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    TColor.primaryColor2.withOpacity(0.4),
                    TColor.primaryColor1.withOpacity(0.4)
                  ]),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Image.asset(
                      "assets/img/Chatbox.png",
                      width: media.width * 0.35,
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(
                          height: 15,
                        ),
                        Text(
                          AppLocalizations.of(context)
                                  ?.translate("Health Bot") ??
                              "Health Bot",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          AppLocalizations.of(context)
                                  ?.translate("Health Care Chat") ??
                              "Health Care Chat",
                          style: TextStyle(
                            color: TColor.primaryColor2,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        SizedBox(
                          width: 110,
                          height: 35,
                          child: RoundButton(
                            title: AppLocalizations.of(context)
                                    ?.translate("Start") ??
                                "Start",
                            fontSize: 12,
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => const ChatScreen()),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 0.01),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
              child: Container(
                width: double.maxFinite,
                padding: const EdgeInsets.all(20),
                height: media.width * 0.4,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    TColor.primaryColor2.withOpacity(0.4),
                    TColor.primaryColor1.withOpacity(0.4)
                  ]),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(
                          height: 15,
                        ),
                        Text(
                          AppLocalizations.of(context)?.translate("Tips") ??
                              "Tips",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          AppLocalizations.of(context)
                                  ?.translate("Helpful tips for you") ??
                              "Helpful tips for you",
                          style: TextStyle(
                            color: TColor.primaryColor2,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        SizedBox(
                          width: 110,
                          height: 35,
                          child: RoundButton(
                            title: AppLocalizations.of(context)
                                    ?.translate("Learn More") ??
                                "Learn More",
                            fontSize: 11,
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const TipsView(),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    Image.asset(
                      "assets/img/tips.png",
                      width: media.width * 0.35,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

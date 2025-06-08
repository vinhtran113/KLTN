import 'package:flutter/material.dart';

import '../../main.dart';
import '../meal_planner/meal_planner_view.dart';
import '../sleep_tracker/sleep_schedule_view.dart';
import '../tips/tips_view.dart';
import '../workout_tracker/workout_tracker_view.dart';
import '../../localization/app_localizations.dart';

class SearchView extends StatefulWidget {
  const SearchView({super.key});

  @override
  State<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<SearchView> {
  TextEditingController txtSearch = TextEditingController();
  List<String> allActivities = [
    "Meal Tracker",
    "Theo dõi bữa ăn",
    "Workout Tracker",
    "Theo dõi tập luyện",
    "Sleep Tracker",
    "Theo dõi giấc ngủ",
    "Tips",
    "Mẹo"
  ];
  List<String> filteredActivities = [];
  bool darkmode = darkModeNotifier.value;

  @override
  void initState() {
    super.initState();
    txtSearch.addListener(() {
      setState(() {
        // Lọc danh sách dựa trên giá trị trong TextField
        filteredActivities = txtSearch.text.isEmpty
            ? [] // Nếu chưa nhập gì, không hiển thị gì cả
            : allActivities
                .where((activity) => activity
                    .toLowerCase()
                    .contains(txtSearch.text.toLowerCase()))
                .toList();
      });
    });
  }

  void navigateToActivity(String activity) {
    switch (activity) {
      case "Workout Tracker" || "Theo dõi tập luyện":
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const WorkoutTrackerView()));
        break;
      case "Meal Tracker" || "Theo dõi bữa ăn":
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => const MealPlannerView()));
        break;
      case "Sleep Tracker" || "Theo dõi giấc ngủ":
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => const SleepScheduleView()));
        break;
      case "Tips" || "Mẹo":
        Navigator.push(
            context, MaterialPageRoute(builder: (context) => const TipsView()));
        break;
      default:
        break;
    }
  }

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
          AppLocalizations.of(context)?.translate("Search Activity") ??
              "Search Activity",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
                color: darkmode ? Colors.black : Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                      color: darkmode ? Colors.white12 : Colors.black12,
                      blurRadius: 2,
                      offset: Offset(0, 1))
                ]),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: txtSearch,
                    decoration: InputDecoration(
                        focusedBorder: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        prefixIcon: Image.asset(
                          "assets/img/search.png",
                          width: 25,
                          height: 25,
                        ),
                        hintText: AppLocalizations.of(context)
                                ?.translate("Search here...") ??
                            "Search here..."),
                    style: TextStyle(
                      color: darkmode ? Colors.white : Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // ListView to display filtered results
          Expanded(
            child: txtSearch.text.isEmpty
                ? Container() // Không hiển thị gì khi chưa nhập
                : (filteredActivities.isEmpty
                    ? Center(
                        child: Text(
                            AppLocalizations.of(context)
                                    ?.translate("No activities found") ??
                                "No activities found",
                            style: TextStyle(
                                color: darkmode ? Colors.white : Colors.black,
                                fontSize: 16)))
                    : ListView.builder(
                        itemCount: filteredActivities.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            title: Text(
                              filteredActivities[index],
                              style: TextStyle(
                                  color:
                                      darkmode ? Colors.white : Colors.black),
                            ),
                            onTap: () =>
                                navigateToActivity(filteredActivities[index]),
                          );
                        },
                      )),
          ),
        ],
      ),
    );
  }
}

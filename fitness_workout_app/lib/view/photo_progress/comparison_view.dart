import 'package:fitness_workout_app/common_widget/icon_title_next_row.dart';
import 'package:fitness_workout_app/common_widget/round_button.dart';
import 'package:fitness_workout_app/view/photo_progress/result_view.dart';
import 'package:flutter/material.dart';

import '../../common/colo_extension.dart';
import '../../main.dart';

class ComparisonView extends StatefulWidget {
  const ComparisonView({super.key});

  @override
  State<ComparisonView> createState() => _ComparisonViewState();
}

class _ComparisonViewState extends State<ComparisonView> {
  bool darkmode = darkModeNotifier.value;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: darkmode? Colors.black : Colors.white,
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
              "assets/img/black_btn.png",
              width: 15,
              height: 15,
              fit: BoxFit.contain,
            ),
          ),
        ),
        title: const Text(
          "Comparison",
          style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
        child: Column(
          children: [
            IconTitleNextRow(
                icon: "assets/img/date.png",
                title: "Select Month 1",
                time: "May",
                onPressed: () {},
                color: TColor.lightGray),
            const SizedBox(
              height: 15,
            ),
            IconTitleNextRow(
                icon: "assets/img/date.png",
                title: "Select Month 2",
                time: "select Month",
                onPressed: () {},
                color: TColor.lightGray),
            const Spacer(),
            RoundButton(
                title: "Compare",
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ResultView(
                        date1: DateTime(2023, 5, 1),
                        date2: DateTime(2023, 6, 1),
                      ),
                    ),
                  );
                }),
            const SizedBox(
              height: 15,
            ),
          ],
        ),
      ),
    );
  }
}
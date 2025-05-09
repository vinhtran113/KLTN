import 'package:fitness_workout_app/common/colo_extension.dart';
import 'package:flutter/material.dart';

import '../view/meal_planner/food_info_details2_view.dart';

class MealFoodScheduleRow extends StatelessWidget {
  final Map mObj;
  final int index;
  const MealFoodScheduleRow({super.key, required this.mObj, required this.index});

  @override
  Widget build(BuildContext context) {
    return Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                height: 55,
                width: 55,
                decoration: BoxDecoration(
                    color: index % 2 == 0 ? TColor.primaryColor2.withOpacity(0.4) : TColor.secondaryColor2.withOpacity(0.4) ,
                    borderRadius: BorderRadius.circular(10)),
                alignment: Alignment.center,
                child: (mObj["image"] != null && mObj["image"].toString().startsWith('http')) ?
                Image.network(
                  mObj["image"].toString(),
                  width: 50,
                  height: 50,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Image.asset(
                      "assets/img/no_image.png",
                      width: 50,
                      height: 50,
                      fit: BoxFit.contain,
                    );
                  },
                )
                    : Image.asset(
                  "assets/img/no_image.png",
                  width: 50,
                  height: 50,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(
              width: 15,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mObj["name"].toString(),
                    style: TextStyle(
                        color: TColor.black,
                        fontSize: 12,
                        fontWeight: FontWeight.w700),
                  ),
                  Text(
                    "${mObj["time"].toString()} | ${mObj["totalCalories"].toStringAsFixed(0)} kCal",
                    style: TextStyle(
                      color: TColor.gray,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FoodInfoDetails2View(dObj: mObj),
                  ),
                );
              },
              icon: Image.asset(
                "assets/img/next_go.png",
                width: 25,
                height: 25,
              ),
            )
          ],
        ));
  }
}
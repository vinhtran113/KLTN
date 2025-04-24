import 'package:fitness_workout_app/common_widget/round_button.dart';
import 'package:flutter/material.dart';

import '../common/colo_extension.dart';
import '../model/meal_model.dart';
import '../view/meal_planner/food_info_details_view.dart';

class MealRecommendCell extends StatelessWidget {
  final Meal fObj;
  final Map mObj;
  final int index;
  const MealRecommendCell({super.key, required this.index, required this.fObj, required this.mObj});

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;
    bool isEvent = index % 2 == 0;
    return Container(
      margin: const EdgeInsets.all(5),
      width: media.width * 0.5,
      decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isEvent
                ? [
              TColor.primaryColor2.withOpacity(0.5),
              TColor.primaryColor1.withOpacity(0.5)
            ]
                : [
              TColor.secondaryColor2.withOpacity(0.5),
              TColor.secondaryColor1.withOpacity(0.5)
            ],
          ),
          borderRadius:  BorderRadius.circular(25)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          (fObj.image != null)
              ? Image.network(
            fObj.image.toString(),
            width: media.width * 0.3,
            height: media.width * 0.25,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Image.asset(
                "assets/img/no_image.png",
                width: media.width * 0.3,
                height: media.width * 0.25,
                fit: BoxFit.contain,
              );
            },
          )
              : Image.asset(
            "assets/img/no_image.png",
            width: media.width * 0.3,
            height: media.width * 0.25,
            fit: BoxFit.contain,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Text(
              fObj.name,
              style: TextStyle(
                color: TColor.black,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Text(
              "${fObj.size} | ${fObj.time} Mins | ${fObj.nutri.getCalories()} kCal",
              style: TextStyle(color: TColor.gray, fontSize: 12),
            ),
          ),
          const SizedBox(height: 15),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: SizedBox(
              width: 90,
              height: 35,
              child: RoundButton(
                fontSize: 12,
                type: isEvent
                    ? RoundButtonType.bgGradient
                    : RoundButtonType.bgSGradient,
                title: "View",
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FoodInfoDetailsView(
                        dObj: fObj,
                        mObj: mObj,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
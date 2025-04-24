import 'package:fitness_workout_app/common/colo_extension.dart';
import 'package:flutter/material.dart';

import '../model/meal_model.dart';

class SearchAllMealRow extends StatelessWidget {
  final Meal mObj;
  final Map dObj;

  const SearchAllMealRow({super.key, required this.mObj, required this.dObj});

  @override
  Widget build(BuildContext context) {
    bool isCurrentMeal = mObj.recommend.contains((dObj["name"]).toLowerCase());

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: TColor.white,
        border: Border.all(
          color: isCurrentMeal ? Colors.transparent : Colors.orange,
          width: 1.2,
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 2)],
      ),
      child: Row(
        children: [
          (mObj.image != null)
              ? Image.network(
            mObj.image.toString(),
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
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      mObj.name.toString(),
                      style: TextStyle(
                        color: TColor.black,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (!isCurrentMeal) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          "Not For ${dObj["name"]}",
                          style: TextStyle(fontSize: 10, color: Colors.red),
                        ),
                      ),
                    ]
                  ],
                ),
                Text(
                  "${mObj.size} | ${mObj.time} Mins | ${mObj.nutri.getCalories()} kCal",
                  style: TextStyle(color: TColor.gray, fontSize: 12),
                )
              ],
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: Image.asset(
              "assets/img/next_icon.png",
              width: 25,
              height: 25,
            ),
          )
        ],
      ),
    );
  }
}

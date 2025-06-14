import 'package:fitness_workout_app/common_widget/round_button.dart';
import 'package:flutter/material.dart';
import '../common/colo_extension.dart';
import '../../localization/app_localizations.dart';
import '../model/meal_model.dart';

class SelectFoodRow extends StatelessWidget {
  final Meal wObj;
  final Function(Meal) onSelect;

  const SelectFoodRow({super.key, required this.wObj, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [
            TColor.primaryColor2.withOpacity(0.3),
            TColor.primaryColor1.withOpacity(0.3)
          ]),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    wObj.name.toString(),
                    style: TextStyle(
                        color: TColor.black,
                        fontSize: 14,
                        fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${wObj.size} | ${wObj.time} Mins | ${wObj.nutri.getCalories()} kCal",
                    style: TextStyle(
                      color: TColor.gray,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 15),
                  SizedBox(
                    width: 100,
                    height: 30,
                    child: RoundButton(
                      title:
                          AppLocalizations.of(context)?.translate("Select") ??
                              "Select",
                      fontSize: 12,
                      type: RoundButtonType.textGradient,
                      elevation: 0.05,
                      fontWeight: FontWeight.w700,
                      onPressed: () {
                        onSelect(wObj);
                      },
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(width: 15),
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.54),
                    borderRadius: BorderRadius.circular(40),
                  ),
                ),
                ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: wObj.image.toString().isNotEmpty
                      ? Image.network(
                          wObj.image.toString(),
                          width: 90,
                          height: 90,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Image.asset(
                              "assets/img/no_image.png",
                              width: 90,
                              height: 90,
                              fit: BoxFit.contain,
                            );
                          },
                        )
                      : Image.asset(
                          "assets/img/no_image.png",
                          width: 90,
                          height: 90,
                          fit: BoxFit.contain,
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

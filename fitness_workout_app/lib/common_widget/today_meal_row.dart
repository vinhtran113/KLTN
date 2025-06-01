import 'package:animated_toggle_switch/animated_toggle_switch.dart';
import 'package:fitness_workout_app/common/colo_extension.dart';
import 'package:flutter/material.dart';

import '../view/meal_planner/edit_meal_schedule_view.dart';

class TodayMealRow extends StatefulWidget {
  final Map mObj;
  final VoidCallback onRefresh;
  const TodayMealRow({
    super.key,
    required this.mObj,
    required this.onRefresh,
  });

  @override
  State<TodayMealRow> createState() => _TodayMealRowState();
}

class _TodayMealRowState extends State<TodayMealRow> {
  bool positive = true;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EditMealScheduleView(bObj: widget.mObj),
          ),
        );
        if (result == true) {
          widget.onRefresh();
        }
      },
      child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
              color: TColor.white,
              borderRadius: BorderRadius.circular(11),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 4)
              ]),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  height: 55,
                  width: 55,
                  alignment: Alignment.center,
                  child: (widget.mObj["image"] != null &&
                          widget.mObj["image"].toString().startsWith('http'))
                      ? Image.network(
                          widget.mObj["image"].toString(),
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
                      widget.mObj["name"].toString(),
                      style: TextStyle(
                          color: TColor.black,
                          fontSize: 13,
                          fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      "Time: ${widget.mObj["time"].toString()}",
                      style: TextStyle(
                        color: TColor.gray,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      "Calories: ${widget.mObj["totalCalories"].toString()} KCal",
                      style: TextStyle(
                        color: TColor.gray,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              AbsorbPointer(
                absorbing: true,
                child: SizedBox(
                  height: 40,
                  child: Transform.scale(
                    scale: 0.8,
                    child: CustomAnimatedToggleSwitch<bool>(
                      current: widget.mObj["notify"],
                      values: [false, true],
                      indicatorSize: Size.square(40.0),
                      animationDuration: const Duration(milliseconds: 200),
                      animationCurve: Curves.linear,
                      onChanged: (b) => setState(() => positive = b),
                      iconBuilder: (context, local, global) {
                        return const SizedBox();
                      },
                      iconsTappable: true,
                      wrapperBuilder: (context, global, child) {
                        return Stack(
                          alignment: Alignment.center,
                          children: [
                            Positioned(
                              left: 15.0,
                              right: 15.0,
                              height: 40.0,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient:
                                      LinearGradient(colors: TColor.thirdG),
                                  borderRadius: const BorderRadius.all(
                                      Radius.circular(50.0)),
                                ),
                              ),
                            ),
                            child,
                          ],
                        );
                      },
                      foregroundIndicatorBuilder: (context, global) {
                        return SizedBox.fromSize(
                          size: const Size(20, 20),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: TColor.white,
                              borderRadius:
                                  const BorderRadius.all(Radius.circular(25.0)),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black38,
                                  spreadRadius: 0.1,
                                  blurRadius: 2.0,
                                  offset: Offset(0.0, 1.0),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          )),
    );
  }
}

import 'package:animated_toggle_switch/animated_toggle_switch.dart';
import 'package:fitness_workout_app/common/colo_extension.dart';
import 'package:flutter/material.dart';

import '../common/common.dart';
import '../model/alarm_model.dart';
import '../view/sleep_tracker/sleep_edit_alarm_view.dart';

class TodaySleepScheduleRow extends StatefulWidget {
  final AlarmSchedule sObj;
  final VoidCallback onRefresh;
  const TodaySleepScheduleRow({super.key, required this.sObj, required this.onRefresh});

  @override
  State<TodaySleepScheduleRow> createState() => _TodaySleepScheduleRowState();
}

class _TodaySleepScheduleRowState extends State<TodaySleepScheduleRow> {
  bool positiveA = true;
  bool positiveB = true;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context).size;

    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SleepEditAlarmView(schedule: widget.sObj),
          ),
        );
        if (result == true) {
          widget.onRefresh();
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16), // Căn lề phù hợp
        padding: const EdgeInsets.all(15),
        constraints: BoxConstraints(maxWidth: media.width - 32), // Giới hạn chiều rộng
        decoration: BoxDecoration(
          color: TColor.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dòng đầu tiên: Repeat Interval
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.sObj.repeatInterval.toString() == "Everyday"
                        ? "Everyday"
                        : widget.sObj.repeatInterval.contains("day")
                        ? "Repeat: ${widget.sObj.repeatInterval.split(",").map((day) {
                      switch (day) {
                        case "Monday":
                          return "2";
                        case "Tuesday":
                          return "3";
                        case "Wednesday":
                          return "4";
                        case "Thursday":
                          return "5";
                        case "Friday":
                          return "6";
                        case "Saturday":
                          return "7";
                        case "Sunday":
                          return "CN";
                        default:
                          return day;
                      }
                    }).join(",")}"
                        : "Date: ${widget.sObj.day.toString()}",
                    style: TextStyle(
                      color: TColor.gray,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Hàng thứ nhất: Giờ đi ngủ
            Row(
              children: [
                const SizedBox(width: 15),
                ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: Image.asset(
                    "assets/img/bed.png",
                    width: 30,
                    height: 30,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Text(
                    "Bedtime: ${widget.sObj.hourBed}",
                    style: TextStyle(
                      color: TColor.black,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
                AbsorbPointer(
                  absorbing: true,
                  child: Transform.scale(
                    scale: 0.7,
                    child: CustomAnimatedToggleSwitch<bool>(
                      current: widget.sObj.notifyBed,
                      values: [false, true],
                      indicatorSize: Size.square(40.0),
                      animationDuration: const Duration(milliseconds: 200),
                      animationCurve: Curves.linear,
                      onChanged: (b) => setState(() => positiveA = b),
                      iconBuilder: (context, local, global) {
                        return const SizedBox();
                      },
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
                                  gradient: LinearGradient(colors: TColor.thirdG),
                                  borderRadius: const BorderRadius.all(
                                    Radius.circular(50.0),
                                  ),
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
              ],
            ),
            const SizedBox(height: 10),
            // Hàng thứ hai: Giờ thức dậy
            Row(
              children: [
                const SizedBox(width: 15),
                ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: Image.asset(
                    "assets/img/alaarm.png",
                    width: 30,
                    height: 30,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Text(
                    "Wakeup: ${widget.sObj.hourWakeup}",
                    style: TextStyle(
                      color: TColor.black,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
                AbsorbPointer(
                  absorbing: true,
                  child: Transform.scale(
                    scale: 0.7,
                    child: CustomAnimatedToggleSwitch<bool>(
                      current: widget.sObj.notifyWakeup,
                      values: [false, true],
                      indicatorSize: Size.square(40.0),
                      animationDuration: const Duration(milliseconds: 200),
                      animationCurve: Curves.linear,
                      onChanged: (b) => setState(() => positiveB = b),
                      iconBuilder: (context, local, global) {
                        return const SizedBox();
                      },
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
                                  gradient: LinearGradient(colors: TColor.thirdG),
                                  borderRadius: const BorderRadius.all(
                                    Radius.circular(50.0),
                                  ),
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
              ],
            ),
          ],
        ),
      ),
    );
  }
}


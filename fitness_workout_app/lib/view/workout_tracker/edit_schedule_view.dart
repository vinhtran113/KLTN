import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitness_workout_app/view/workout_tracker/select_workout_view.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../common/colo_extension.dart';
import '../../common/common.dart';
import '../../common_widget/delete_button.dart';
import '../../common_widget/icon_title_next_row.dart';
import '../../common_widget/repetition_row.dart';
import '../../common_widget/round_button.dart';
import '../../model/workout_schedule_model.dart';
import '../../services/workout_services.dart';
import '../../main.dart';
import '../../localization/app_localizations.dart';

class EditScheduleView extends StatefulWidget {
  final WorkoutSchedule schedule;
  const EditScheduleView({super.key, required this.schedule});

  @override
  State<EditScheduleView> createState() => _EditScheduleViewState();
}

class _EditScheduleViewState extends State<EditScheduleView> {
  final WorkoutService _workoutService = WorkoutService();
  final TextEditingController selectedDifficulty = TextEditingController();
  final TextEditingController selectedWorkout = TextEditingController();
  final TextEditingController selectedRepetition = TextEditingController();
  String day = "";
  String hour = "";
  bool isLoading = false;
  DateTime? parsedDay;
  DateTime? parsedHour;
  bool isNotificationEnabled = true; // Ban đầu thông báo được bật
  bool darkmode = darkModeNotifier.value;

  @override
  void initState() {
    super.initState();
    // Gán giá trị cho các TextEditingController sau khi có lịch tập
    selectedWorkout.text = widget.schedule.name;
    selectedDifficulty.text = widget.schedule.difficulty;
    selectedRepetition.text = widget.schedule.repeatInterval;
    day = widget.schedule.day;
    hour = widget.schedule.hour;
    parsedDay = DateFormat("d/M/yyyy").parse(widget.schedule.day);
    parsedHour = DateFormat("h:mm a").parse(widget.schedule.hour);
    isNotificationEnabled = widget.schedule.notify;
  }

  @override
  void dispose() {
    super.dispose();
    selectedDifficulty.dispose();
    selectedWorkout.dispose();
    selectedRepetition.dispose();
  }

  void _handleUpdateSchedule() async {
    try {
      setState(() {
        isLoading = true;
      });
      String uid = FirebaseAuth.instance.currentUser!.uid;
      String res = await _workoutService.updateSchedule(
          id: widget.schedule.id,
          day: day,
          difficulty: selectedDifficulty.text.trim(),
          hour: hour,
          name: selectedWorkout.text.trim(),
          repeatInterval: selectedRepetition.text.trim(),
          uid: uid,
          notify: isNotificationEnabled,
          id_notify: widget.schedule.id_notify);
      if (res == "success") {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Workout schedule updating successfully')));
        Navigator.pop(context, true);
        setState(() {
          isLoading = false;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$res')),);
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi xảy ra: $e')),
      );
      setState(() {
        isLoading = false;
      });
    }
  }

  void _onTimeChanged(DateTime newDate) {
    setState(() {
      // Lấy giờ và phút từ DateTime và định dạng lại
      hour = DateFormat('h:mm a').format(newDate);
      ;
    });
  }

  void _showDifficultySelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: ["Beginner", "Normal", "Professional"].map((difficulty) {
              return ListTile(
                title: Text(
                  AppLocalizations.of(context)?.translate(difficulty) ?? difficulty,
                  style: TextStyle(color: darkmode? TColor.white : TColor.black, fontSize: 14),
                ),
                onTap: () {
                  setState(() {
                    selectedDifficulty.text = difficulty;
                  });
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  void _confirmDeleteSchedule() async {
    // Hiển thị một hộp thoại xác nhận trước khi xoá
    bool? confirm = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Delete'),
          content: Text(
              'Are you sure you want to delete this workout schedule?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('Delete'),
            ),
          ],
        );
      },
    );
    // Nếu người dùng xác nhận, gọi hàm xoá lịch bài tập
    if (confirm == true) {
      String res = await _workoutService.deleteWorkoutSchedule(scheduleId:  widget.schedule.id);
      if (res == "success") {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Workout schedule deleted successfully')));

        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$res')),);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery
        .of(context)
        .size;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: darkmode? Colors.blueGrey[900] : TColor.white,
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
              "assets/img/closed_btn.png",
              width: 15,
              height: 15,
              fit: BoxFit.contain,
            ),
          ),
        ),
        title: Text(
          AppLocalizations.of(context)?.translate("Edit Schedule") ?? "Edit Schedule",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      body: Stack(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 25),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(
                children: [
                  Image.asset(
                    "assets/img/date.png",
                    width: 21,
                    height: 21,
                  ),
                  const SizedBox(
                    width: 12,
                  ),
                  Text(
                    dateToString(parsedDay as DateTime, formatStr: "E, dd MMMM yyyy"),
                    style: TextStyle(color: TColor.gray, fontSize: 15),
                  ),
                ],
              ),
              SizedBox(
                  height: media.width * 0.04,
              ),
              Text(
                AppLocalizations.of(context)?.translate("Time") ?? "Time",
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500),
              ),
              SizedBox(
                height: media.width * 0.35,
                child: CupertinoDatePicker(
                  onDateTimeChanged: _onTimeChanged,
                  initialDateTime: parsedHour,
                  use24hFormat: false,
                  minuteInterval: 1,
                  mode: CupertinoDatePickerMode.time,
                ),
              ),
              SizedBox(
                  height: media.width * 0.06,
              ),
              Text(
                AppLocalizations.of(context)?.translate("Details Workout") ?? "Details Workout",
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500),
              ),
              SizedBox(
                  height: media.width * 0.03,
              ),
              IconTitleNextRow(
                icon: "assets/img/choose_workout.png",
                title: AppLocalizations.of(context)?.translate("Choose Workout") ?? "Choose Workout",
                time: selectedWorkout.text,
                color: TColor.lightGray,
                onPressed: () async {
                  // Chuyển sang trang SelectWorkoutView và chờ kết quả
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const SelectWorkoutView()),
                  );
                  if (result != null && result is String) {
                    setState(() {
                      selectedWorkout.text = result;
                    });
                  }
                },
              ),
              SizedBox(
                  height: media.width * 0.03
              ),
              InkWell(
                onTap: () {
                  _showDifficultySelector(context);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      vertical: 8, horizontal: 15),
                  decoration: BoxDecoration(
                    color: TColor.lightGray,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        alignment: Alignment.center,
                        child: Image.asset(
                          "assets/img/difficulity.png",
                          width: 16,
                          height: 16,
                          fit: BoxFit.contain,
                        ),
                      ),

                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          AppLocalizations.of(context)?.translate("Difficulty") ?? "Difficulty",
                          style: TextStyle(color: TColor.gray, fontSize: 12),
                        ),
                      ),

                      SizedBox(
                        width: 120,
                        child: Text(
                          selectedDifficulty.text,
                          textAlign: TextAlign.right,
                          style: TextStyle(color: TColor.gray, fontSize: 12),
                        ),
                      ),

                      Container(
                        width: 25,
                        height: 25,
                        alignment: Alignment.center,
                        child: Image.asset(
                          "assets/img/p_next.png",
                          width: 12,
                          height: 12,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(
                height: media.width * 0.03,
              ),
              RepetitionsRow(
                icon: "assets/img/Repeat.png",
                title: AppLocalizations.of(context)?.translate("Custom Repetitions") ?? "Custom Repetitions",
                color: TColor.lightGray,
                repetitionController: selectedRepetition,
              ),
              SizedBox(
                height: media.width * 0.03,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppLocalizations.of(context)?.translate("Enable Notifications") ?? "Enable Notifications",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Switch(
                    value: isNotificationEnabled,
                    activeColor: TColor.primaryColor1,
                    onChanged: (value) {
                      setState(() {
                        isNotificationEnabled = value;
                      });
                    },
                  ),
                ],
              ),
              Spacer(),
              RoundButton(
                  title: AppLocalizations.of(context)?.translate("Save") ?? "Save",
                  onPressed: _handleUpdateSchedule),
              SizedBox(
                height: media.width * 0.03,
              ),
              DeleteButton(
                title: AppLocalizations.of(context)?.translate("Delete") ?? "Delete",
                onPressed: _confirmDeleteSchedule),
              const SizedBox(
                height: 20,
              ),
            ]),
          ),
          AnimatedOpacity(
            opacity: isLoading ? 1.0 : 0.0,
            duration: Duration(milliseconds: 300),
            child: IgnorePointer(
              ignoring: !isLoading,
              child: Container(
                color: Colors.black.withOpacity(0.5),
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
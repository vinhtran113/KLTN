import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitness_workout_app/services/alarm_services.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../common/colo_extension.dart';
import '../../common/common.dart';
import '../../common_widget/icon_title_next_row.dart';
import '../../common_widget/repetition_row.dart';
import '../../common_widget/round_button.dart';
import '../../main.dart';
import '../../localization/app_localizations.dart';

class SleepAddAlarmView extends StatefulWidget {
  final DateTime date;
  const SleepAddAlarmView({super.key, required this.date});

  @override
  State<SleepAddAlarmView> createState() => _SleepAddAlarmViewState();
}

class _SleepAddAlarmViewState extends State<SleepAddAlarmView> {
  final AlarmService _alarmService = AlarmService();
  final TextEditingController selectedRepetition = TextEditingController();
  bool isBedEnabled = true;
  bool isWakeupEnabled = true;
  String selectedTimeBed = "";
  String selectedTimeWakeup = "";
  bool isLoading = false;
  String day = "";
  bool darkmode = darkModeNotifier.value;

  @override
  void initState() {
    super.initState();
    selectedRepetition.text = "no";
    day = dateToString(widget.date, formatStr: "d/M/yyyy");
  }

  @override
  void dispose() {
    super.dispose();
    selectedRepetition.dispose();
  }

  Future<void> _selectTimeBed(BuildContext context) async {
    // Chuyển selectedTimeBed (String) thành TimeOfDay
    TimeOfDay initialTime = TimeOfDay.now();
    if (selectedTimeBed.isNotEmpty) {
      final DateTime parsedTime = DateFormat('hh:mm a').parse(selectedTimeBed);
      initialTime = TimeOfDay(hour: parsedTime.hour, minute: parsedTime.minute);
    }

    TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: initialTime, // Dùng giờ đã chọn trước đó
      builder: (BuildContext context, Widget? child) {
        return Localizations.override(
          context: context,
          locale: const Locale('en', 'US'), // Ép buộc sử dụng định dạng 12 giờ kiểu Anh
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
            child: child!,
          ),
        );
      },
    );

    if (pickedTime != null) {
      final now = DateTime.now();

      // Format lại giờ theo 12-hour format chuẩn AM/PM
      final formattedTime = DateFormat('hh:mm a').format(
        DateTime(now.year, now.month, now.day, pickedTime.hour, pickedTime.minute),
      );

      setState(() {
        selectedTimeBed = formattedTime; // Luôn là dạng 12-hour format
      });
    }
  }

  Future<void> _selectTimeWakeup(BuildContext context) async {
    // Chuyển selectedTimeBed (String) thành TimeOfDay
    TimeOfDay initialTime = TimeOfDay.now();
    if (selectedTimeWakeup.isNotEmpty) {
      final DateTime parsedTime = DateFormat('hh:mm a').parse(selectedTimeWakeup);
      initialTime = TimeOfDay(hour: parsedTime.hour, minute: parsedTime.minute);
    }

    TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (BuildContext context, Widget? child) {
        return Localizations.override(
          context: context,
          locale: const Locale('en', 'US'), // Ép buộc sử dụng định dạng 12 giờ kiểu Anh
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
            child: child!,
          ),
        );
      },
    );

    if (pickedTime != null) {
      final now = DateTime.now();

      // Format lại giờ theo 12-hour format chuẩn AM/PM
      final formattedTime = DateFormat('hh:mm a').format(
        DateTime(now.year, now.month, now.day, pickedTime.hour, pickedTime.minute),
      );

      setState(() {
        selectedTimeWakeup = formattedTime; // Luôn là dạng 12-hour format
      });
    }
  }

  void _handleAddAlarmSchedule() async {
    try {
      setState(() {
        isLoading = true;
      });
      String uid = FirebaseAuth.instance.currentUser!.uid;
      String res = await _alarmService.addAlarmSchedule(
        day: day,
        hourWakeup: selectedTimeWakeup,
        hourBed: selectedTimeBed,
        notify_Bed: isBedEnabled,
        notify_Wakeup: isWakeupEnabled,
        repeatInterval: selectedRepetition.text.trim(),
        uid: uid,);

      if (res == "success") {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Alarm schedule added successfully')));
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

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;
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
            AppLocalizations.of(context)?.translate("Add Alarm") ?? "Add Alarm",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      body: Stack(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 25),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: [
              const SizedBox(
                height: 8,
              ),
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
                    dateToString(widget.date, formatStr: "E, dd MMMM yyyy"),
                    style: TextStyle(color: TColor.gray, fontSize: 15),
                  ),
                ],
              ),
              SizedBox(
                height: media.width * 0.04,
              ),
              IconTitleNextRow(
                icon: "assets/img/Bed_Add.png",
                title: AppLocalizations.of(context)?.translate("Bed Time",) ?? "Bed Time",
                time: selectedTimeBed,
                color: TColor.lightGray,
                onPressed: () => _selectTimeBed(context),
              ),
              const SizedBox(
                height: 10,
              ),
              IconTitleNextRow(
                  icon: "assets/img/HoursTime.png",
                  title: AppLocalizations.of(context)?.translate("Wake Up Time") ?? "Wake Up Time",
                  time: selectedTimeWakeup,
                  color: TColor.lightGray,
                  onPressed: () => _selectTimeWakeup(context)),
              const SizedBox(
                height: 10,
              ),
              RepetitionsRow(
                icon: "assets/img/Repeat.png",
                title: AppLocalizations.of(context)?.translate("Custom Repetitions") ?? "Custom Repetitions",
                color: TColor.lightGray,
                repetitionController: selectedRepetition,
              ),
              const SizedBox(height: 10,),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                  AppLocalizations.of(context)?.translate("Enable Bedtime") ?? "Enable Notifications Bedtime",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                  Switch(
                    value: isBedEnabled,
                    activeColor: TColor.primaryColor1,
                    onChanged: (value) {
                      setState(() {
                        isBedEnabled = value;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                  AppLocalizations.of(context)?.translate("Enable Wakeup") ?? "Enable Notifications Wakeup",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                  Switch(
                    value: isWakeupEnabled,
                    activeColor: TColor.primaryColor1,
                    onChanged: (value) {
                      setState(() {
                        isWakeupEnabled = value;
                      });
                    },
                  ),
                ],
              ),
              const Spacer(),
              RoundButton(title: AppLocalizations.of(context)?.translate("Add") ?? "Add",
                  onPressed: _handleAddAlarmSchedule),
              const SizedBox(
                height: 20,
              ),
            ]
            ),
          ),
          if (isLoading)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.5),
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
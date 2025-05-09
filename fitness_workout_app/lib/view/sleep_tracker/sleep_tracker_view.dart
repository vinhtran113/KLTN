import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitness_workout_app/view/sleep_tracker/sleep_schedule_view.dart';
import 'package:flutter/material.dart';

import '../../common/colo_extension.dart';
import '../../common_widget/round_button.dart';
import '../../common_widget/today_sleep_schedule_row.dart';
import '../../model/alarm_model.dart';
import '../../services/alarm_services.dart';
import '../../main.dart';
import '../../localization/app_localizations.dart';

class SleepTrackerView extends StatefulWidget {
  const SleepTrackerView({super.key});

  @override
  State<SleepTrackerView> createState() => _SleepTrackerViewState();
}

class _SleepTrackerViewState extends State<SleepTrackerView> {
  final AlarmService _alarmService = AlarmService();
  List<AlarmSchedule> todaySleepArr = [];
  String totalTime = '0 hours 0 minutes';
  bool darkmode = darkModeNotifier.value;

  @override
  void initState() {
    super.initState();
    _loadAlarmSchedules();
    _loadTimeSleepLastNight();
  }

  void _loadAlarmSchedules() async {
    List<AlarmSchedule> list = await _alarmService.fetchTodayAlarmSchedules(
        uid: FirebaseAuth.instance.currentUser!.uid);
    setState(() {
      todaySleepArr = list;
    });
  }

  void _confirmDeleteSchedule(String Id) async {
    String res = await _alarmService.deleteAlarmSchedule(alarmId: Id);
    if (res == "success") {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Alarm schedule deleted successfully')));

      _loadAlarmSchedules();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$res')),
      );
    }
  }

  void _loadTimeSleepLastNight() async {
    int total = await _alarmService.calculateTotalSleepTime(
        uid: FirebaseAuth.instance.currentUser!.uid);

    setState(() {
      int hours = total ~/ 60;
      int minutes = total % 60;
      totalTime = '$hours hours $minutes minutes';
    });
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
              "assets/img/black_btn.png",
              width: 15,
              height: 15,
              fit: BoxFit.contain,
            ),
          ),
        ),
        title: Text(
          AppLocalizations.of(context)?.translate("Sleep Tracker") ?? "Sleep Tracker",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.maxFinite,
                    height: media.width * 0.4,
                    decoration: BoxDecoration(
                        gradient: LinearGradient(colors: TColor.primaryG),
                        borderRadius: BorderRadius.circular(20)),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(
                            height: 15,
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 15),
                            child: Text(
                              AppLocalizations.of(context)?.translate("Last Night Sleep") ?? "Last Night Sleep",
                              style: TextStyle(
                                color: TColor.white,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 15),
                            child: Text(
                              totalTime,
                              style: TextStyle(
                                  color: TColor.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500),
                            ),
                          ),
                          const Spacer(),
                          Image.asset(
                            "assets/img/SleepGraph.png",
                            width: double.maxFinite,
                          )
                        ]),
                  ),
                  SizedBox(
                    height: media.width * 0.05,
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 15, horizontal: 15),
                    decoration: BoxDecoration(
                      color: TColor.primaryColor2.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          AppLocalizations.of(context)?.translate("Daily Sleep Schedule") ?? "Daily Sleep Schedule",
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700),
                        ),
                        SizedBox(
                          width: 80,
                          height: 30,
                          child: RoundButton(
                            title: AppLocalizations.of(context)?.translate("Check") ?? "Check",
                            type: RoundButtonType.bgGradient,
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            onPressed: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => SleepScheduleView()));

                              if (result == true) {
                                setState(() {
                                  _loadAlarmSchedules();
                                });
                              }
                            },
                          ),
                        )
                      ],
                    ),
                  ),
                  SizedBox(
                    height: media.width * 0.05,
                  ),
                  if (todaySleepArr.isEmpty) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          AppLocalizations.of(context)?.translate("You haven't set an alarm for today") ?? "You haven't set an alarm for today",
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ],
                  if (todaySleepArr.isNotEmpty) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          AppLocalizations.of(context)?.translate("Today Alarm") ?? "Today Alarm",
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    SizedBox(
                      height: media.width * 0.01,
                    ),
                    ListView.builder(
                      padding: EdgeInsets.zero,
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      itemCount: todaySleepArr.length,
                      itemBuilder: (context, index) {
                        AlarmSchedule wObj = todaySleepArr[index];
                        return Dismissible(
                          key: Key(wObj.id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            color: Colors.red,
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: const Icon(
                                Icons.delete, color: Colors.white),
                          ),
                          confirmDismiss: (direction) async {
                            // Hiển thị hộp thoại xác nhận trước khi xoá
                            bool? confirm = await showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: Text(AppLocalizations.of(context)?.translate("Confirm Delete") ?? "Confirm Delete"),
                                  content: Text(
                                      AppLocalizations.of(context)?.translate("Confirm Delete des") ?? "Are you sure you want to delete this alarm schedule?"),                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(false),
                                      child: Text(AppLocalizations.of(context)?.translate("Cancel") ?? "Cancel"),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(true),
                                      child: Text(AppLocalizations.of(context)?.translate("Delete") ?? "Delete"),
                                    ),
                                  ],
                                );
                              },
                            );
                            // Nếu người dùng xác nhận, cho phép xoá
                            return confirm == true;
                          },
                          onDismissed: (direction) {
                            _confirmDeleteSchedule(wObj.id);
                          },
                          child: TodaySleepScheduleRow(
                            sObj: wObj,
                            onRefresh: () {
                              _loadAlarmSchedules();
                            },
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }


}
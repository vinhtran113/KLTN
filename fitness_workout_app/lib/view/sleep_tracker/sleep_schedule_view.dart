import 'package:calendar_agenda/calendar_agenda.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitness_workout_app/services/alarm.dart';
import 'package:fitness_workout_app/view/sleep_tracker/sleep_add_alarm_view.dart';
import 'package:flutter/material.dart';

import '../../common/colo_extension.dart';
import '../../common_widget/today_sleep_schedule_row.dart';
import '../../model/alarm_model.dart';
import '../../main.dart';
import '../../localization/app_localizations.dart';

class SleepScheduleView extends StatefulWidget {
  const SleepScheduleView({super.key});

  @override
  State<SleepScheduleView> createState() => _SleepScheduleViewState();
}

class _SleepScheduleViewState extends State<SleepScheduleView> {
  CalendarAgendaController _calendarAgendaControllerAppBar = CalendarAgendaController();
  final AlarmService _alarmService = AlarmService();
  late DateTime _selectedDateAppBBar;

  List<AlarmSchedule> todaySleepArr = [];
  List<int> showingTooltipOnSpots = [4];
  bool darkmode = darkModeNotifier.value;

  @override
  void initState() {
    super.initState();
    _selectedDateAppBBar = DateTime.now();
    _loadAlarmSchedules();
  }

  void _loadAlarmSchedules() async {
    List<AlarmSchedule> list = await _alarmService.fetchAlarmSchedules(
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
            Navigator.pop(context, true);
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
          AppLocalizations.of(context)?.translate("Sleep Schedule") ?? "Sleep Schedule",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding:
                  const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                  child: Container(
                    width: double.maxFinite,
                    padding: const EdgeInsets.all(20),
                    height: media.width * 0.4,
                    decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [
                          TColor.primaryColor2.withOpacity(0.4),
                          TColor.primaryColor1.withOpacity(0.4)
                        ]),
                        borderRadius: BorderRadius.circular(20)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(
                                height: 50,
                              ),
                              Text(
                                AppLocalizations.of(context)?.translate("Ideal Sleep") ?? "Ideal Hours for Sleep",
                                style: TextStyle(
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                "8hours 30minutes",
                                style: TextStyle(
                                    color: TColor.primaryColor2,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500),
                              ),
                            ]),
                        Image.asset(
                          "assets/img/sleep_schedule.png",
                          width: media.width * 0.35,
                        )
                      ],
                    ),
                  ),
                ),
                SizedBox(
                  height: media.width * 0.02,
                ),
                Padding(
                  padding:
                  const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                  child: Text(
                      AppLocalizations.of(context)?.translate("Your Schedule") ?? "Your Schedule",
                    style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700),
                  ),
                ),
                CalendarAgenda(
                  controller: _calendarAgendaControllerAppBar,
                  appbar: false,
                  selectedDayPosition: SelectedDayPosition.center,
                  leading: IconButton(
                      onPressed: () {},
                      icon: Image.asset(
                        "assets/img/ArrowLeft.png",
                        width: 15,
                        height: 15,
                      )),
                  training: IconButton(
                      onPressed: () {},
                      icon: Image.asset(
                        "assets/img/ArrowRight.png",
                        width: 15,
                        height: 15,
                      )),
                  weekDay: WeekDay.short,
                  dayNameFontSize: 12,
                  dayNumberFontSize: 16,
                  dayBGColor: Colors.grey.withOpacity(0.15),
                  titleSpaceBetween: 15,
                  backgroundColor: Colors.transparent,
                  // fullCalendar: false,
                  fullCalendarScroll: FullCalendarScroll.horizontal,
                  fullCalendarDay: WeekDay.short,
                  selectedDateColor: darkmode? Colors.black : TColor.white,
                  dateColor: darkmode? Colors.white : TColor.black,
                  locale: 'en',

                  initialDate: DateTime.now(),
                  calendarEventColor: TColor.primaryColor2,
                  firstDate: DateTime.now().subtract(const Duration(days: 140)),
                  lastDate: DateTime.now().add(const Duration(days: 60)),

                  onDateSelected: (date) {
                    _selectedDateAppBBar = date;
                  },
                  selectedDayLogo: Container(
                    width: double.maxFinite,
                    height: double.maxFinite,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                          colors: TColor.primaryG,
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter),
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                ),
                if (todaySleepArr.isEmpty) ...[
                  SizedBox(
                    height: media.width * 0.02,
                  ),
                  Padding(
                    padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                    child: Text(
                      AppLocalizations.of(context)?.translate("not alarm") ?? "You have not scheduled an alarm!",
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
                if (todaySleepArr.isNotEmpty) ...[
                  SizedBox(
                    height: media.width * 0.02,
                  ),
                  Padding(
                    padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                    child: Text(
                      AppLocalizations.of(context)?.translate("Upcoming Alarm") ?? "Upcoming Alarm",
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700),
                    ),
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
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        confirmDismiss: (direction) async {
                          // Hiển thị hộp thoại xác nhận trước khi xoá
                          bool? confirm = await showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: Text(AppLocalizations.of(context)?.translate("Confirm Delete") ?? "Confirm Delete"),
                                content: Text(
                                    AppLocalizations.of(context)?.translate("Confirm Delete des") ?? "Are you sure you want to delete this alarm schedule?"),
                                actions: [
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
            SizedBox(
              height: media.width * 0.05,
            ),
          ],
        ),
      ),
      floatingActionButton: InkWell(
        onTap: () async {
          DateTime now = DateTime.now();
          DateTime startOfDay = DateTime(now.year, now.month, now.day);
          if (_selectedDateAppBBar.isBefore(startOfDay)) {
            return;
          }
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  SleepAddAlarmView(
                    date: _selectedDateAppBBar,
                  ),
            ),
          );
          if (result == true) {
            _loadAlarmSchedules();
          }
        },
        child: Container(
          width: 55,
          height: 55,
          decoration: BoxDecoration(
              gradient: LinearGradient(colors: TColor.secondaryG),
              borderRadius: BorderRadius.circular(27.5),
              boxShadow: const [
                BoxShadow(
                    color: Colors.black12, blurRadius: 5, offset: Offset(0, 2))
              ]),
          alignment: Alignment.center,
          child: Icon(
            Icons.add,
            size: 20,
            color: TColor.white,
          ),
        ),
      ),
    );
  }
}
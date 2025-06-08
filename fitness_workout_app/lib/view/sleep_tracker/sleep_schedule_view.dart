import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitness_workout_app/common_widget/round_button.dart';
import 'package:fitness_workout_app/model/user_model.dart';
import 'package:fitness_workout_app/services/alarm_services.dart';
import 'package:fitness_workout_app/services/auth_services.dart';
import 'package:fitness_workout_app/view/sleep_tracker/sleep_add_alarm_view.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

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
  final AlarmService _alarmService = AlarmService();

  List<AlarmSchedule> todaySleepArr = [];
  List<int> showingTooltipOnSpots = [4];
  bool darkmode = darkModeNotifier.value;
  String totalTime = '0 hours 0 minutes';

  int userAge = 0;
  String idealSleepText = "";

  @override
  void initState() {
    super.initState();
    getUserInfo();
    _loadAlarmSchedules();
    _loadTimeSleepLastNight();
  }

  void getUserInfo() async {
    try {
      // Lấy lại thông tin người dùng
      UserModel? user = await AuthService()
          .getUserInfo(FirebaseAuth.instance.currentUser!.uid);

      if (user != null) {
        setState(() {
          userAge = user.getAge();
          idealSleepText = suggestIdealSleepHours(userAge);
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Có lỗi xảy ra')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi xảy ra: $e')),
      );
    }
  }

  String suggestIdealSleepHours(int age) {
    if (age < 0) return "Invalid age";
    if (age <= 0) return "14 - 17 hours";
    if (age <= 0.25) return "14 - 17 hours"; // 0-3 tháng
    if (age <= 0.92) return "12 - 16 hours"; // 4-11 tháng
    if (age <= 2) return "11 - 14 hours"; // 1-2 tuổi
    if (age <= 5) return "10 - 13 hours"; // 3-5 tuổi
    if (age <= 12) return "9 - 12 hours"; // 6-12 tuổi
    if (age <= 18) return "8 - 10 hours"; // 13-18 tuổi
    if (age <= 64) return "7 - 9 hours"; // 18-64 tuổi
    return "7 - 8 hours"; // 65+ tuổi
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
        SnackBar(content: Text(res)),
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
    var media = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: darkmode ? Colors.blueGrey[900] : TColor.white,
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
          AppLocalizations.of(context)?.translate("Sleep Tracker") ??
              "Sleep Tracker",
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
                                height: 25,
                              ),
                              Text(
                                AppLocalizations.of(context)
                                        ?.translate("Ideal Sleep") ??
                                    "Ideal Hours for Sleep",
                                style: TextStyle(
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                idealSleepText,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const Spacer(),
                              SizedBox(
                                width: 110,
                                height: 35,
                                child: RoundButton(
                                  title: "Learn More",
                                  fontSize: 12,
                                  onPressed: () async {
                                    final url = Uri.parse(
                                        'https://www.healthline.com/health/sleep/sleep-calculator#sleep-needs');
                                    if (!await launchUrl(url,
                                        mode: LaunchMode.externalApplication)) {
                                      // Nếu không mở được, thử mở bằng launchUrl đơn giản
                                      await launchUrl(url);
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(
                                height: 25,
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
                Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    height: media.width * 0.4,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: TColor.primaryG),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 15),
                        Text(
                          AppLocalizations.of(context)
                                  ?.translate("Last Night Sleep") ??
                              "Last Night Sleep",
                          style: TextStyle(
                            color: TColor.white,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          totalTime,
                          style: TextStyle(
                            color: TColor.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        Image.asset(
                          "assets/img/SleepGraph.png",
                          width: double.infinity,
                          fit: BoxFit.contain,
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                  child: Text(
                    AppLocalizations.of(context)
                            ?.translate("Your Alarm Schedule") ??
                        "Your Alarm Schedule",
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                  ),
                ),
                if (todaySleepArr.isEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 20),
                    child: Text(
                      AppLocalizations.of(context)?.translate("not alarm") ??
                          "You have not scheduled an alarm!",
                      style:
                          TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
                    ),
                  ),
                ],
                if (todaySleepArr.isNotEmpty) ...[
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
                                title: Text(AppLocalizations.of(context)
                                        ?.translate("Confirm Delete") ??
                                    "Confirm Delete"),
                                content: Text(AppLocalizations.of(context)
                                        ?.translate("Confirm Delete des") ??
                                    "Are you sure you want to delete this alarm schedule?"),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(false),
                                    child: Text(AppLocalizations.of(context)
                                            ?.translate("Cancel") ??
                                        "Cancel"),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(true),
                                    child: Text(AppLocalizations.of(context)
                                            ?.translate("Delete") ??
                                        "Delete"),
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
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const SleepAddAlarmView(),
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

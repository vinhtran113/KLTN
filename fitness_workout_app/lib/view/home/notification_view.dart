import 'package:fitness_workout_app/common_widget/notification_row_2.dart';
import 'package:fitness_workout_app/common_widget/notification_row_3.dart';
import 'package:flutter/material.dart';

import '../../common/colo_extension.dart';
import '../../common_widget/notification_row.dart';
import '../../services/notification_services.dart';
import '../../main.dart';
import '../../localization/app_localizations.dart';

class NotificationView extends StatefulWidget {
  const NotificationView({super.key});

  @override
  State<NotificationView> createState() => _NotificationViewState();
}

class _NotificationViewState extends State<NotificationView> {
  List<Map<String, String>> workoutNotificationArr = [];
  List<Map<String, String>> mealNotificationArr = [];
  List<Map<String, String>> alarmNotificationArr = [];
  bool darkmode = darkModeNotifier.value;
  int selectButton = 0;
  bool isLoading = true;
  bool isLoading1 = true;
  bool isLoading2 = true;

  @override
  void initState() {
    super.initState();
    loadWorkoutNotifications();
    loadMealNotifications();
    loadAlarmNotifications();
  }

  Future<void> loadWorkoutNotifications() async {
    setState(() {
      isLoading = true;
    });
    final loadedNotifications =
        await NotificationServices().loadWorkoutNotifications();

    // Lọc các thông báo có thời gian trong quá khứ
    final currentDateTime = DateTime.now();
    final filteredNotifications = loadedNotifications.where((notification) {
      DateTime notificationDate = DateTime.parse(notification['time']!);
      return notificationDate
          .isBefore(currentDateTime); // Giữ lại thông báo trong quá khứ
    }).toList();

    // Sắp xếp danh sách thông báo theo ngày từ tương lai đến quá khứ
    filteredNotifications.sort((a, b) {
      DateTime dateA =
          DateTime.parse(a['time']!); // Chuyển đổi chuỗi thành DateTime
      DateTime dateB = DateTime.parse(b['time']!);
      return dateB.compareTo(dateA); // Sắp xếp theo thứ tự tăng dần
    });

    setState(() {
      workoutNotificationArr = filteredNotifications;
      isLoading = false;
    });
  }

  Future<void> loadMealNotifications() async {
    setState(() {
      isLoading1 = true;
    });
    final loadedNotifications =
        await NotificationServices().loadMealNotifications();

    // Lọc các thông báo có thời gian trong quá khứ
    final currentDateTime = DateTime.now();
    final filteredNotifications = loadedNotifications.where((notification) {
      DateTime notificationDate = DateTime.parse(notification['time']!);
      return notificationDate
          .isBefore(currentDateTime); // Giữ lại thông báo trong quá khứ
    }).toList();

    // Sắp xếp danh sách thông báo theo ngày từ tương lai đến quá khứ
    filteredNotifications.sort((a, b) {
      DateTime dateA =
          DateTime.parse(a['time']!); // Chuyển đổi chuỗi thành DateTime
      DateTime dateB = DateTime.parse(b['time']!);
      return dateB.compareTo(dateA); // Sắp xếp theo thứ tự tăng dần
    });

    setState(() {
      mealNotificationArr = filteredNotifications;
      isLoading1 = false;
    });
  }

  Future<void> loadAlarmNotifications() async {
    setState(() {
      isLoading2 = true;
    });
    final loadedNotifications =
        await NotificationServices().loadAlarmNotifications();

    // Lọc các thông báo có thời gian trong quá khứ
    final currentDateTime = DateTime.now();
    final filteredNotifications = loadedNotifications.where((notification) {
      DateTime notificationDate = DateTime.parse(notification['time']!);
      return notificationDate
          .isBefore(currentDateTime); // Giữ lại thông báo trong quá khứ
    }).toList();

    // Sắp xếp danh sách thông báo theo ngày từ tương lai đến quá khứ
    filteredNotifications.sort((a, b) {
      DateTime dateA =
          DateTime.parse(a['time']!); // Chuyển đổi chuỗi thành DateTime
      DateTime dateB = DateTime.parse(b['time']!);
      return dateB.compareTo(dateA); // Sắp xếp theo thứ tự tăng dần
    });

    setState(() {
      alarmNotificationArr = filteredNotifications;
      isLoading2 = false;
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
          AppLocalizations.of(context)?.translate("Notification") ??
              "Notification",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
          child: Column(
            children: [
              Container(
                height: 55,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                    color: TColor.lightGray,
                    borderRadius: BorderRadius.circular(30)),
                child: Stack(alignment: Alignment.center, children: [
                  AnimatedContainer(
                    alignment: selectButton == 0
                        ? Alignment.centerLeft
                        : selectButton == 1
                            ? Alignment.center
                            : Alignment.centerRight,
                    duration: const Duration(milliseconds: 300),
                    child: Container(
                      width: (media.width - 40) / 3,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: TColor.primaryG),
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 40,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                selectButton = 0;
                              });
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(30)),
                              child: Text(
                                "Workout",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: selectButton == 0
                                        ? TColor.white
                                        : TColor.gray,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                selectButton = 1;
                              });
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(30)),
                              child: Text(
                                "Meal",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: selectButton == 1
                                        ? TColor.white
                                        : TColor.gray,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                selectButton = 2;
                              });
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(30)),
                              child: Text(
                                "Alarm",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: selectButton == 2
                                        ? TColor.white
                                        : TColor.gray,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                ]),
              ),
              if (selectButton == 0)
                if (isLoading)
                  const Center(child: CircularProgressIndicator())
                else if (workoutNotificationArr.isNotEmpty) ...[
                  ListView.separated(
                    padding:
                        const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                    itemBuilder: ((context, index) {
                      var nObj = workoutNotificationArr[index] as Map? ?? {};
                      return NotificationRow(nObj: nObj);
                    }),
                    separatorBuilder: (context, index) {
                      return Divider(
                        color: TColor.gray.withOpacity(0.5),
                        height: 1,
                      );
                    },
                    itemCount: workoutNotificationArr.length,
                    shrinkWrap: true, // Thêm dòng này
                    physics: NeverScrollableScrollPhysics(),
                  ),
                ] else
                  Center(
                    child: Text(
                      AppLocalizations.of(context)
                              ?.translate("No Notification") ??
                          "Not Notification",
                      style: const TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  ),
              if (selectButton == 1)
                if (isLoading1)
                  const Center(child: CircularProgressIndicator())
                else if (mealNotificationArr.isNotEmpty) ...[
                  ListView.separated(
                    padding:
                        const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                    itemBuilder: ((context, index) {
                      var nObj = mealNotificationArr[index] as Map? ?? {};
                      return NotificationRow2(nObj: nObj);
                    }),
                    separatorBuilder: (context, index) {
                      return Divider(
                        color: TColor.gray.withOpacity(0.5),
                        height: 1,
                      );
                    },
                    itemCount: mealNotificationArr.length,
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                  ),
                ] else
                  Center(
                    child: Text(
                      AppLocalizations.of(context)
                              ?.translate("No Notification") ??
                          "Not Notification",
                      style: const TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  ),
              if (selectButton == 2)
                if (isLoading2)
                  const Center(child: CircularProgressIndicator())
                else if (alarmNotificationArr.isNotEmpty) ...[
                  ListView.separated(
                    padding:
                        const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                    itemBuilder: ((context, index) {
                      var nObj = alarmNotificationArr[index] as Map? ?? {};
                      return NotificationRow3(nObj: nObj);
                    }),
                    separatorBuilder: (context, index) {
                      return Divider(
                        color: TColor.gray.withOpacity(0.5),
                        height: 1,
                      );
                    },
                    itemCount: alarmNotificationArr.length,
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                  ),
                ] else
                  Center(
                    child: Text(
                      AppLocalizations.of(context)
                              ?.translate("No Notification") ??
                          "Not Notification",
                      style: const TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../common/colo_extension.dart';
import '../../common_widget/notification_row.dart';
import '../../services/notification.dart';
import '../../main.dart';
import '../../localization/app_localizations.dart';

class NotificationView extends StatefulWidget {
  const NotificationView({super.key});

  @override
  State<NotificationView> createState() => _NotificationViewState();
}

class _NotificationViewState extends State<NotificationView> {
  List<Map<String, String>> notificationArr = [];
  bool darkmode = darkModeNotifier.value;

  @override
  void initState() {
    super.initState();
    loadNotifications(); // Gọi hàm tải dữ liệu
  }

  Future<void> loadNotifications() async {
    final loadedNotifications = await NotificationServices().loadNotificationArr();

    // Lọc các thông báo có thời gian trong quá khứ
    final currentDateTime = DateTime.now();
    final filteredNotifications = loadedNotifications.where((notification) {
      DateTime notificationDate = DateTime.parse(notification['time']!);
      return notificationDate.isBefore(currentDateTime); // Giữ lại thông báo trong quá khứ
    }).toList();

    // Sắp xếp danh sách thông báo theo ngày từ tương lai đến quá khứ
    filteredNotifications.sort((a, b) {
      DateTime dateA = DateTime.parse(a['time']!); // Chuyển đổi chuỗi thành DateTime
      DateTime dateB = DateTime.parse(b['time']!);
      return dateB.compareTo(dateA); // Sắp xếp theo thứ tự tăng dần
    });

    setState(() {
      notificationArr = filteredNotifications;
    });
  }

  @override
  Widget build(BuildContext context) {
    final message = ModalRoute.of(context)!.settings.arguments;
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
          AppLocalizations.of(context)?.translate("Notification") ?? "Notification",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 25),
          itemBuilder: ((context, index) {
            var nObj = notificationArr[index] as Map? ?? {};
            return NotificationRow(nObj: nObj);
          }), separatorBuilder: (context, index){
        return Divider(color: TColor.gray.withOpacity(0.5), height: 1, );
      }, itemCount: notificationArr.length),
    );
  }
}
import 'package:fitness_workout_app/common/colo_extension.dart';
import 'package:flutter/material.dart';

class NotificationRow3 extends StatelessWidget {
  final Map nObj;
  const NotificationRow3({super.key, required this.nObj});

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 60) {
      return "About ${difference.inMinutes} minutes ago";
    } else if (difference.inHours < 24) {
      return "About ${difference.inHours} hours ago";
    } else if (difference.inDays < 7) {
      return "${difference.inDays} days ago";
    } else {
      return "${time.day} ${_getMonthName(time.month)} ${time.year}";
    }
  }

  String _getMonthName(int month) {
    const months = [
      "January",
      "February",
      "March",
      "April",
      "May",
      "June",
      "July",
      "August",
      "September",
      "October",
      "November",
      "December"
    ];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    final String timeString = nObj["time"].toString();
    final String title = nObj["title"].toString();

    String assetImage;
    if (title == 'Bedtime Reminder') {
      assetImage = "assets/img/bed.png";
    } else if (title == 'Wake Up Alarm') {
      assetImage = "assets/img/alaarm.png";
    } else {
      assetImage = "assets/img/no_image.png";
    }

    // Chuyển đổi `time` từ chuỗi sang `DateTime`
    DateTime? time;
    try {
      time = DateTime.parse(timeString);
    } catch (e) {
      print("Error parsing time: $e");
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: Image.asset(
              assetImage,
              width: 40,
              height: 40,
              fit: BoxFit.cover,
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
                title,
                style: TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
              ),
              Text(
                time != null ? _formatTime(time) : "Invalid time",
                style: TextStyle(
                  color: TColor.gray,
                  fontSize: 10,
                ),
              ),
            ],
          )),
        ],
      ),
    );
  }
}

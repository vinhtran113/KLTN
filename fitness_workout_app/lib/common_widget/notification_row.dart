import 'package:fitness_workout_app/common/colo_extension.dart';
import 'package:flutter/material.dart';

import 'package:fitness_workout_app/common/colo_extension.dart';
import 'package:flutter/material.dart';

import '../main.dart';
import '../view/workout_tracker/workour_detail_view.dart';

class NotificationRow extends StatelessWidget {
  final Map nObj;
  const NotificationRow({super.key, required this.nObj});

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
      return "${time.day} ${_getMonthName(time.month)}";
    }
  }

  String _getMonthName(int month) {
    const months = [
      "January", "February", "March", "April", "May", "June",
      "July", "August", "September", "October", "November", "December"
    ];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    final String imageUrl = nObj["image"].toString();
    final String title = nObj["title"].toString();
    final String timeString = nObj["time"].toString();

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
            child: Image.network(
              imageUrl,
              width: 40,
              height: 40,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                        (loadingProgress.expectedTotalBytes ?? 1)
                        : null,
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 40,
                  height: 40,
                  color: TColor.lightGray,
                  child: Icon(Icons.image_not_supported, color: TColor.gray),
                );
              },
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
                    style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 12),
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
          IconButton(
              onPressed: () {
                navigatorKey.currentState?.push(
                  MaterialPageRoute(
                    builder: (context) => WorkoutDetailView(dObj: nObj),
                  ),
                );
              },
              icon: Image.asset(
                "assets/img/next_icon.png",
                width: 20,
                height: 20,
                fit: BoxFit.contain,
              ))
        ],
      ),
    );
  }
}

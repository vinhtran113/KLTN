import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../common/colo_extension.dart';
import '../../localization/app_localizations.dart';
import '../../main.dart';

class StatisticsChartView extends StatefulWidget {
  const StatisticsChartView({super.key});

  @override
  State<StatisticsChartView> createState() => _StatisticsChartViewState();
}

class _StatisticsChartViewState extends State<StatisticsChartView> {
  bool darkmode = darkModeNotifier.value;
  String _selectedView = "Month"; // Chế độ mặc định: Xem theo tháng
  String _selectedType = "Workout";

  Future<Map<String, double>> fetchCaloriesData() async {
    // Lấy dữ liệu từ Firebase
    final snapshot = await FirebaseFirestore.instance
        .collection('WorkoutHistory')
        .where('uid', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
        .get();

    final Map<String, double> caloriesData = {};

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final date = DateTime.fromMillisecondsSinceEpoch(
        data['completedAt'].seconds * 1000,
      );
      final calories = data['caloriesBurned'] as int;

      if (_selectedView == "Month") {
        // Gom dữ liệu theo tháng
        final monthKey = DateFormat('yyyy-MM').format(date);
        caloriesData[monthKey] =
            (caloriesData[monthKey] ?? 0) + calories.toDouble();
      } else {
        // Gom dữ liệu theo năm
        final yearKey = DateFormat('yyyy').format(date);
        caloriesData[yearKey] =
            (caloriesData[yearKey] ?? 0) + calories.toDouble();
      }
    }

    return caloriesData;
  }

  Future<Map<String, double>> fetchMealCaloriesData() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('MealSchedules')
        .where('uid', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
        .get();

    final Map<String, double> caloriesData = {};

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final date = DateTime.parse(data['date']);
      double totalCalories = 0.0;

      for (final type in ['breakfast', 'lunch', 'dinner', 'snacks']) {
        if (data.containsKey(type)) {
          final List<dynamic> meals = data[type];
          for (final meal in meals) {
            totalCalories += (meal['totalCalories'] ?? 0.0) as num;
          }
        }
      }

      if (_selectedView == "Month") {
        final monthKey = DateFormat('yyyy-MM').format(date);
        caloriesData[monthKey] = (caloriesData[monthKey] ?? 0) + totalCalories;
      } else {
        final yearKey = DateFormat('yyyy').format(date);
        caloriesData[yearKey] = (caloriesData[yearKey] ?? 0) + totalCalories;
      }
    }

    return caloriesData;
  }

  Future<Map<String, double>> fetchSleepData() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('Alarm')
        .where('uid', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
        .get();

    final Map<String, double> sleepData = {};

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final day = data['day'];
      final hourBed = data['hourBed'];
      final hourWakeup = data['hourWakeup'];
      final repeatInterval = data['repeat_interval'];

      DateTime date;
      try {
        date = DateFormat('dd/MM/yyyy').parse(day);
      } catch (_) {
        continue;
      }
      DateTime bedTime = DateFormat('hh:mm a').parse(hourBed);
      DateTime wakeTime = DateFormat('hh:mm a').parse(hourWakeup);

      DateTime bedDateTime = DateTime(
          date.year, date.month, date.day, bedTime.hour, bedTime.minute);
      DateTime wakeDateTime = DateTime(
          date.year, date.month, date.day, wakeTime.hour, wakeTime.minute);
      if (wakeDateTime.isBefore(bedDateTime)) {
        wakeDateTime = wakeDateTime.add(Duration(days: 1));
      }
      double sleepHours = wakeDateTime.difference(bedDateTime).inMinutes / 60.0;

      if (repeatInterval == "Everyday") {
        // Lặp lại mỗi ngày trong tháng/năm
        DateTime start = date;
        DateTime end = _selectedView == "Month"
            ? DateTime(date.year, date.month + 1, 0)
            : DateTime(date.year + 1, 1, 0);
        for (DateTime d = start;
            d.isBefore(end) || d.isAtSameMomentAs(end);
            d = d.add(Duration(days: 1))) {
          final key = _selectedView == "Month"
              ? DateFormat('yyyy-MM').format(d)
              : DateFormat('yyyy').format(d);
          sleepData[key] = (sleepData[key] ?? 0) + sleepHours;
        }
      } else if (repeatInterval.contains(',')) {
        // Lặp lại các ngày trong tuần
        List<String> daysOfWeek = repeatInterval.split(',');
        Set<int> weekdaysSet = daysOfWeek
            .map((e) => _getWeekdayFromString(e.trim()))
            .where((w) => w != -1)
            .toSet();

        DateTime start = date;
        DateTime end = _selectedView == "Month"
            ? DateTime(date.year, date.month + 1, 0)
            : DateTime(date.year + 1, 1, 0);
        for (DateTime d = start;
            d.isBefore(end) || d.isAtSameMomentAs(end);
            d = d.add(Duration(days: 1))) {
          if (weekdaysSet.contains(d.weekday)) {
            final key = _selectedView == "Month"
                ? DateFormat('yyyy-MM').format(d)
                : DateFormat('yyyy').format(d);
            sleepData[key] = (sleepData[key] ?? 0) + sleepHours;
          }
        }
      } else {
        // Không lặp lại, chỉ tính đúng ngày
        final key = _selectedView == "Month"
            ? DateFormat('yyyy-MM').format(date)
            : DateFormat('yyyy').format(date);
        sleepData[key] = (sleepData[key] ?? 0) + sleepHours;
      }
    }

    return sleepData;
  }

  // Hàm chuyển tên ngày sang số thứ tự (Monday = 1, ..., Sunday = 7)
  int _getWeekdayFromString(String day) {
    switch (day.toLowerCase()) {
      case 'monday':
        return DateTime.monday;
      case 'tuesday':
        return DateTime.tuesday;
      case 'wednesday':
        return DateTime.wednesday;
      case 'thursday':
        return DateTime.thursday;
      case 'friday':
        return DateTime.friday;
      case 'saturday':
        return DateTime.saturday;
      case 'sunday':
        return DateTime.sunday;
      default:
        return -1;
    }
  }

  Future<Map<String, double>> getSelectedData() {
    if (_selectedType == "Workout") return fetchCaloriesData();
    if (_selectedType == "Meal") return fetchMealCaloriesData();
    return fetchSleepData();
  }

  @override
  Widget build(BuildContext context) {
    String chartTitle;
    if (_selectedType == "Workout") {
      chartTitle = "Workout Calories Burned";
    } else if (_selectedType == "Meal") {
      chartTitle = "Meal Calories Intake";
    } else {
      chartTitle = "Sleep Duration";
    }

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
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              chartTitle,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButton<String>(
                    value: _selectedType,
                    isExpanded: true,
                    items: [
                      DropdownMenuItem(
                          value: "Workout", child: Text("Workout")),
                      DropdownMenuItem(value: "Meal", child: Text("Meal")),
                      DropdownMenuItem(value: "Sleep", child: Text("Sleep")),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedType = value!;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButton<String>(
                    value: _selectedView,
                    isExpanded: true,
                    items: [
                      DropdownMenuItem(value: "Month", child: Text("Month")),
                      DropdownMenuItem(value: "Year", child: Text("Year")),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedView = value!;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              elevation: 6,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: FutureBuilder<Map<String, double>>(
                  future: getSelectedData(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError || snapshot.data == null) {
                      return const Center(child: Text("Error loading data"));
                    }

                    final data = snapshot.data!;
                    final barGroups = data.entries.map((entry) {
                      final key = entry.key;
                      final value = entry.value;
                      return BarChartGroupData(
                        x: int.parse(key.split('-').last),
                        barRods: [
                          BarChartRodData(
                            toY: value,
                            color: _selectedType == "Workout"
                                ? Colors.blue
                                : _selectedType == "Meal"
                                    ? Colors.green
                                    : Colors.purple,
                            width: 15,
                            borderRadius: BorderRadius.circular(6),
                            gradient: LinearGradient(
                              colors: _selectedType == "Workout"
                                  ? [Colors.blueAccent, Colors.lightBlueAccent]
                                  : _selectedType == "Meal"
                                      ? [Colors.green, Colors.lightGreenAccent]
                                      : [
                                          Colors.purple,
                                          Colors.deepPurpleAccent
                                        ],
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                            ),
                          ),
                        ],
                      );
                    }).toList();

                    return BarChart(
                      BarChartData(
                        barGroups: barGroups,
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 40,
                              interval: _selectedType == "Sleep" ? 10 : 500,
                              getTitlesWidget: (value, meta) {
                                return Text(
                                  _selectedType == "Sleep"
                                      ? '${value.toInt()} Giờ'
                                      : '${value.toInt()} KCal',
                                  style: const TextStyle(fontSize: 12),
                                );
                              },
                            ),
                          ),
                          topTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                return Text(
                                  _selectedView == "Month"
                                      ? 'Tháng ${value.toInt()}'
                                      : '${value.toInt()}',
                                  style: const TextStyle(fontSize: 12),
                                );
                              },
                            ),
                          ),
                        ),
                        borderData: FlBorderData(
                          border: Border.all(color: Colors.grey),
                        ),
                        gridData: FlGridData(
                          show: true,
                          horizontalInterval:
                              _selectedType == "Sleep" ? 10 : 500,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Text(
              _selectedType == "Workout"
                  ? "Tổng calo tiêu hao qua các bài tập."
                  : _selectedType == "Meal"
                      ? "Tổng calo nạp vào qua các bữa ăn."
                      : "Tổng thời gian nghỉ/ngủ (giờ).",
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 13,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

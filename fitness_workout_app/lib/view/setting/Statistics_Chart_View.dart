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
        caloriesData[monthKey] = (caloriesData[monthKey] ?? 0) + calories.toDouble();
      } else {
        // Gom dữ liệu theo năm
        final yearKey = DateFormat('yyyy').format(date);
        caloriesData[yearKey] = (caloriesData[yearKey] ?? 0) + calories.toDouble();
      }
    }

    return caloriesData;
  }

  @override
  Widget build(BuildContext context) {
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
          AppLocalizations.of(context)?.translate("Calories Burned Chart") ?? "Calories Burned Chart",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
        ),
      ),
      body: Column(
        children: [
          // Dropdown chọn chế độ xem
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppLocalizations.of(context)?.translate("View by:") ?? "View by:",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                DropdownButton<String>(
                  value: _selectedView,
                  items:[
                    DropdownMenuItem(value: "Month", child: Text(AppLocalizations.of(context)?.translate("Month") ?? "Month")),
                    DropdownMenuItem(value: "Year", child: Text(AppLocalizations.of(context)?.translate("Year") ?? "Year")),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedView = value!;
                    });
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<Map<String, double>>(
              future: fetchCaloriesData(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError || snapshot.data == null) {
                  return const Center(child: Text("Error loading data"));
                }

                final caloriesData = snapshot.data!;
                final barGroups = caloriesData.entries.map((entry) {
                  final key = entry.key;
                  final calories = entry.value;
                  return BarChartGroupData(
                    x: int.parse(key.split('-').last), // Tháng hoặc Năm
                    barRods: [
                      BarChartRodData(
                        toY: calories,
                        color: Colors.blue,
                        width: 15,
                      ),
                    ],
                  );
                }).toList();

                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: BarChart(
                    BarChartData(
                      barGroups: barGroups,
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false), // Tắt trục Y bên trái
                        ),
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            interval: 200, // Khoảng cách giữa các điểm trên trục Y
                            getTitlesWidget: (value, meta) {
                              return Text(
                                '${value.toInt()} KCal',
                                style: const TextStyle(fontSize: 12),
                              );
                            },
                          ),
                        ),
                        topTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false), // Tắt trục trên
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
                        horizontalInterval: 200, // Đường kẻ ngang tương ứng khoảng cách trục Y
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fitness_workout_app/model/user_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../common/colo_extension.dart';
import '../../main.dart';
import '../../services/photo_service.dart';
import 'result_view.dart';

class ComparisonView extends StatefulWidget {
  final UserModel user;
  const ComparisonView({super.key, required this.user});

  @override
  State<ComparisonView> createState() => _ComparisonViewState();
}

class _ComparisonViewState extends State<ComparisonView> {
  DateTime? date1;
  DateTime? date2;
  List<Map<String, dynamic>> photosDay1 = [];
  List<Map<String, dynamic>> photosDay2 = [];
  bool loading1 = false;
  bool loading2 = false;
  bool darkmode = darkModeNotifier.value;

  Future<void> selectDate(int index) async {
    final now = DateTime.now();
    final initialDate = index == 1 ? date1 ?? now : date2 ?? now;

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      final timestamp = Timestamp.fromDate(
        DateTime(picked.year, picked.month, picked.day),
      );

      setState(() {
        if (index == 1) {
          date1 = picked;
          loading1 = true;
        } else {
          date2 = picked;
          loading2 = true;
        }
      });

      final photos = await PhotoService.getPhotosByDate(
        uid: widget.user.uid,
        dateOnly: timestamp,
      );

      setState(() {
        if (index == 1) {
          photosDay1 = photos;
          loading1 = false;
        } else {
          photosDay2 = photos;
          loading2 = false;
        }
      });

      if (photos.isEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No photos found for this date")),
        );
      }
    }
  }

  void applyQuickSuggestion(Duration duration) {
    if (date1 != null) {
      final suggestedDate = date1!.subtract(duration);
      selectDateWithFixedValue(2, suggestedDate);
    }
  }

  void selectDateWithFixedValue(int index, DateTime value) async {
    final timestamp =
        Timestamp.fromDate(DateTime(value.year, value.month, value.day));

    setState(() {
      if (index == 2) {
        date2 = value;
        loading2 = true;
      }
    });

    final photos = await PhotoService.getPhotosByDate(
        uid: widget.user.uid, dateOnly: timestamp);

    setState(() {
      photosDay2 = photos;
      loading2 = false;
    });

    if (photos.isEmpty && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No photos found for this date.")),
      );
    }
  }

  String formatDate(DateTime? date) {
    if (date == null) return "Select date";
    return DateFormat('dd/MM/yyyy').format(date);
  }

  Widget buildDateCard(
    String label,
    DateTime? date,
    VoidCallback onTap,
    bool loading,
    List<Map<String, dynamic>> photos,
  ) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(label,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: onTap,
              icon: const Icon(Icons.calendar_today),
              label: Text(formatDate(date)),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                backgroundColor: Colors.blueAccent,
              ),
            ),
            const SizedBox(height: 16),
            if (loading)
              const Center(child: CircularProgressIndicator())
            else if (photos.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 4,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1,
                  children: photos.map((photo) {
                    final style = photo['style'] ?? 'Unknown';
                    final imageUrl = photo['imageUrl'] ?? '';
                    return Column(
                      children: [
                        Text(style,
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w500)),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            imageUrl,
                            width: 68,
                            height: 68,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              )
            else
              const Center(child: Text("No photos found for this date.")),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: darkmode ? Colors.black : Colors.white,
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
        title: const Text(
          "Comparison",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            buildDateCard(
                "Day After", date1, () => selectDate(1), loading1, photosDay1),
            SizedBox(height: media.height * 0.01),
            Align(
              alignment: Alignment.centerLeft,
              child: Text("Suggested comparison date selection:",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            ),
            SizedBox(height: media.height * 0.01),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                "1 week ago",
                "2 weeks ago",
                "1 month ago",
                "3 month ago",
                "6 month ago",
                "1 year ago",
              ].map((label) {
                final duration = {
                  "1 week ago": const Duration(days: 7),
                  "2 weeks ago": const Duration(days: 14),
                  "1 month ago": const Duration(days: 30),
                  "3 month ago": const Duration(days: 90),
                  "6 month ago": const Duration(days: 180),
                  "1 year ago": const Duration(days: 365),
                }[label]!;
                return GestureDetector(
                  onTap: () => applyQuickSuggestion(duration),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade400),
                    ),
                    child: Text(label, style: const TextStyle(fontSize: 13)),
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: media.height * 0.01),
            buildDateCard(
                "Day Before", date2, () => selectDate(2), loading2, photosDay2),
            SizedBox(height: media.height * 0.03),
            if (date1 != null &&
                date2 != null &&
                (date1 == date2 || !date2!.isBefore(date1!)))
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  "⚠️ The day before must be DIFFERENT from the day after and NOT exceed the day after.",
                  style: TextStyle(color: Colors.red.shade700),
                  textAlign: TextAlign.center,
                ),
              ),
            SizedBox(height: media.height * 0.015),
            Padding(
              padding: const EdgeInsets.all(12),
              child: ElevatedButton(
                onPressed: date1 != null &&
                        date2 != null &&
                        photosDay1.isNotEmpty &&
                        photosDay2.isNotEmpty &&
                        date1 != date2 &&
                        date2!.isBefore(date1!)
                    ? () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ResultView(
                                date1: date1!,
                                date2: date2!,
                                photosDay1: photosDay1,
                                photosDay2: photosDay2,
                                user: widget.user),
                          ),
                        );
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: date1 != null &&
                          date2 != null &&
                          photosDay1.isNotEmpty &&
                          photosDay2.isNotEmpty &&
                          date1 != date2 &&
                          date2!.isBefore(date1!)
                      ? TColor.primaryColor1
                      : Colors.grey.shade400,
                  foregroundColor: Colors.white,
                ),
                child: const Text("View Result"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

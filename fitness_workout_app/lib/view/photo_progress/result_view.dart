import 'package:fitness_workout_app/model/user_model.dart';
import 'package:flutter/material.dart';
import 'package:simple_animation_progress_bar/simple_animation_progress_bar.dart';
import 'package:share_plus/share_plus.dart';
import 'package:screenshot/screenshot.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

import '../../common/colo_extension.dart';
import '../../common/common.dart';

class ResultView extends StatefulWidget {
  final DateTime date1;
  final DateTime date2;
  final List<Map<String, dynamic>> photosDay1;
  final List<Map<String, dynamic>> photosDay2;
  final UserModel user;

  const ResultView(
      {super.key,
      required this.date1,
      required this.date2,
      required this.photosDay1,
      required this.photosDay2,
      required this.user});

  @override
  State<ResultView> createState() => _ResultViewState();
}

class _ResultViewState extends State<ResultView> {
  int selectButton = 0;
  int progressScore = 0;
  double progressRatio = 0.0;
  String progressLabel = "";
  String progressMessage = "";
  Color progressColor = Colors.grey;
  List<Map<String, dynamic>> imaArr = [];
  List statArr = [];
  final ScreenshotController screenshotController = ScreenshotController();

  @override
  void initState() {
    super.initState();

    final statsDay1 = extractBodyStats(widget.photosDay1);
    final statsDay2 = extractBodyStats(widget.photosDay2);
    final loadStatarr = buildStatArr(statsDay1, statsDay2);

    final result = calculateProgress(
      weightBefore: statsDay2['weight']!,
      weightAfter: statsDay1['weight']!,
      bodyFatBefore: statsDay2['bodyFat']!,
      bodyFatAfter: statsDay1['bodyFat']!,
      height: statsDay1['height']!,
      goal: widget.user.level,
    );

    final score = result['score'];
    final message = result['message'];
    final progress = getProgressDisplay(score);
    final loadImaarr =
        buildImageComparisonList(widget.photosDay1, widget.photosDay2);

    setState(() {
      progressScore = score;
      progressMessage = message;
      progressColor = progress['color'];
      progressLabel = progress['label'];
      progressRatio = score / 100;
      imaArr = loadImaarr;
      statArr = loadStatarr;
    });
  }

  Map<String, double> extractBodyStats(List<Map<String, dynamic>> photos) {
    if (photos.isEmpty) {
      return {
        'weight': 0.0,
        'height': 0.0,
        'bodyFat': 0.0,
      };
    }

    final photo = photos.first;

    return {
      'weight': double.tryParse(photo['weight']?.toString() ?? '') ?? 0.0,
      'height': double.tryParse(photo['height']?.toString() ?? '') ?? 0.0,
      'bodyFat': double.tryParse(photo['bodyFat']?.toString() ?? '') ?? 0.0,
    };
  }

  List<Map<String, dynamic>> buildImageComparisonList(
    List<Map<String, dynamic>> photosDay1,
    List<Map<String, dynamic>> photosDay2,
  ) {
    const fallbackImage = "assets/img/no_image.png";
    final styles = [
      "Front Facing",
      "Back Facing",
      "Left Facing",
      "Right Facing"
    ];

    String? findImage(List<Map<String, dynamic>> photos, String style) {
      try {
        return photos.firstWhere((p) => p['style'] == style)['imageUrl'];
      } catch (e) {
        return null;
      }
    }

    return styles.map((style) {
      final image1 = findImage(photosDay1, style);
      final image2 = findImage(photosDay2, style);
      return {
        "title": style,
        "image_day_1": image1 ?? fallbackImage,
        "image_day_2": image2 ?? fallbackImage,
      };
    }).toList();
  }

  List<Map<String, dynamic>> buildStatArr(
    Map<String, double> stat1,
    Map<String, double> stat2,
  ) {
    double diffPercent(double a, double b) {
      if (a == 0) return 0.0;
      return ((b - a) / a) * 100.0;
    }

    return [
      {
        "title": "Lose Weight",
        "diff_per": diffPercent(stat1["weight"]!, stat2["weight"]!)
            .abs()
            .toStringAsFixed(0),
        "month_1_per": "${stat1["weight"]?.toStringAsFixed(0)}kg",
        "month_2_per": "${stat2["weight"]?.toStringAsFixed(0)}kg",
      },
      {
        "title": "Height Increase",
        "diff_per":
            diffPercent(stat1["height"]!, stat2["height"]!).toStringAsFixed(0),
        "month_1_per": "${stat1["height"]?.toStringAsFixed(0)}cm",
        "month_2_per": "${stat2["height"]?.toStringAsFixed(0)}cm",
      },
      {
        "title": "Body Fat Reduction",
        "diff_per": diffPercent(stat1["bodyFat"]!, stat2["bodyFat"]!)
            .abs()
            .toStringAsFixed(0),
        "month_1_per": "${stat1["bodyFat"]?.toStringAsFixed(0)}%",
        "month_2_per": "${stat2["bodyFat"]?.toStringAsFixed(0)}%",
      },
    ];
  }

  Map<String, dynamic> getProgressDisplay(int score) {
    String label;
    Color color;

    if (score >= 80) {
      label = "Excellent";
      color = const Color(0xFF6DD570); // Green
    } else if (score >= 60) {
      label = "Good";
      color = const Color(0xFFB6D94C); // Light Green/Yellow
    } else if (score >= 40) {
      label = "Average";
      color = const Color(0xFFFFC107); // Orange
    } else {
      label = "Poor";
      color = const Color(0xFFFF4C4C); // Red
    }

    return {
      "label": label,
      "color": color,
    };
  }

  Map<String, dynamic> calculateProgress({
    required double weightBefore,
    required double weightAfter,
    required double bodyFatBefore,
    required double bodyFatAfter,
    required double height, // tính theo cm
    required String goal,
  }) {
    double weightChange = weightAfter - weightBefore;
    double fatChange = bodyFatAfter - bodyFatBefore;
    double bmi = weightAfter / ((height / 100) * (height / 100));

    int score = 50;
    String message = "";

    if (goal.toLowerCase() != "lose a fat" && bmi > 27) {
      return {
        'score': 20,
        'message':
            "⚠️ Your BMI is already quite high. You should not gain any more weight."
      };
    }

    // ⚠️ Cảnh báo BMI quá cao hoặc quá thấp
    if (bmi >= 30) {
      return {
        'score': 10,
        'message':
            "⚠️ Your BMI is in the obese range. Please adjust your diet and exercise."
      };
    }

    if (bmi < 18.5) {
      return {
        'score': 15,
        'message':
            "⚠️ Your BMI is in the underweight range. You need to improve your nutrition and exercise."
      };
    }

    // ✅ Phân tích theo mục tiêu cụ thể
    switch (goal.toLowerCase()) {
      case "lose a fat":
        if (weightChange < -0.2 && fatChange < -0.2) {
          score = 90;
          message = "🎯 You're losing weight and fat very well!";
        } else if (weightChange > 0.3) {
          score = 20;
          message =
              "⚠️ Your weight is increasing, contrary to the goal of losing fat.";
        } else {
          score = 60;
          message =
              "🔄 The progress is stable, but there is room for improvement.";
        }
        break;

      case "improve shape":
        if (weightChange > 0.2 && fatChange < 0.2) {
          score = 90;
          message = "💪 You're gaining muscle effectively!";
        } else if (fatChange > 1.0) {
          score = 30;
          message = "⚠️ You may be gaining more fat than muscle.";
        } else {
          score = 60;
          message = "🔄 The progress is stable, keep it up.";
        }
        break;

      case "lean & tone":
        if (weightChange.abs() < 0.2 && fatChange.abs() < 0.2) {
          score = 85;
          message = "✅ You're maintaining your shape very well!";
        } else {
          score = 40;
          message = "⚠️ Your weight or fat is changing inconsistently.";
        }
        break;

      default:
        score = 20;
        message = "❓ Unable to determine the goal.";
    }

    return {
      'score': score.clamp(0, 100),
      'message': message,
    };
  }

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: TColor.white,
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
          "Result",
          style: TextStyle(
              color: TColor.black, fontSize: 16, fontWeight: FontWeight.w700),
        ),
        actions: [
          InkWell(
            onTap: () async {
              final image = await screenshotController.capture();
              if (image != null) {
                final tempDir = await getTemporaryDirectory();
                final file = await File('${tempDir.path}/result.png').create();
                await file.writeAsBytes(image);
                await Share.shareXFiles([XFile(file.path)],
                    text: 'My fitness progress result!');
              }
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
                "assets/img/share.png",
                width: 15,
                height: 15,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
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
                        : Alignment.centerRight,
                    duration: const Duration(milliseconds: 300),
                    child: Container(
                      width: (media.width * 0.5) - 40,
                      height: 40,
                      decoration: BoxDecoration(
                          gradient: LinearGradient(colors: TColor.primaryG),
                          borderRadius: BorderRadius.circular(30)),
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
                                "Photo",
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
                                "Statistic",
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
                      ],
                    ),
                  )
                ]),
              ),

              const SizedBox(
                height: 20,
              ),

              //Photo Tab UI
              if (selectButton == 0)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Average Progress",
                          style: TextStyle(
                              color: TColor.black,
                              fontSize: 16,
                              fontWeight: FontWeight.w700),
                        ),
                        Text(
                          progressLabel,
                          style: TextStyle(
                            color: progressColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SimpleAnimationProgressBar(
                          height: 20,
                          width: media.width - 40,
                          backgroundColor: Colors.grey.shade100,
                          foregroundColor: progressColor,
                          ratio: progressRatio,
                          direction: Axis.horizontal,
                          curve: Curves.fastLinearToSlowEaseIn,
                          duration: const Duration(seconds: 2),
                          borderRadius: BorderRadius.circular(10),
                          gradientColor: LinearGradient(
                            colors: [
                              progressColor.withOpacity(0.8),
                              progressColor
                            ],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                        ),
                        Text(
                          "${(progressRatio * 100).toStringAsFixed(0)}%",
                          style: TextStyle(color: TColor.white, fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      progressMessage,
                      style: TextStyle(
                        color: progressScore < 50
                            ? Colors.red
                            : Colors.grey.shade800,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(
                      height: 15,
                    ),
                    // Only screenshot from here down
                    Screenshot(
                      controller: screenshotController,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                dateToString(widget.date2,
                                    formatStr: "dd MMMM, yyyy"),
                                style: TextStyle(
                                    color: TColor.gray,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700),
                              ),
                              Text(
                                dateToString(widget.date1,
                                    formatStr: "dd MMMM, yyyy"),
                                style: TextStyle(
                                    color: TColor.gray,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                          ListView.builder(
                            physics: const NeverScrollableScrollPhysics(),
                            shrinkWrap: true,
                            itemCount: imaArr.length,
                            itemBuilder: (context, index) {
                              var iObj = imaArr[index];

                              Widget imageWidget(String imagePath) {
                                if (imagePath.startsWith("http")) {
                                  return Image.network(
                                    imagePath,
                                    width: double.infinity,
                                    height: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Image.asset(
                                          "assets/img/no_image.png",
                                          fit: BoxFit.cover);
                                    },
                                  );
                                } else {
                                  return Image.asset(
                                    imagePath,
                                    width: double.infinity,
                                    height: double.infinity,
                                    fit: BoxFit.cover,
                                  );
                                }
                              }

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  const SizedBox(height: 8),
                                  Text(
                                    iObj["title"].toString(),
                                    style: TextStyle(
                                        color: TColor.gray,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: AspectRatio(
                                          aspectRatio: 1,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: TColor.lightGray,
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              child: imageWidget(
                                                  iObj["image_day_2"]),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 15),
                                      Expanded(
                                        child: AspectRatio(
                                          aspectRatio: 1,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: TColor.lightGray,
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              child: imageWidget(
                                                  iObj["image_day_1"]),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

              // Statistic Tab UI
              if (selectButton == 1)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          dateToString(widget.date2,
                              formatStr: "dd MMMM, yyyy"),
                          style: TextStyle(
                              color: TColor.gray,
                              fontSize: 16,
                              fontWeight: FontWeight.w700),
                        ),
                        Text(
                          dateToString(widget.date1,
                              formatStr: "dd MMMM, yyyy"),
                          style: TextStyle(
                              color: TColor.gray,
                              fontSize: 16,
                              fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    ListView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      itemCount: statArr.length,
                      itemBuilder: (context, index) {
                        var iObj = statArr[index] as Map? ?? {};

                        double diffPer =
                            double.tryParse(iObj["diff_per"].toString()) ?? 0.0;

                        // Xác định chiều hướng và màu sắc
                        IconData trendIcon;
                        Color trendColor;

                        if (diffPer > 0) {
                          trendIcon = Icons.arrow_upward;
                          trendColor = Colors.redAccent;
                        } else if (diffPer < 0) {
                          trendIcon = Icons.arrow_downward;
                          trendColor = Colors.green;
                        } else {
                          trendIcon = Icons.remove;
                          trendColor = Colors.grey;
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const SizedBox(height: 15),
                            Text(
                              iObj["title"].toString(),
                              style: TextStyle(
                                  color: TColor.gray,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                SizedBox(
                                  width: 40,
                                  child: Text(
                                    iObj["month_2_per"].toString(),
                                    textAlign: TextAlign.right,
                                    style: TextStyle(
                                        color: TColor.gray, fontSize: 12),
                                  ),
                                ),
                                Expanded(
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: SimpleAnimationProgressBar(
                                          height: 10,
                                          width: media.width - 160,
                                          backgroundColor: TColor.primaryColor1,
                                          foregroundColor:
                                              trendColor.withOpacity(0.6),
                                          ratio: diffPer.abs() / 100.0,
                                          direction: Axis.horizontal,
                                          curve: Curves.fastLinearToSlowEaseIn,
                                          duration: const Duration(seconds: 3),
                                          borderRadius:
                                              BorderRadius.circular(5),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Icon(trendIcon,
                                          color: trendColor, size: 16),
                                    ],
                                  ),
                                ),
                                SizedBox(
                                  width: 40,
                                  child: Text(
                                    iObj["month_1_per"].toString(),
                                    textAlign: TextAlign.left,
                                    style: TextStyle(
                                      color: TColor.gray,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            )
                          ],
                        );
                      },
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

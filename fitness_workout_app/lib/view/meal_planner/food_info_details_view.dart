import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitness_workout_app/common/colo_extension.dart';
import 'package:fitness_workout_app/common_widget/round_button.dart';
import 'package:fitness_workout_app/view/meal_planner/food_review_view.dart';
import 'package:flutter/material.dart';
import 'package:readmore/readmore.dart';

import '../../common_widget/food_step_detail_row.dart';
import '../../model/meal_model.dart';
import 'add_meal_schedule_view.dart';

class FoodInfoDetailsView extends StatefulWidget {
  final Map mObj;
  final Meal dObj;
  const FoodInfoDetailsView(
      {super.key, required this.dObj, required this.mObj});

  @override
  State<FoodInfoDetailsView> createState() => _FoodInfoDetailsViewState();
}

class _FoodInfoDetailsViewState extends State<FoodInfoDetailsView> {
  List<Map<String, String>> nutritionArr = [];
  List<Map<String, String>> ingredientsArr = [];
  List<String> userMedicalHistory = [];
  List<String> warningRisks = [];

  // Thêm các biến cho review
  double avgRating = 0;
  int totalReviews = 0;

  @override
  void initState() {
    super.initState();
    nutritionArr = widget.dObj.nutri.toDisplayList();
    ingredientsArr = widget.dObj.getIngredientDisplayList();
    _loadReviewInfo();
    _loadUserMedicalHistory();
  }

  void _loadUserMedicalHistory() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final userDoc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final List<String> medicalHistory =
        List<String>.from(userDoc.data()?['medical_history'] ?? []);
    setState(() {
      userMedicalHistory = medicalHistory;
      // So sánh với health_risks của món ăn
      final List<String> healthRisks =
          List<String>.from(widget.dObj.healthRisks);
      warningRisks = healthRisks
          .where((risk) => userMedicalHistory.contains(risk))
          .toList();
    });
  }

  Future<void> _loadReviewInfo() async {
    final foodId = widget.dObj.id;
    final snapshot = await FirebaseFirestore.instance
        .collection('Meals')
        .doc(foodId)
        .collection('Reviews')
        .get();

    double total = 0;
    int count = 0;

    for (var doc in snapshot.docs) {
      final data = doc.data();
      if (data['rating'] != null) {
        total += (data['rating'] as num).toDouble();
        count++;
      }
    }
    setState(() {
      avgRating = count > 0 ? total / count : 0;
      totalReviews = count;
    });
  }

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;
    return Container(
      decoration:
          BoxDecoration(gradient: LinearGradient(colors: TColor.primaryG)),
      child: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              backgroundColor: Colors.transparent,
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
            ),
            SliverAppBar(
              backgroundColor: Colors.transparent,
              centerTitle: true,
              elevation: 0,
              leadingWidth: 0,
              leading: Container(),
              expandedHeight: media.width * 0.5,
              flexibleSpace: ClipRect(
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    Transform.scale(
                      scale: 1.25,
                      child: Container(
                        width: media.width * 0.55,
                        height: media.width * 0.55,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius:
                              BorderRadius.circular(media.width * 0.275),
                        ),
                      ),
                    ),
                    Transform.scale(
                      scale: 1.25,
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: (widget.dObj.image.toString().isNotEmpty)
                            ? Image.network(
                                widget.dObj.image.toString(),
                                width: media.width * 0.50,
                                height: media.width * 0.50,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return Image.asset(
                                    "assets/img/no_image.png",
                                    width: media.width * 0.50,
                                    height: media.width * 0.50,
                                    fit: BoxFit.contain,
                                  );
                                },
                              )
                            : Image.asset(
                                "assets/img/no_image.png",
                                width: media.width * 0.50,
                                height: media.width * 0.50,
                                fit: BoxFit.contain,
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ];
        },
        body: Container(
          decoration: BoxDecoration(
              color: TColor.white,
              borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(25), topRight: Radius.circular(25))),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: Stack(
              children: [
                SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 50,
                            height: 4,
                            decoration: BoxDecoration(
                                color: TColor.gray.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(3)),
                          ),
                        ],
                      ),
                      SizedBox(
                        height: media.width * 0.05,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (warningRisks.isNotEmpty)
                                    Container(
                                      margin: const EdgeInsets.symmetric(
                                          vertical: 8),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.red.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.red),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.warning,
                                              color: Colors.red),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              "Warning: This food may not be suitable for your medical condition(s): ${warningRisks.join(', ')}",
                                              style: const TextStyle(
                                                  color: Colors.red,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  Text(
                                    widget.dObj.name.toString(),
                                    style: TextStyle(
                                        color: TColor.black,
                                        fontSize: 22,
                                        fontWeight: FontWeight.w700),
                                  ),
                                  Text(
                                    "${widget.dObj.size.toString()} | ${widget.dObj.time.toString()} min",
                                    style: TextStyle(
                                        color: TColor.gray, fontSize: 12),
                                  ),
                                  Row(
                                    children: [
                                      Icon(Icons.star,
                                          color: Colors.amber, size: 18),
                                      SizedBox(width: 4),
                                      Text(
                                        avgRating.toStringAsFixed(1),
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                      SizedBox(width: 12),
                                      Icon(Icons.comment,
                                          color: Colors.grey, size: 18),
                                      SizedBox(width: 4),
                                      Text(
                                        '$totalReviews comments',
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                      Spacer(),
                                      TextButton(
                                        onPressed: () async {
                                          final result = await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  FoodReviewView(
                                                foodId: widget.dObj.id,
                                              ),
                                            ),
                                          );
                                          if (result == true) {
                                            _loadReviewInfo();
                                          }
                                        },
                                        child: Text('See All',
                                            style: TextStyle(
                                                color: TColor.gray,
                                                fontSize: 12)),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        child: Text(
                          "Nutrition",
                          style: TextStyle(
                              color: TColor.black,
                              fontSize: 16,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                      SizedBox(
                        height: 50,
                        child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            scrollDirection: Axis.horizontal,
                            shrinkWrap: true,
                            itemCount: nutritionArr.length,
                            itemBuilder: (context, index) {
                              final nObj = nutritionArr[index];
                              return Container(
                                  margin: const EdgeInsets.symmetric(
                                      vertical: 8, horizontal: 4),
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 8),
                                  decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          TColor.primaryColor2.withOpacity(0.4),
                                          TColor.primaryColor1.withOpacity(0.4)
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(10)),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Image.asset(
                                        nObj["image"]!,
                                        width: 15,
                                        height: 15,
                                        fit: BoxFit.contain,
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Text(
                                          nObj["title"]!,
                                          style: TextStyle(
                                              color: TColor.black,
                                              fontSize: 12),
                                        ),
                                      )
                                    ],
                                  ));
                            }),
                      ),
                      SizedBox(
                        height: media.width * 0.01,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        child: Text(
                          "Descriptions",
                          style: TextStyle(
                              color: TColor.black,
                              fontSize: 16,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(
                        height: 4,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        child: ReadMoreText(
                          widget.dObj.description.toString(),
                          trimLines: 4,
                          colorClickableText: TColor.black,
                          trimMode: TrimMode.Line,
                          trimCollapsedText: ' Read More ...',
                          trimExpandedText: ' Read Less',
                          style: TextStyle(
                            color: TColor.gray,
                            fontSize: 12,
                          ),
                          moreStyle: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                      ),
                      SizedBox(
                        height: media.width * 0.01,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Ingredients That You\nWill Need",
                              style: TextStyle(
                                  color: TColor.black,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700),
                            ),
                            TextButton(
                              onPressed: () {},
                              child: Text(
                                "${widget.dObj.ingredients.length} Items",
                                style:
                                    TextStyle(color: TColor.gray, fontSize: 12),
                              ),
                            )
                          ],
                        ),
                      ),
                      SizedBox(
                        height: (media.width * 0.25) + 40,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          scrollDirection: Axis.horizontal,
                          shrinkWrap: true,
                          itemCount: ingredientsArr.length,
                          itemBuilder: (context, index) {
                            var nObj = ingredientsArr[index] as Map? ?? {};
                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              width: media.width * 0.23,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: media.width * 0.23,
                                    height: media.width * 0.23,
                                    decoration: BoxDecoration(
                                      color: TColor.lightGray,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    alignment: Alignment.center,
                                    child: (nObj["image"] != null &&
                                            nObj["image"]
                                                .toString()
                                                .startsWith("http"))
                                        ? Image.network(
                                            nObj["image"].toString(),
                                            width: 80,
                                            height: 80,
                                            fit: BoxFit.contain,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                              return Image.asset(
                                                "assets/img/no_image.png",
                                                width: 45,
                                                height: 45,
                                                fit: BoxFit.contain,
                                              );
                                            },
                                          )
                                        : Image.asset(
                                            "assets/img/no_image.png",
                                            width: 45,
                                            height: 45,
                                            fit: BoxFit.contain,
                                          ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    nObj["title"].toString(),
                                    style: TextStyle(
                                        color: TColor.black, fontSize: 12),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    nObj["value"].toString(),
                                    style: TextStyle(
                                        color: TColor.gray, fontSize: 10),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Step by Step",
                              style: TextStyle(
                                  color: TColor.black,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700),
                            ),
                            TextButton(
                              onPressed: () {},
                              child: Text(
                                "${widget.dObj.recipe.length} Steps",
                                style:
                                    TextStyle(color: TColor.gray, fontSize: 12),
                              ),
                            )
                          ],
                        ),
                      ),
                      ListView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        shrinkWrap: true,
                        itemCount: widget.dObj.recipe.length,
                        itemBuilder: ((context, index) {
                          var sObj = widget.dObj.recipe[index + 1];
                          return FoodStepDetailRow(
                            sObj: sObj,
                            index: index,
                            isLast: widget.dObj.recipe.length == index + 1,
                          );
                        }),
                      ),
                      SizedBox(
                        height: media.width * 0.25,
                      ),
                    ],
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 15),
                          child: RoundButton(
                            title: "Add to ${widget.mObj["name"]} Meal",
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AddMealScheduleView(
                                    date: DateTime.now(),
                                    initialMeal: widget.dObj,
                                    initialMealType:
                                        widget.mObj["name"].toString(),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitness_workout_app/common_widget/meal_recommed_cell.dart';
import 'package:fitness_workout_app/view/meal_planner/recommend_meal_food_view.dart';
import 'package:flutter/material.dart';

import '../../common/colo_extension.dart';
import '../../common_widget/meal_category_cell.dart';
import '../../common_widget/popular_meal_row.dart';
import '../../common_widget/search_all_meal_row.dart';
import '../../model/meal_model.dart';
import '../../model/user_model.dart';
import '../../services/auth.dart';
import '../../services/meal.dart';
import 'all_meal_food_view.dart';
import 'food_info_details_view.dart';
import 'meal_by_category_view.dart';

class MealFoodDetailsView extends StatefulWidget {
  final Map eObj;
  const MealFoodDetailsView({super.key, required this.eObj});

  @override
  State<MealFoodDetailsView> createState() => _MealFoodDetailsViewState();
}

class _MealFoodDetailsViewState extends State<MealFoodDetailsView> {
  TextEditingController txtSearch = TextEditingController();
  final MealService _mealService = MealService();
  String level = '';

  List categoryArr = [
    {
      "name": "Main Dish",
      "image": "assets/img/fried-rice_icon.png",
    },
    {
      "name": "Side Dish",
      "image": "assets/img/c_1.png",
    },
    {
      "name": "Fast Food",
      "image": "assets/img/FastFoodIcon.png",
    },
    {
      "name": "Beverage",
      "image": "assets/img/healthy_drink_icon.png",
    },
    {
      "name": "Dessert",
      "image": "assets/img/c_4.png",
    },
    {
      "name": "Bakery & Snacks",
      "image": "assets/img/c_3.png",
    },
  ];

  List filteredCategoryArr = [];
  List<Meal> recommendArr = [];
  List<Meal> popularArr = [];
  List<Meal> allMealArr = [];
  List<Meal> filteredMeals = [];

  @override
  void initState() {
    super.initState();
    _loadMealsByRecommendAndLevel(widget.eObj["name"]);
    _loadPopularMeals(widget.eObj["name"]);
    _loadAllMeals();
    txtSearch.addListener(_onSearchChanged);

    if (widget.eObj["name"].toString() == "Snack") {
      filteredCategoryArr = categoryArr.where((category) {
        return category["name"] != "Main Dish" && category["name"] != "Side Dish";
      }).toList();
    } else {
      filteredCategoryArr = List.from(categoryArr);
    }
  }

  @override
  void dispose() {
    txtSearch.removeListener(_onSearchChanged);
    txtSearch.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    String keyword = txtSearch.text.trim().toLowerCase();
    setState(() {
      if (keyword.isEmpty) {
        filteredMeals = [];
      } else {
        filteredMeals = allMealArr
            .where((meal) => meal.name.toLowerCase().contains(keyword))
            .toList();
      }
    });
  }

  void _loadMealsByRecommendAndLevel(String mealType) async {
    UserModel? user = await AuthService().getUserInfo(
      FirebaseAuth.instance.currentUser!.uid,
    );

    if (user != null) {
      String lv = user.level;

      List<Meal> meals = await _mealService.fetchMealsByRecommendAndLevel(
        recommend: mealType,
        level: lv,
      );

      setState(() {
        level = lv;
        recommendArr = meals;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể lấy thông tin người dùng')),
      );
    }
  }

  void _loadPopularMeals(String mealType) async {
    try {
      List<Meal> meals = await _mealService.fetchMealsWithRecommend(
        recommend: mealType,
      );
      setState(() {
        popularArr = meals;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    }
  }

  void _loadAllMeals() async {
    try {
      List<Meal> meals = await _mealService.fetchAllMeals();
      setState(() {
        allMealArr = meals;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    }
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
          widget.eObj["name"].toString(),
          style: TextStyle(
              color: TColor.black, fontSize: 22, fontWeight: FontWeight.w700),
        ),
      ),
      backgroundColor: TColor.white,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                  color: TColor.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: const [
                    BoxShadow(
                        color: Colors.black12,
                        blurRadius: 2,
                        offset: Offset(0, 1))
                  ]),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: txtSearch,
                      decoration: InputDecoration(
                          focusedBorder: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          prefixIcon: Image.asset(
                            "assets/img/search.png",
                            width: 25,
                            height: 25,
                          ),
                          hintText: "Search here..."),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: media.width * 0.01,
            ),
            txtSearch.text.isNotEmpty
                ? (filteredMeals.isEmpty
                ? Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Text(
                  "Not Found",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ),
            ) : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 15.0),
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: filteredMeals.length,
              itemBuilder: (context, index) {
                Meal fObj = filteredMeals[index];
                return InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FoodInfoDetailsView(
                          dObj: fObj,
                          mObj: widget.eObj,
                        ),
                      ),
                    );
                  },
                  child: SearchAllMealRow(
                    mObj: fObj,
                    dObj: widget.eObj,
                  ),
                );
              },
            )) : SizedBox(),
            SizedBox(
              height: media.width * 0.03,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Category",
                    style: TextStyle(
                        color: TColor.black,
                        fontSize: 16,
                        fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 120,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 15.0),
                scrollDirection: Axis.horizontal,
                itemCount: filteredCategoryArr.length,
                itemBuilder: (context, index) {
                  var cObj = filteredCategoryArr[index] as Map? ?? {};
                  return InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MealsByCategoryView(
                            categoryName: cObj["name"],
                            mObj: widget.eObj,
                          ),
                        ),
                      );
                    },
                    child: MealCategoryCell(
                      cObj: cObj,
                      index: index,
                    ),
                  );
                },
              ),
            ),
            SizedBox(
              height: media.width * 0.05,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Recommendation\nfor ${level.toString()}",
                    style: TextStyle(
                        color: TColor.black,
                        fontSize: 16,
                        fontWeight: FontWeight.w700),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RecommendMealFoodView(
                            level: level.toString(),
                            mObj: widget.eObj,
                          ),
                        ),
                      );
                    },
                    child: Text(
                      "See All",
                      style:
                      TextStyle(color: TColor.gray, fontSize: 12),
                    ),
                  )
                ],
              ),
            ),
            SizedBox(
              height: media.width * 0.6,
              child: recommendArr.isEmpty ? Center(
                  child: Text(
                    'Not Found',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey,
                    ),
                ),
              ) : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 15.0),
                scrollDirection: Axis.horizontal,
                itemCount: recommendArr.length > 2 ? 2 : recommendArr.length,
                itemBuilder: (context, index) {
                  Meal fObj = recommendArr[index];
                  return MealRecommendCell(
                    fObj: fObj,
                    index: index,
                    mObj: widget.eObj,
                  );
                },
              ),
            ),
            SizedBox(
              height: media.width * 0.05,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Meal for ${widget.eObj["name"]}",
                    style: TextStyle(
                        color: TColor.black,
                        fontSize: 16,
                        fontWeight: FontWeight.w700),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AllMealFoodView(
                            mObj: widget.eObj,
                          ),
                        ),
                      );
                    },
                    child: Text(
                      "See All",
                      style:
                      TextStyle(color: TColor.gray, fontSize: 12),
                    ),
                  )
                ],
              ),
            ),
            popularArr.isEmpty ? Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Text(
                  "Not Found",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ),
            ) : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 15.0),
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: popularArr.length > 5 ? 5 : popularArr.length,
              itemBuilder: (context, index) {
                Meal fObj = popularArr[index];
                return InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FoodInfoDetailsView(
                          dObj: fObj,
                          mObj: widget.eObj,
                        ),
                      ),
                    );
                  },
                  child: PopularMealRow(
                    mObj: fObj,
                  ),
                );
              },
            ),
            SizedBox(
              height: media.width * 0.05,
            ),
          ],
        ),
      ),
    );
  }
}
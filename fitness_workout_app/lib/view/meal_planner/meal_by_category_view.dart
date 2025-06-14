import 'package:fitness_workout_app/common/colo_extension.dart';
import 'package:flutter/material.dart';
import '../../common_widget/search_all_meal_row.dart';
import '../../model/meal_model.dart';
import '../../services/meal_services.dart';
import '../../main.dart';
import '../../localization/app_localizations.dart';
import 'food_info_details_view.dart';

class MealsByCategoryView extends StatefulWidget {
  final Map mObj;
  final String categoryName;
  const MealsByCategoryView(
      {super.key, required this.categoryName, required this.mObj});

  @override
  State<MealsByCategoryView> createState() => _MealsByCategoryViewState();
}

class _MealsByCategoryViewState extends State<MealsByCategoryView> {
  final MealService _mealService = MealService();
  List<Meal> allMealByCateArr = [];
  List<Meal> filteredMeals = [];
  final TextEditingController _searchController = TextEditingController();
  bool darkmode = darkModeNotifier.value;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAllMealsByCate();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    String keyword = _searchController.text.trim().toLowerCase();
    setState(() {
      if (keyword.isEmpty) {
        // Trở lại danh sách được recommend
        filteredMeals = allMealByCateArr
            .where((meal) =>
                meal.recommend.contains(widget.mObj["name"].toLowerCase()))
            .toList();
      } else {
        filteredMeals = allMealByCateArr
            .where((meal) => meal.name.toLowerCase().contains(keyword))
            .toList();
      }
    });
  }

  void _loadAllMealsByCate() async {
    try {
      setState(() {
        isLoading = true;
      });
      List<Meal> meals = await _mealService.fetchAllMealsByCate(
        cate: widget.categoryName.toString(),
      );

      setState(() {
        allMealByCateArr = meals;

        // Lọc mặc định theo recommend
        filteredMeals = meals
            .where((meal) =>
                meal.recommend.contains(widget.mObj["name"].toLowerCase()))
            .toList();

        isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
      setState(() {
        isLoading = false;
      });
    }
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
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Image.asset(
                    "assets/img/black_btn.png",
                    width: 15,
                    height: 15,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              title: Text(
                AppLocalizations.of(context)?.translate(
                        "${widget.categoryName} of ${widget.mObj["name"]}") ??
                    "${widget.categoryName} of ${widget.mObj["name"]}",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
              ),
            ),
          ];
        },
        body: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: darkmode ? Colors.blueGrey[900] : TColor.white,
            borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(25), topRight: Radius.circular(25)),
          ),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: SizedBox(
                      width: double.infinity,
                      child: TextField(
                        controller: _searchController,
                        style: TextStyle(
                            color: darkmode ? TColor.white : TColor.black),
                        decoration: InputDecoration(
                          hintText: AppLocalizations.of(context)
                                  ?.translate("Search...") ??
                              "Search...",
                          hintStyle: TextStyle(
                              color: darkmode
                                  ? Colors.white.withOpacity(0.7)
                                  : Colors.black.withOpacity(0.7)),
                          filled: true,
                          fillColor: darkmode
                              ? Colors.white.withOpacity(0.1)
                              : Colors.grey.withOpacity(0.1),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 15, vertical: 10),
                        ),
                      ),
                    ),
                  ),
                  if (isLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (filteredMeals.isNotEmpty) ...[
                    ListView.builder(
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
                                  mObj: widget.mObj,
                                ),
                              ),
                            );
                          },
                          child: SearchAllMealRow(
                            mObj: fObj,
                            dObj: widget.mObj,
                          ),
                        );
                      },
                    ),
                  ] else
                    Center(
                      child: Text(
                        AppLocalizations.of(context)?.translate("Not Found") ??
                            "Not Found",
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    ),
                  SizedBox(height: media.width * 0.1),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

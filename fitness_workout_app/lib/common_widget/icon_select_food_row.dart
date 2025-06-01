import 'package:flutter/material.dart';
import '../common/colo_extension.dart';
import '../model/ingredient_model.dart';
import '../model/meal_model.dart';
import '../services/meal_services.dart';

class IconSelectFoodRow extends StatefulWidget {
  final String icon;
  final String title;
  final List<Meal> selectedMeals;
  final VoidCallback onPressed;
  final Color color;
  final Function(int) onRemove;
  final Function(int, int, double) onIngredientAmountChanged;

  const IconSelectFoodRow({
    super.key,
    required this.icon,
    required this.title,
    required this.selectedMeals,
    required this.onPressed,
    required this.color,
    required this.onRemove,
    required this.onIngredientAmountChanged,
  });

  @override
  State<IconSelectFoodRow> createState() => _IconSelectFoodRowState();
}

class _IconSelectFoodRowState extends State<IconSelectFoodRow> {
  List<Ingredient> availableIngredients = [];
  final MealService _mealService = MealService();

  @override
  void initState() {
    super.initState();
    _loadAvailableIngredients();
  }

  Future<void> _loadAvailableIngredients() async {
    final ingredients = await _mealService.fetchAvailableIngredients();
    setState(() {
      availableIngredients = ingredients;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 15),
      decoration: BoxDecoration(
        color: widget.color,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: widget.onPressed,
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  alignment: Alignment.center,
                  child: Image.asset(
                    widget.icon,
                    width: 18,
                    height: 18,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.title,
                    style: TextStyle(
                      color: TColor.gray,
                      fontSize: 12,
                    ),
                  ),
                ),
                const Icon(Icons.add, size: 20, color: Colors.blue),
              ],
            ),
          ),
          const SizedBox(height: 8),
          widget.selectedMeals.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    "No food selected",
                    style: TextStyle(color: TColor.gray, fontSize: 12),
                  ),
                )
              : Column(
                  children:
                      List.generate(widget.selectedMeals.length, (mealIndex) {
                    final meal = widget.selectedMeals[mealIndex];
                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: TColor.gray, width: 1),
                      ),
                      child: ExpansionTile(
                        tilePadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        childrenPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        expandedCrossAxisAlignment: CrossAxisAlignment.start,
                        expandedAlignment: Alignment.centerLeft,
                        title: Text(
                          meal.name,
                          style: TextStyle(color: TColor.black, fontSize: 13),
                        ),
                        children: [
                          ...meal.ingredients.asMap().entries.map((entry) {
                            final ingIndex = entry.key;
                            final ingredient = entry.value;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(
                                    flex: 4,
                                    child: Text(
                                      ingredient.name,
                                      style: TextStyle(
                                          color: TColor.gray, fontSize: 12),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: TextFormField(
                                      initialValue:
                                          ingredient.amount.toString(),
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                              decimal: true),
                                      style: const TextStyle(fontSize: 12),
                                      decoration: const InputDecoration(
                                        isDense: true,
                                        contentPadding: EdgeInsets.symmetric(
                                            vertical: 4, horizontal: 8),
                                        border: OutlineInputBorder(),
                                      ),
                                      onChanged: (val) {
                                        double? newAmount =
                                            double.tryParse(val);
                                        if (newAmount != null) {
                                          widget.onIngredientAmountChanged(
                                              mealIndex, ingIndex, newAmount);
                                        }
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      ingredient.unit.isNotEmpty
                                          ? ingredient.unit
                                          : "-", // luôn hiện đơn vị
                                      style: TextStyle(
                                          color: TColor.gray, fontSize: 12),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                        Icons.remove_circle_outline,
                                        size: 20,
                                        color: Colors.red),
                                    onPressed: () {
                                      setState(() {
                                        widget.selectedMeals[mealIndex]
                                            .ingredients
                                            .removeAt(ingIndex);
                                      });
                                    },
                                  ),
                                ],
                              ),
                            );
                          }),

                          // Thêm ingredient mới
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton.icon(
                              onPressed: () {
                                _showAddIngredientDialog(context, mealIndex);
                              },
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text(
                                "Add Ingredient",
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                          ),

                          // Xóa nguyên món ăn
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              onPressed: () => widget.onRemove(mealIndex),
                              icon: const Icon(Icons.delete,
                                  size: 18, color: Colors.red),
                              label: const Text(
                                "Remove",
                                style:
                                    TextStyle(color: Colors.red, fontSize: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
        ],
      ),
    );
  }

  void _showAddIngredientDialog(BuildContext context, int mealIndex) {
    Ingredient? selectedIngredient;
    double newAmount = 0;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Add New Ingredient"),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<Ingredient>(
                    value: selectedIngredient,
                    items: availableIngredients.map((ingredient) {
                      return DropdownMenuItem<Ingredient>(
                        value: ingredient,
                        child: Text(ingredient.name),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedIngredient = value;
                      });
                    },
                    decoration: const InputDecoration(
                      labelText: "Select Ingredient",
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (selectedIngredient != null)
                    Row(
                      children: [
                        const Text(
                          "Unit: ",
                          style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                        Text(
                          selectedIngredient!.unit,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                  const SizedBox(height: 12),
                  TextField(
                    decoration: const InputDecoration(labelText: "Amount"),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (val) {
                      newAmount = double.tryParse(val) ?? 0;
                    },
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              child: const Text("Cancel"),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              child: const Text("Add"),
              onPressed: () async {
                if (selectedIngredient != null && newAmount > 0) {
                  final existingIndex =
                      widget.selectedMeals[mealIndex].ingredients.indexWhere(
                    (ing) => ing.name == selectedIngredient!.name,
                  );

                  if (existingIndex != -1) {
                    // Đã tồn tại nguyên liệu, hỏi người dùng
                    final shouldReplace = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text("Ingredient Already Exists"),
                        content: const Text(
                            "This ingredient already exists. Do you want to replace it?"),
                        actions: [
                          TextButton(
                            child: const Text("No"),
                            onPressed: () => Navigator.pop(context, false),
                          ),
                          ElevatedButton(
                            child: const Text("Yes"),
                            onPressed: () => Navigator.pop(context, true),
                          ),
                        ],
                      ),
                    );

                    if (shouldReplace == true) {
                      Navigator.pop(
                          context); // Đóng Add Ingredient Dialog trước
                      setState(() {
                        widget.selectedMeals[mealIndex]
                            .ingredients[existingIndex] = Ingredient(
                          name: selectedIngredient!.name,
                          amount: newAmount,
                          unit: selectedIngredient!.unit,
                          image: selectedIngredient!.image,
                          nutri: selectedIngredient!.nutri,
                        );
                      });
                    }
                  } else {
                    Navigator.pop(context); // Đóng Add Ingredient Dialog trước
                    setState(() {
                      widget.selectedMeals[mealIndex].ingredients.add(
                        Ingredient(
                          name: selectedIngredient!.name,
                          amount: newAmount,
                          unit: selectedIngredient!.unit,
                          image: selectedIngredient!.image,
                          nutri: selectedIngredient!.nutri,
                        ),
                      );
                    });
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }
}

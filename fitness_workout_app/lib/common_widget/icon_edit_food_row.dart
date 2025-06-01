import 'package:flutter/material.dart';
import '../common/colo_extension.dart';
import '../model/ingredient_model.dart';
import '../model/meal_model.dart';
import '../services/meal_services.dart';

class IconEditFoodRow extends StatefulWidget {
  final String icon;
  final String title;
  final Meal selectedMeal;
  final Color color;
  final Function(int, double) onIngredientAmountChanged;

  const IconEditFoodRow({
    super.key,
    required this.icon,
    required this.title,
    required this.selectedMeal,
    required this.color,
    required this.onIngredientAmountChanged,
  });

  @override
  State<IconEditFoodRow> createState() => _IconEditFoodRowState();
}

class _IconEditFoodRowState extends State<IconEditFoodRow> {
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
    final meal = widget.selectedMeal;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 15),
      decoration: BoxDecoration(
        color: widget.color,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
            ],
          ),
          const SizedBox(height: 8),
          Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: TColor.gray, width: 1),
            ),
            child: ExpansionTile(
              tilePadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              childrenPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                      children: [
                        Expanded(
                            flex: 4,
                            child: Text(ingredient.name,
                                style: TextStyle(fontSize: 12))),
                        Expanded(
                          flex: 3,
                          child: TextFormField(
                            initialValue: ingredient.amount.toString(),
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            decoration: const InputDecoration(
                                isDense: true, border: OutlineInputBorder()),
                            onChanged: (val) {
                              double? newAmount = double.tryParse(val);
                              if (newAmount != null) {
                                widget.onIngredientAmountChanged(
                                    ingIndex, newAmount);
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
                                  : "-",
                              style: TextStyle(fontSize: 12)),
                        ),
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline,
                              size: 20, color: Colors.red),
                          onPressed: () {
                            setState(() {
                              meal.ingredients.removeAt(ingIndex);
                            });
                          },
                        ),
                      ],
                    ),
                  );
                }),

                // Add Ingredient
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () {
                      _showAddIngredientDialog(context);
                    },
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text("Add Ingredient",
                        style: TextStyle(fontSize: 12)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAddIngredientDialog(BuildContext context) {
    Ingredient? selectedIngredient;
    double newAmount = 0;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Add New Ingredient"),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<Ingredient>(
                value: selectedIngredient,
                items: availableIngredients.map((ingredient) {
                  return DropdownMenuItem(
                    value: ingredient,
                    child: Text(ingredient.name),
                  );
                }).toList(),
                onChanged: (val) => setState(() => selectedIngredient = val),
                decoration:
                    const InputDecoration(labelText: "Select Ingredient"),
              ),
              const SizedBox(height: 12),
              if (selectedIngredient != null)
                Text("Unit: ${selectedIngredient!.unit}",
                    style: const TextStyle(fontSize: 13)),
              TextField(
                decoration: const InputDecoration(labelText: "Amount"),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                onChanged: (val) => newAmount = double.tryParse(val) ?? 0,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              if (selectedIngredient != null && newAmount > 0) {
                final existingIndex =
                    widget.selectedMeal.ingredients.indexWhere(
                  (ing) => ing.name == selectedIngredient!.name,
                );

                if (existingIndex != -1) {
                  widget.selectedMeal.ingredients[existingIndex] = Ingredient(
                    name: selectedIngredient!.name,
                    amount: newAmount,
                    unit: selectedIngredient!.unit,
                    image: selectedIngredient!.image,
                    nutri: selectedIngredient!.nutri,
                  );
                } else {
                  widget.selectedMeal.ingredients.add(
                    Ingredient(
                      name: selectedIngredient!.name,
                      amount: newAmount,
                      unit: selectedIngredient!.unit,
                      image: selectedIngredient!.image,
                      nutri: selectedIngredient!.nutri,
                    ),
                  );
                }

                setState(() {});
                Navigator.pop(context);
              }
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }
}

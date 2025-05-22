import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitness_workout_app/view/login/what_your_goal_view.dart';
import 'package:flutter/material.dart';

import '../../common/colo_extension.dart';
import '../../services/auth_services.dart';

class WhatYourBodyFatView extends StatefulWidget {
  const WhatYourBodyFatView({super.key});

  @override
  _WhatYourBodyFatViewState createState() => _WhatYourBodyFatViewState();
}

class _WhatYourBodyFatViewState extends State<WhatYourBodyFatView> {
  int? selectedIndex;

  final List<Map<String, dynamic>> bodyFatOptions = [
    {'label': '10–13%', 'value': 11.5, 'asset': 'assets/img/bodyfat_10_13.jpg'},
    {'label': '14–17%', 'value': 15.5, 'asset': 'assets/img/bodyfat_14_17.jpg'},
    {'label': '18–23%', 'value': 20.5, 'asset': 'assets/img/bodyfat_18_23.jpg'},
    {'label': '24–28%', 'value': 26.0, 'asset': 'assets/img/bodyfat_24_28.jpg'},
    {'label': '29–33%', 'value': 31.0, 'asset': 'assets/img/bodyfat_29_33.png'},
    {'label': '34–37%', 'value': 35.5, 'asset': 'assets/img/bodyfat_34_37.png'},
    {'label': '38–42%', 'value': 40.0, 'asset': 'assets/img/bodyfat_38_42.jpg'},
    {'label': '43–49%', 'value': 46.0, 'asset': 'assets/img/bodyfat_43_49.jpg'},
    {'label': '50% +', 'value': 52.0, 'asset': 'assets/img/bodyfat_50_plus.jpg'},
  ];

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery
        .of(context)
        .size;
    return Scaffold(
      body: Column(
        children: [
          SizedBox(
            height: media.width * 0.1,
          ),
          Text(
            "What is your body fat level?",
            style: TextStyle(
                color: TColor.black,
                fontSize: 20,
                fontWeight: FontWeight.w700),
          ),
          Text(
            "Use a visual assessment and don’t worry about being too precise",
            textAlign: TextAlign.center,
            style: TextStyle(color: TColor.gray, fontSize: 14),
          ),
          SizedBox(
            height: media.width * 0.03,
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: bodyFatOptions.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 20,
                crossAxisSpacing: 12,
                childAspectRatio: 0.65,
              ),
              itemBuilder: (context, index) {
                final option = bodyFatOptions[index];
                final isSelected = selectedIndex == index;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedIndex = index;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isSelected ? Colors.blue : Colors.grey,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        AspectRatio(
                          aspectRatio: 0.75, // Hình luôn vuông
                          child: Image.asset(
                            option['asset'],
                            fit: BoxFit.cover, // Hiển thị đầy đủ, cắt viền nếu cần
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          option['label'],
                          style: TextStyle(
                            fontWeight: FontWeight.w400,
                            color: isSelected ? Colors.blue : Colors.black,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: ElevatedButton(
              onPressed: selectedIndex != null
                  ? () async {
                final selectedValue = bodyFatOptions[selectedIndex!]['value'];
                String result = await AuthService().updateUserBodyFat(
                    FirebaseAuth.instance.currentUser!.uid,
                    selectedValue.toString());

                if (result == "success") {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const WhatYourGoalView(),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Lỗi xảy ra: $result')),
                  );
                }
              } : null,
              child: const Text("Confirm"),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: selectedIndex != null
                    ? TColor.primaryColor1
                    : Colors.grey.shade400,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

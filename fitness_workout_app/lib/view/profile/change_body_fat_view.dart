import 'package:flutter/material.dart';

import '../../common/colo_extension.dart';
import '../../main.dart';


class ChangeBodyFatView extends StatefulWidget {
  final String value;
  const ChangeBodyFatView({super.key, required this.value});

  @override
  _ChangeBodyFatViewState createState() => _ChangeBodyFatViewState();
}

class _ChangeBodyFatViewState extends State<ChangeBodyFatView> {
  int? selectedIndex;
  bool darkmode = darkModeNotifier.value;

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
  void initState() {
    super.initState();
    double? passedValue = double.tryParse(widget.value); // Chuyển String -> double
    if (passedValue != null) {
      selectedIndex = bodyFatOptions.indexWhere((option) => option['value'] == passedValue);
    }
  }

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery
        .of(context)
        .size;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: darkmode? Colors.blueGrey[900] : TColor.white,
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
      ),
      body: Column(
        children: [
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
                  ? () {
                final selectedValue = bodyFatOptions[selectedIndex!]['value'];
                Navigator.pop(context, selectedValue.toString());
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

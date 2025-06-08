import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitness_workout_app/common/colo_extension.dart';
import 'package:fitness_workout_app/common_widget/round_button.dart';
import 'package:fitness_workout_app/main.dart';
import 'package:fitness_workout_app/model/user_model.dart';
import 'package:fitness_workout_app/services/auth_services.dart';
import 'package:flutter/material.dart';

class ChangeMedicalHistoryView extends StatefulWidget {
  const ChangeMedicalHistoryView({super.key});

  @override
  State<ChangeMedicalHistoryView> createState() =>
      _ChangeMedicalHistoryViewState();
}

class _ChangeMedicalHistoryViewState extends State<ChangeMedicalHistoryView> {
  final List<String> diseases = [
    "Hypertension",
    "Diabetes",
    "Cardiovascular disease",
    "Osteoarthritis",
    "Asthma",
    "Obesity",
    "Chronic kidney disease",
    "Chronic respiratory disease",
    "Other"
  ];
  final Set<String> selectedDiseases = {};
  final TextEditingController otherDiseasesController = TextEditingController();
  final TextEditingController noteController = TextEditingController();
  bool darkmode = darkModeNotifier.value;

  @override
  void initState() {
    super.initState();
    // Lấy thông tin người dùng khi view được khởi tạo
    getUserInfo();
  }

  @override
  void dispose() {
    // Giải phóng bộ nhớ của các controller khi không còn sử dụng
    otherDiseasesController.dispose();
    noteController.dispose();
    super.dispose();
  }

  void getUserInfo() async {
    try {
      // Lấy lại thông tin người dùng
      UserModel? user = await AuthService()
          .getUserInfo(FirebaseAuth.instance.currentUser!.uid);

      if (user != null) {
        // Cập nhật thông tin vào các trường
        setState(() {
          selectedDiseases.addAll(user.medicalHistory);
          otherDiseasesController.text = user.medicalHistoryOther.join('\n');
          noteController.text = user.medicalNote;
          // Nếu có medicalHistoryOther thì tự tích "Other"
          if (user.medicalHistoryOther.isNotEmpty) {
            selectedDiseases.add("Other");
          }
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Có lỗi xảy ra')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi xảy ra: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: darkmode ? Colors.blueGrey[900] : TColor.white,
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
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Text(
              "Do you have any medical history?",
              style: TextStyle(
                  color: TColor.black,
                  fontSize: 20,
                  fontWeight: FontWeight.w700),
            ),
            const Text(
              "Please select any medical conditions you have:",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const Text(
              "If you have no medical conditions, just leave everything blank and press Confirm.",
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            ...diseases.map((disease) => CheckboxListTile(
                  title: Text(disease),
                  value: selectedDiseases.contains(disease),
                  onChanged: (val) {
                    setState(() {
                      if (val == true) {
                        selectedDiseases.add(disease);
                      } else {
                        selectedDiseases.remove(disease);
                        if (disease == "Other") otherDiseasesController.clear();
                      }
                    });
                  },
                )),
            if (selectedDiseases.contains("Other"))
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
                child: TextField(
                  controller: otherDiseasesController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: "Please specify (one per line)",
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            const SizedBox(height: 4),
            const Text(
              "Additional notes (optional):",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: noteController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: "Enter any additional notes...",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            RoundButton(
                title: "Confirm",
                onPressed: () async {
                  // Prepare data to save
                  final List<String> medicalHistory =
                      selectedDiseases.where((d) => d != "Other").toList();
                  final List<String> medicalHistoryOther =
                      otherDiseasesController.text
                          .split('\n')
                          .map((e) => e.trim())
                          .where((e) => e.isNotEmpty)
                          .toList();
                  final String medicalNote = noteController.text.trim();
                  String result = await AuthService().updateUserMedicalHistory(
                    uid: FirebaseAuth.instance.currentUser!.uid,
                    medicalHistory: medicalHistory,
                    medicalHistoryOther: medicalHistoryOther,
                    medicalNote: medicalNote,
                  );
                  if (result == "success") {
                    Navigator.pop(context);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $result')),
                    );
                  }
                }),
          ],
        ),
      ),
    );
  }
}

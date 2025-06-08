import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitness_workout_app/common/colo_extension.dart';
import 'package:fitness_workout_app/common_widget/round_button.dart';
import 'package:fitness_workout_app/services/auth_services.dart';
import 'package:fitness_workout_app/view/login/overview_view.dart';
import 'package:flutter/material.dart';

class MedicalHistoryView extends StatefulWidget {
  const MedicalHistoryView({super.key});

  @override
  State<MedicalHistoryView> createState() => _MedicalHistoryViewState();
}

class _MedicalHistoryViewState extends State<MedicalHistoryView> {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const OverviewView(),
                      ),
                    );
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

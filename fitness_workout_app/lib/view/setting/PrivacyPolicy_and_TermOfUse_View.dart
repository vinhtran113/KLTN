import 'package:fitness_workout_app/common/colo_extension.dart';
import 'package:flutter/material.dart';

import '../../main.dart';
import '../../localization/app_localizations.dart';

class PrivacyPolicyandTermOfUseView extends StatefulWidget {
  const PrivacyPolicyandTermOfUseView({super.key});

  @override
  State<PrivacyPolicyandTermOfUseView> createState() => _PrivacyPolicyandTermOfUseViewState();
}

class _PrivacyPolicyandTermOfUseViewState extends State<PrivacyPolicyandTermOfUseView> {
  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;
    bool darkmode = darkModeNotifier.value;
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
      body: SingleChildScrollView(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(15.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)?.translate("Privacy Policy and Terms of Use") ?? "Privacy Policy and Terms of Use",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  AppLocalizations.of(context)?.translate("Privacy Policy") ?? "Privacy Policy",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  AppLocalizations.of(context)?.translate("Privacy Policy 1") ?? "1. We value your privacy and are committed to protecting your personal information. "
                      "The data we collect is used solely for improving the user experience and providing personalized features in the app.",
                  style: TextStyle(color: darkmode? Colors.white60 : TColor.secondaryText, fontSize: 16),
                ),
                SizedBox(height: 10),
                Text(
                  AppLocalizations.of(context)?.translate("Privacy Policy 2") ?? "2. Your data will not be shared with third parties without your consent, except as required by law.",
                  style: TextStyle(color: darkmode? Colors.white60 : TColor.secondaryText, fontSize: 16),
                ),
                SizedBox(height: 20),
                Text(
                  AppLocalizations.of(context)?.translate("Terms of Use") ?? "Terms of Use",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  AppLocalizations.of(context)?.translate("Terms of Use 1") ?? "1. By using this app, you agree to adhere to all guidelines and rules outlined in this document.",
                  style: TextStyle(color: darkmode? Colors.white60 : TColor.secondaryText, fontSize: 16),
                ),
                SizedBox(height: 10),
                Text(
                  AppLocalizations.of(context)?.translate("Terms of Use 2") ?? "2. This app is designed to provide workout plans and exercise management. It is not a substitute for professional medical advice. "
                      "Always consult a healthcare professional before beginning any fitness program.",
                  style: TextStyle(color: darkmode? Colors.white60 : TColor.secondaryText, fontSize: 16),
                ),
                SizedBox(height: 10),
                Text(
                  AppLocalizations.of(context)?.translate("Terms of Use 3") ?? "3. Users are prohibited from sharing their accounts or engaging in any unauthorized use of the application.",
                  style: TextStyle(color: darkmode? Colors.white60 : TColor.secondaryText, fontSize: 16),
                ),
                SizedBox(height: 20),
                Text(
                  AppLocalizations.of(context)?.translate("Contact Us") ?? "Contact Us",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  AppLocalizations.of(context)?.translate("Contact Us des") ?? "If you have any questions or concerns about this Privacy Policy or Terms of Use, please contact us at support@fitnessapp.com.",
                  style: TextStyle(color: darkmode? Colors.white60 : TColor.secondaryText, fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

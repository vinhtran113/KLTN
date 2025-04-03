import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../localization/app_localizations.dart';
import '../../common/colo_extension.dart';
import '../../common_widget/language_row.dart';
import '../../main.dart';

class SelectLanguageView extends StatefulWidget {
  const SelectLanguageView({super.key});

  @override
  State<SelectLanguageView> createState() => _SelectLanguageViewState();
}

class _SelectLanguageViewState extends State<SelectLanguageView> {
  int selectIndex = 0;
  final List<Map<String, String>> langArr = [
    {"code": "en", "name": "English"},
    {"code": "vi", "name": "Vietnamese"},
  ];

  @override
  void initState() {
    super.initState();
    _loadLanguage();
  }

  /// Đọc ngôn ngữ đã lưu trong SharedPreferences
  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    String langCode = prefs.getString('locale') ?? "en";
    selectIndex = langArr.indexWhere((lang) => lang["code"] == langCode);
    setState(() {});
  }

  /// Cập nhật ngôn ngữ khi người dùng chọn
  Future<void> _changeLanguage(int index) async {
    final prefs = await SharedPreferences.getInstance();
    String langCode = langArr[index]["code"]!;

    await prefs.setString('locale', langCode);
    localeNotifier.value = Locale(langCode);

    setState(() {
      selectIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    bool darkmode = darkModeNotifier.value;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: darkmode ? Colors.blueGrey[900] : TColor.white,
        centerTitle: true,
        elevation: 0.1,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Image.asset(
            "assets/img/black_btn.png",
            width: 25,
            height: 25,
          ),
        ),
        title: Text(
          AppLocalizations.of(context)?.translate("language") ?? "Language",
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        itemBuilder: (context, index) {
          var lang = langArr[index];
          return LanguageRow(
            tObj: {
              "name": AppLocalizations.of(context)?.translate(lang["name"]!) ?? lang["name"]!,
            },
            isActive: selectIndex == index,
            onPressed: () => _changeLanguage(index),
          );
        },
        separatorBuilder: (context, index) => const Divider(
          color: Colors.black26,
          height: 1,
        ),
        itemCount: langArr.length,
      ),
    );
  }
}

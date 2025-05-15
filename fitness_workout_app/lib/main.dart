import 'dart:async';

import 'package:fitness_workout_app/services/auth_services.dart';
import 'package:fitness_workout_app/services/notification_services.dart';
import 'package:fitness_workout_app/view/login/choose_activity_level_view.dart';
import 'package:fitness_workout_app/view/login/complete_profile_view.dart';
import 'package:fitness_workout_app/view/login/what_your_goal_view.dart';
import 'package:fitness_workout_app/view/main_tab/main_tab_view.dart';
import 'package:fitness_workout_app/view/on_boarding/started_view.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'chatbox/firebase_options.dart';
import 'model/user_model.dart';
import 'localization/app_localizations.dart';
import 'package:permission_handler/permission_handler.dart';

final navigatorKey = GlobalKey<NavigatorState>();
final darkModeNotifier = ValueNotifier<bool>(false); // Trạng thái dark mode
ValueNotifier<Locale> localeNotifier = ValueNotifier<Locale>(const Locale('en', 'US'));

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: ".env");
    print("✅ .env loaded");
    await Firebase.initializeApp();
    await NotificationServices().initNotifications();
    print("✅ Notifications initialized");

    await requestPermissions();
    print("✅ Permissions granted");

    final prefs = await SharedPreferences.getInstance();
    darkModeNotifier.value = prefs.getBool('isDarkMode') ?? false;
    String? savedLocale = prefs.getString('locale');
    if (savedLocale != null) {
      localeNotifier.value = Locale(savedLocale);
    }
  } catch (e, stackTrace) {
    print('❌ Initialization failed: $e');
    print(stackTrace);
    return;
  }

  runZonedGuarded(
        () => runApp(
      ProviderScope(
        child: const MyApp(),
      ),
    ),
        (error, stackTrace) {
      print('Uncaught error: $error');
      print(stackTrace);
    },
  );
}


// Hàm xin quyền người dùng
Future<void> requestPermissions() async {
  var cameraStatus = await Permission.camera.request();
  if (cameraStatus.isDenied) {
    print("Camera permission denied");
  }

  var storageStatus = await Permission.storage.request();
  if (storageStatus.isDenied) {
    print("Storage permission denied");
  }

  var manageStatus = await Permission.manageExternalStorage.request();
  if (manageStatus.isDenied) {
    print("Manage External Storage permission denied");
  }
}

// App chính
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: localeNotifier,
      builder: (context, locale, child) {
        return ValueListenableBuilder<bool>(
          valueListenable: darkModeNotifier,
          builder: (context, isDarkMode, child) {
            return MaterialApp(
              title: AppLocalizations.of(context)?.translate("app_name") ?? "Fitness 3 in 1",
              debugShowCheckedModeBanner: false,
              navigatorKey: navigatorKey,
              theme: isDarkMode ? _darkTheme : _lightTheme,
              locale: locale,
              supportedLocales: const [Locale('en', 'US'), Locale('vi', 'VN')],
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              localeResolutionCallback: (locale, supportedLocales) {
                for (var supportedLocale in supportedLocales) {
                  if (supportedLocale.languageCode == locale?.languageCode) {
                    return supportedLocale;
                  }
                }
                return supportedLocales.first;
              },
              home: FutureBuilder<Widget>(
                future: _getInitialScreen(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return const Center(child: Text("Something went wrong"));
                  } else {
                    return snapshot.data!;
                  }
                },
              ),
            );
          },
        );
      },
    );
  }

  Future<Widget> _getInitialScreen() async {
    UserModel? user;
    if (FirebaseAuth.instance.currentUser != null) {
      user = await AuthService().getUserInfo(FirebaseAuth.instance.currentUser!.uid);
    }
    if (user?.gender == '') {
      return const CompleteProfileView();
    }
    if (user?.level == '') {
      return const WhatYourGoalView();
    }
    if (user?.ActivityLevel == '') {
      return const ChooseActivityLevelView();
    }
    if (user != null) {
      return MainTabView(user: user);
    } else {
      return const StartedView();
    }
  }
}

final ThemeData _lightTheme = ThemeData(
  brightness: Brightness.light,
  scaffoldBackgroundColor: Colors.white,
  textTheme: const TextTheme(
    bodyLarge: TextStyle(color: Colors.black),
  ),
);

final ThemeData _darkTheme = ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: Colors.blueGrey[900],
  textTheme: const TextTheme(
    bodyLarge: TextStyle(color: Colors.white),
  ),
);



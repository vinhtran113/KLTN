import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:fitness_workout_app/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import '../view/meal_planner/meal_schedule_view.dart';
import '../view/sleep_tracker/sleep_schedule_view.dart';
import '../view/workout_tracker/workout_detail_view.dart';

class NotificationServices {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final AndroidNotificationChannel _androidChannel =
      const AndroidNotificationChannel(
    'workout_channel',
    'Workout Notifications',
    description: 'This channel is used for workout reminders',
    importance: Importance.max,
  );

  final AndroidNotificationChannel _sleepChannel =
      const AndroidNotificationChannel(
    'sleep_channel',
    'Sleep Notifications',
    description: 'This channel is used for bedtime reminders',
    importance: Importance.max,
    sound: RawResourceAndroidNotificationSound('alarm'),
  );

  final AndroidNotificationChannel _wakeUpChannel =
      const AndroidNotificationChannel(
    'wake_up_channel',
    'Wake Up Notifications',
    description: 'This channel is used for wake-up reminders',
    importance: Importance.max,
    sound: RawResourceAndroidNotificationSound('alarm'),
  );

  final AndroidNotificationChannel _mealChannel =
      const AndroidNotificationChannel(
    'meal_channel',
    'Meal Notifications',
    description: 'This channel is used for meal reminders',
    importance: Importance.max,
  );

  NotificationServices() {
    // Khởi tạo múi giờ
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Ho_Chi_Minh'));
  }

  Future<void> _addNotificationToArr(
      Map<String, dynamic> notificationData, DateTime scheduledTime) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    // Thêm trường 'time' với thời gian đã lên lịch
    notificationData['time'] = scheduledTime.toIso8601String();

    String type = notificationData['type'] ?? 'workout'; // mặc định là workout

    String key;
    if (type == 'workout') {
      key = 'workoutNotificationArr';
    } else if (type == 'alarm') {
      key = 'alarmNotificationArr';
    } else if (type == 'meal') {
      key = 'mealNotificationArr';
    } else {
      key = 'otherNotificationArr';
    }

    List<String> notificationArr = prefs.getStringList(key) ?? [];
    notificationArr.add(jsonEncode(notificationData));
    await prefs.setStringList(key, notificationArr);
  }

  // Tải danh sách notificationArr từ SharedPreferences
  Future<List<Map<String, String>>> loadWorkoutNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encodedData = prefs.getStringList(
          'workoutNotificationArr'); // Sử dụng getStringList thay vì getString
      if (encodedData != null && encodedData.isNotEmpty) {
        // Giải mã từng phần tử trong danh sách JSON
        final decodedData = encodedData.map((item) {
          return Map<String, String>.from(jsonDecode(item));
        }).toList();

        print("Notifications loaded successfully");
        return decodedData;
      }
    } catch (e) {
      print("Error loading notifications: $e");
    }
    return [];
  }

  // Tải danh sách notificationArr từ SharedPreferences
  Future<List<Map<String, String>>> loadMealNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encodedData = prefs.getStringList(
          'mealNotificationArr'); // Sử dụng getStringList thay vì getString
      if (encodedData != null && encodedData.isNotEmpty) {
        // Giải mã từng phần tử trong danh sách JSON
        final decodedData = encodedData.map((item) {
          return Map<String, String>.from(jsonDecode(item));
        }).toList();

        print("Notifications loaded successfully");
        return decodedData;
      }
    } catch (e) {
      print("Error loading notifications: $e");
    }
    return [];
  }

  // Tải danh sách notificationArr từ SharedPreferences
  Future<List<Map<String, String>>> loadAlarmNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encodedData = prefs.getStringList(
          'alarmNotificationArr'); // Sử dụng getStringList thay vì getString
      if (encodedData != null && encodedData.isNotEmpty) {
        // Giải mã từng phần tử trong danh sách JSON
        final decodedData = encodedData.map((item) {
          return Map<String, String>.from(jsonDecode(item));
        }).toList();

        print("Notifications loaded successfully");
        return decodedData;
      }
    } catch (e) {
      print("Error loading notifications: $e");
    }
    return [];
  }

  Future<void> removeWorkoutNotifications(String notificationId) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> notificationArr =
        prefs.getStringList('workoutNotificationArr') ?? [];

    // Tìm và xóa thông báo có ID tương ứng
    notificationArr.removeWhere((item) {
      final Map<String, dynamic> notificationData = jsonDecode(item);
      return notificationData['id'] == notificationId; // Kiểm tra ID
    });
    // Lưu lại danh sách đã cập nhật
    await prefs.setStringList('workoutNotificationArr', notificationArr);
  }

  Future<void> removeAlarmNotifications(String notificationId) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> notificationArr =
        prefs.getStringList('alarmNotificationArr') ?? [];

    // Tìm và xóa thông báo có ID tương ứng
    notificationArr.removeWhere((item) {
      final Map<String, dynamic> notificationData = jsonDecode(item);
      return notificationData['id'] == notificationId; // Kiểm tra ID
    });
    // Lưu lại danh sách đã cập nhật
    await prefs.setStringList('alarmNotificationArr', notificationArr);
  }

  Future<void> removeMealNotifications(String notificationId) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> notificationArr =
        prefs.getStringList('mealNotificationArr') ?? [];

    // Tìm và xóa thông báo có ID tương ứng
    notificationArr.removeWhere((item) {
      final Map<String, dynamic> notificationData = jsonDecode(item);
      return notificationData['id'] == notificationId; // Kiểm tra ID
    });
    // Lưu lại danh sách đã cập nhật
    await prefs.setStringList('mealNotificationArr', notificationArr);
  }

  Future<void> clearNotificationArr() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    // Xóa toàn bộ thông tin trong 'notificationArr'
    await prefs.remove('workoutNotificationArr');

    await prefs.remove('mealNotificationArr');

    await prefs.remove('alarmNotificationArr');
  }

  Future<void> initNotifications() async {
    // Yêu cầu quyền từ người dùng
    NotificationSettings settings =
        await _firebaseMessaging.requestPermission();
    if (settings.authorizationStatus != AuthorizationStatus.authorized) {
      print('User declined or has not accepted permission');
      return;
    }
    setupMessageHandlers();

    await initLocalNotifications();
  }

  Future<void> initLocalNotifications() async {
    const DarwinInitializationSettings iOS = DarwinInitializationSettings();
    const AndroidInitializationSettings android =
        AndroidInitializationSettings('@drawable/icon_app');
    const InitializationSettings settings =
        InitializationSettings(android: android, iOS: iOS);

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: (notificationResponse) async {
        final payload = notificationResponse.payload;
        if (payload != null) {
          try {
            final Map<String, dynamic> data = jsonDecode(payload);
            final String type = data['type'] ?? '';

            if (type == 'workout') {
              navigatorKey.currentState?.push(
                MaterialPageRoute(
                  builder: (context) => WorkoutDetailView(dObj: data),
                ),
              );
            } else if (type == 'meal') {
              navigatorKey.currentState?.push(
                MaterialPageRoute(
                  builder: (context) => const MealScheduleView(),
                ),
              );
            } else if (type == 'alarm') {
              navigatorKey.currentState?.push(MaterialPageRoute(
                  builder: (context) => const SleepScheduleView()));
            } else {
              print("Unknown notification type: $type");
            }
          } catch (e) {
            print("Error decoding payload: $e");
          }
        } else {
          print("Payload is null");
        }
      },
    );

    final platform = _localNotifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await platform?.createNotificationChannel(_androidChannel);
    await platform?.createNotificationChannel(_sleepChannel);
    await platform?.createNotificationChannel(_wakeUpChannel);
    await platform?.createNotificationChannel(_mealChannel);
  }

  void handleMessage(RemoteMessage? message) {
    if (message == null) return;

    final workoutData = message.data;
    if (workoutData.isNotEmpty) {
      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (context) => WorkoutDetailView(dObj: workoutData),
        ),
      );
    }
  }

  void setupMessageHandlers() {
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      final data = message.data;
      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (context) => WorkoutDetailView(dObj: data),
        ),
      );
    });

    _firebaseMessaging.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        final data = message.data;
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (context) => WorkoutDetailView(dObj: data),
          ),
        );
      }
    });
  }

  Future<String> scheduleBedtimeNotification({
    required String id,
    required DateTime bedtime,
    required String repeatInterval,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'sleep_channel',
      'Sleep Notifications',
      channelDescription: 'This channel is used for bedtime reminders',
      importance: Importance.max,
      priority: Priority.high,
      icon: 'icon_app',
      sound: RawResourceAndroidNotificationSound('alarm'),
    );
    const NotificationDetails platformDetails =
        NotificationDetails(android: androidDetails);
    DateTime newScheduledTime = bedtime;
    // Nếu lặp lại là 'Everyday', kiểm tra xem thời gian đã qua chưa
    if (repeatInterval == 'Everyday') {
      if (newScheduledTime.isBefore(DateTime.now())) {
        newScheduledTime = DateTime.now().add(const Duration(days: 1));
      }
    }
    // Nếu lặp lại là các ngày trong tuần (Monday, Friday)
    else if (repeatInterval.contains(',')) {
      newScheduledTime =
          _getNextWeekdayWithSameTime(DateTime.now(), repeatInterval, bedtime);
    }
    final tz.TZDateTime scheduledTZDateTime =
        tz.TZDateTime.from(newScheduledTime, tz.local);
    if (repeatInterval == 'no') {
      // Thông báo một lần
      await _localNotifications.zonedSchedule(
        id.hashCode,
        'Bedtime Reminder',
        'It\'s time to prepare for bed!',
        scheduledTZDateTime,
        platformDetails,
        payload: jsonEncode({
          'type': 'alarm',
        }),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.wallClockTime,
      );
      // Thêm vào notificationArr
      final Map<String, dynamic> data = {
        'title': 'Bedtime Reminder',
        'type': 'alarm',
        'id': id.hashCode.toString(),
      };
      await _addNotificationToArr(data, scheduledTZDateTime);
    } else if (repeatInterval == 'Everyday') {
      // Thông báo hàng ngày
      await _localNotifications.zonedSchedule(
        id.hashCode,
        'Bedtime Reminder',
        'It\'s time to prepare for bed!',
        scheduledTZDateTime,
        payload: jsonEncode({
          'type': 'alarm',
        }),
        platformDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.wallClockTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
      // Thêm vào notificationArr
      final Map<String, dynamic> data = {
        'title': 'Bedtime Reminder',
        'type': 'alarm',
        'id': id.hashCode.toString(),
      };
      await _addNotificationToArr(data, scheduledTZDateTime);
    } else {
      // Tính toán ngày kết thúc (365 ngày sau)
      final DateTime endDate = bedtime.add(Duration(days: 365));
      final tz.TZDateTime endTZDateTime = tz.TZDateTime.from(endDate, tz.local);
      // Chia danh sách các ngày lặp lại
      List<String> daysOfWeek = repeatInterval.split(',');
      Set<int> weekdaysSet = {};
      for (String day in daysOfWeek) {
        final int weekday = _getWeekdayFromString(day.trim());
        if (weekday != -1) {
          weekdaysSet.add(weekday);
        }
      }
      // Duyệt qua các ngày trong tuần và lên lịch thông báo
      tz.TZDateTime currentScheduledTime = scheduledTZDateTime;
      while (currentScheduledTime.isBefore(endTZDateTime)) {
        if (weekdaysSet.contains(currentScheduledTime.weekday)) {
          // Nếu ngày trong tuần nằm trong danh sách, lên lịch thông báo
          await _localNotifications.zonedSchedule(
            id.hashCode,
            'Bedtime Reminder',
            'It\'s time to prepare for bed!',
            currentScheduledTime,
            payload: jsonEncode({
              'type': 'alarm',
            }),
            platformDetails,
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.wallClockTime,
            matchDateTimeComponents: DateTimeComponents.time,
          );
          // Thêm vào notificationArr
          final Map<String, dynamic> data = {
            'title': 'Bedtime Reminder',
            'type': 'alarm',
            'id': id.hashCode.toString(),
          };
          await _addNotificationToArr(data, currentScheduledTime);
        }
        // Tính ngày tiếp theo trong tuần
        currentScheduledTime =
            _nextInstanceOfWeekday(currentScheduledTime, weekdaysSet);
      }
      // Kiểm tra nếu ngày lên lịch không nằm trong danh sách, thêm vào
      if (!weekdaysSet.contains(scheduledTZDateTime.weekday)) {
        // Lên lịch thông báo cho ngày lên lịch ban đầu
        await _localNotifications.zonedSchedule(
          id.hashCode,
          'Bedtime Reminder',
          'It\'s time to prepare for bed!',
          scheduledTZDateTime,
          payload: jsonEncode({
            'type': 'alarm',
          }),
          platformDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.wallClockTime,
        );
        // Thêm vào notificationArr
        final Map<String, dynamic> data = {
          'title': 'Bedtime Reminder',
          'type': 'alarm',
          'id': id.hashCode.toString(),
        };
        await _addNotificationToArr(data, scheduledTZDateTime);
      }
    }
    print('Notification ID updated for bedtime ${id.hashCode}');
    return id.hashCode.toString();
  }

  Future<String> scheduleWakeUpNotification({
    required String id,
    required DateTime wakeUpTime,
    required String repeatInterval,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'wake_up_channel',
      'Wake Up Notifications',
      channelDescription: 'This channel is used for wake-up reminders',
      importance: Importance.max,
      priority: Priority.high,
      icon: 'icon_app',
      sound: RawResourceAndroidNotificationSound('alarm'),
    );
    const NotificationDetails platformDetails =
        NotificationDetails(android: androidDetails);
    DateTime newScheduledTime = wakeUpTime;
    // Nếu lặp lại là 'Everyday', kiểm tra xem thời gian đã qua chưa
    if (repeatInterval == 'Everyday') {
      if (newScheduledTime.isBefore(DateTime.now())) {
        newScheduledTime = DateTime.now().add(const Duration(days: 1));
      }
    }
    // Nếu lặp lại là các ngày trong tuần (Monday, Friday)
    else if (repeatInterval.contains(',')) {
      newScheduledTime = _getNextWeekdayWithSameTime(
          DateTime.now(), repeatInterval, wakeUpTime);
    }
    final tz.TZDateTime scheduledTZDateTime =
        tz.TZDateTime.from(newScheduledTime, tz.local);
    if (repeatInterval == 'no') {
      // Thông báo một lần
      await _localNotifications.zonedSchedule(
        id.hashCode + 1,
        'Wake Up Alarm',
        'Time to wake up and start your day!',
        scheduledTZDateTime,
        payload: jsonEncode({
          'type': 'alarm',
        }),
        platformDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.wallClockTime,
      );
      // Thêm vào notificationArr
      final Map<String, dynamic> data = {
        'title': 'Wake Up Alarm',
        'type': 'alarm',
        'id': (id.hashCode + 1).toString()
      };
      await _addNotificationToArr(data, scheduledTZDateTime);
    } else if (repeatInterval == 'Everyday') {
      // Thông báo hàng ngày
      await _localNotifications.zonedSchedule(
        id.hashCode + 1,
        'Wake Up Alarm',
        'Time to wake up and start your day!',
        scheduledTZDateTime,
        payload: jsonEncode({
          'type': 'alarm',
        }),
        platformDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.wallClockTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
      // Thêm vào notificationArr
      final Map<String, dynamic> data = {
        'title': 'Wake Up Alarm',
        'type': 'alarm',
        'id': (id.hashCode + 1).toString()
      };
      await _addNotificationToArr(data, scheduledTZDateTime);
    } else {
      // Tính toán ngày kết thúc (365 ngày sau)
      final DateTime endDate = wakeUpTime.add(Duration(days: 365));
      final tz.TZDateTime endTZDateTime = tz.TZDateTime.from(endDate, tz.local);
      // Chia danh sách các ngày lặp lại
      List<String> daysOfWeek = repeatInterval.split(',');
      Set<int> weekdaysSet = {};
      for (String day in daysOfWeek) {
        final int weekday = _getWeekdayFromString(day.trim());
        if (weekday != -1) {
          weekdaysSet.add(weekday);
        }
      }
      // Duyệt qua các ngày trong tuần và lên lịch thông báo
      tz.TZDateTime currentScheduledTime = scheduledTZDateTime;
      while (currentScheduledTime.isBefore(endTZDateTime)) {
        if (weekdaysSet.contains(currentScheduledTime.weekday)) {
          // Nếu ngày trong tuần nằm trong danh sách, lên lịch thông báo
          await _localNotifications.zonedSchedule(
            id.hashCode + 1,
            'Wake Up Alarm',
            'Time to wake up and start your day!',
            currentScheduledTime,
            payload: jsonEncode({
              'type': 'alarm',
            }),
            platformDetails,
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.wallClockTime,
            matchDateTimeComponents: DateTimeComponents.time,
          );
          // Thêm vào notificationArr
          final Map<String, dynamic> data = {
            'title': 'Wake Up Alarm',
            'type': 'alarm',
            'id': (id.hashCode + 1).toString()
          };
          await _addNotificationToArr(data, currentScheduledTime);
        }
        // Tính ngày tiếp theo trong tuần
        currentScheduledTime =
            _nextInstanceOfWeekday(currentScheduledTime, weekdaysSet);
      }
      // Kiểm tra nếu ngày lên lịch không nằm trong danh sách, thêm vào
      if (!weekdaysSet.contains(scheduledTZDateTime.weekday)) {
        // Lên lịch thông báo cho ngày lên lịch ban đầu
        await _localNotifications.zonedSchedule(
          id.hashCode + 1,
          'Wake Up Alarm',
          'Time to wake up and start your day!',
          scheduledTZDateTime,
          payload: jsonEncode({
            'type': 'alarm',
          }),
          platformDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.wallClockTime,
        );
        // Thêm vào notificationArr
        final Map<String, dynamic> data = {
          'title': 'Wake Up Alarm',
          'type': 'alarm',
          'id': (id.hashCode + 1).toString()
        };
        await _addNotificationToArr(data, scheduledTZDateTime);
      }
    }
    print('Notification ID updated for wakeup ${id.hashCode + 1}');
    return id.hashCode.toString();
  }

  Future<String> scheduleMealNotification({
    required String id,
    required String mealType,
    required DateTime Time,
    required String Name,
    required String pic,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'meal_channel',
      'Meal Notifications',
      channelDescription: 'This channel is used for meal reminders',
      importance: Importance.max,
      priority: Priority.high,
      icon: 'icon_app',
    );
    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
    );

    DateTime newScheduledTime = Time;

    final tz.TZDateTime scheduledTZDateTime =
        tz.TZDateTime.from(newScheduledTime, tz.local);

    // Thông báo một lần
    await _localNotifications.zonedSchedule(
      id.hashCode,
      'Meal Reminder',
      'It\'s time for your $mealType: $Name',
      scheduledTZDateTime,
      platformDetails,
      payload: jsonEncode({
        'type': 'meal',
        'mealType': mealType,
        'name': Name,
        'image': pic,
      }),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.wallClockTime,
    );
    // Thêm vào notificationArr
    final Map<String, dynamic> data = {
      'id': id.hashCode.toString(),
      'name': Name,
      'image': pic,
      'mealType': mealType,
      'type': 'meal',
    };
    await _addNotificationToArr(data, scheduledTZDateTime);

    print('Notification ID updated for meal ${id.hashCode}');
    return id.hashCode.toString();
  }

  Future<String> scheduleWorkoutNotification({
    required String id,
    required DateTime scheduledTime,
    required String workoutName,
    required String repeatInterval,
    required String id_cate,
    required String pic,
    required String diff,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'workout_channel',
      'Workout Notifications',
      channelDescription: 'This channel is used for workout reminders',
      importance: Importance.max,
      priority: Priority.high,
      icon: 'icon_app',
    );
    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
    );
    DateTime newScheduledTime = scheduledTime;
    // Nếu lặp lại là 'Everyday', kiểm tra xem thời gian đã qua chưa
    if (repeatInterval == 'Everyday') {
      if (newScheduledTime.isBefore(DateTime.now())) {
        newScheduledTime = DateTime.now().add(const Duration(days: 1));
      }
    }
    // Nếu lặp lại là các ngày trong tuần (Monday, Friday)
    else if (repeatInterval.contains(',')) {
      newScheduledTime = _getNextWeekdayWithSameTime(
          DateTime.now(), repeatInterval, scheduledTime);
    }
    final tz.TZDateTime scheduledTZDateTime =
        tz.TZDateTime.from(newScheduledTime, tz.local);
    if (repeatInterval == 'no') {
      // Thông báo một lần
      await _localNotifications.zonedSchedule(
        id.hashCode,
        'Workout Reminder',
        'It\'s time for your workout: $workoutName',
        scheduledTZDateTime,
        platformDetails,
        payload: jsonEncode({
          'id': id_cate,
          'title': workoutName,
          'image': pic,
          'difficulty': diff,
          'type': 'workout',
        }),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.wallClockTime,
      );
      // Tạo dữ liệu cho notification
      final Map<String, dynamic> data = {
        'id': id.hashCode.toString(),
        'title': workoutName,
        'image': pic,
        'difficulty': diff,
      };
      await _addNotificationToArr(
          data, scheduledTZDateTime); // Pass the scheduled time
    } else if (repeatInterval == 'Everyday') {
      // Thông báo hàng ngày
      await _localNotifications.zonedSchedule(
        id.hashCode,
        'Daily Workout Reminder',
        'It\'s time for your daily workout: $workoutName',
        scheduledTZDateTime,
        platformDetails,
        payload: jsonEncode({
          'id': id_cate,
          'title': workoutName,
          'image': pic,
          'difficulty': diff,
          'type': 'workout',
        }),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.wallClockTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
      // Tạo dữ liệu cho notification
      final Map<String, dynamic> data = {
        'id': id.hashCode.toString(),
        'title': workoutName,
        'image': pic,
        'difficulty': diff,
      };
      await _addNotificationToArr(
          data, scheduledTZDateTime); // Pass the scheduled time
    } else {
      // Tính toán ngày kết thúc (365 ngày sau)
      final DateTime endDate = scheduledTime.add(Duration(days: 365));
      final tz.TZDateTime endTZDateTime = tz.TZDateTime.from(endDate, tz.local);
      // Chia danh sách các ngày lặp lại
      List<String> daysOfWeek = repeatInterval.split(',');
      Set<int> weekdaysSet = {};
      for (String day in daysOfWeek) {
        final int weekday = _getWeekdayFromString(day.trim());
        if (weekday != -1) {
          weekdaysSet.add(weekday);
        }
      }
      // Duyệt qua các ngày trong tuần và lên lịch thông báo
      tz.TZDateTime currentScheduledTime = scheduledTZDateTime;
      while (currentScheduledTime.isBefore(endTZDateTime)) {
        if (weekdaysSet.contains(currentScheduledTime.weekday)) {
          // Nếu ngày trong tuần nằm trong danh sách, lên lịch thông báo
          await _localNotifications.zonedSchedule(
            id.hashCode,
            'Weekly Workout Reminder',
            'It\'s time for your workout: $workoutName',
            currentScheduledTime,
            platformDetails,
            payload: jsonEncode({
              'id': id_cate,
              'title': workoutName,
              'image': pic,
              'difficulty': diff,
              'type': 'workout',
            }),
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.wallClockTime,
            matchDateTimeComponents: DateTimeComponents.time,
          );
          // Tạo dữ liệu cho notification
          final Map<String, dynamic> data = {
            'id': id.hashCode.toString(),
            'title': workoutName,
            'image': pic,
            'difficulty': diff,
          };
          await _addNotificationToArr(data, currentScheduledTime);
          //print('Scheduled ${id.hashCode} notification for: $currentScheduledTime');
        }
        // Tính ngày tiếp theo trong tuần
        currentScheduledTime =
            _nextInstanceOfWeekday(currentScheduledTime, weekdaysSet);
      }
      // Kiểm tra nếu ngày lên lịch không nằm trong danh sách, thêm vào
      if (!weekdaysSet.contains(scheduledTZDateTime.weekday)) {
        // Lên lịch thông báo cho ngày lên lịch ban đầu
        await _localNotifications.zonedSchedule(
          id.hashCode,
          'Workout Reminder',
          'It\'s time for your workout: $workoutName',
          scheduledTZDateTime,
          platformDetails,
          payload: jsonEncode({
            'id': id_cate,
            'title': workoutName,
            'image': pic,
            'difficulty': diff,
            'type': 'workout',
          }),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.wallClockTime,
          matchDateTimeComponents: DateTimeComponents.time,
        );
        // Tạo dữ liệu cho notification
        final Map<String, dynamic> data = {
          'id': id.hashCode.toString(),
          'title': workoutName,
          'image': pic,
          'difficulty': diff,
        };
        await _addNotificationToArr(
            data, scheduledTZDateTime); // Pass the scheduled time
      }
    }
    print('Notification ID updated for workout ${id.hashCode}');
    return id.hashCode.toString();
  }

  DateTime _getNextWeekdayWithSameTime(DateTime currentDateTime,
      String repeatInterval, DateTime originalScheduledTime) {
    // Chuyển đổi các ngày trong tuần từ chuỗi 'Monday,Friday' thành danh sách các ngày trong tuần
    List<String> daysOfWeek = repeatInterval.split(',');
    List<int> weekdaysSet = [];
    for (String day in daysOfWeek) {
      final int weekday = _getWeekdayFromString(day.trim());
      if (weekday != -1) {
        weekdaysSet.add(weekday);
      }
    }
    // Lưu giờ ban đầu để giữ nguyên
    DateTime newScheduledTime = DateTime(
        currentDateTime.year,
        currentDateTime.month,
        currentDateTime.day,
        originalScheduledTime.hour,
        originalScheduledTime.minute);
    // Tìm ngày gần nhất trong tuần cho mỗi ngày yêu cầu
    while (!weekdaysSet.contains(newScheduledTime.weekday)) {
      newScheduledTime = newScheduledTime
          .add(Duration(days: 1)); // Tìm ngày tiếp theo trong tuần
    }
    // Kiểm tra xem thời gian có qua chưa, nếu có, chuyển sang ngày tiếp theo
    if (newScheduledTime.isBefore(currentDateTime)) {
      newScheduledTime = newScheduledTime
          .add(Duration(days: 7)); // Nếu đã qua, chuyển sang tuần sau
    }
    return newScheduledTime;
  }

  int _getWeekdayFromString(String day) {
    switch (day.toLowerCase()) {
      case 'monday':
        return DateTime.monday;
      case 'tuesday':
        return DateTime.tuesday;
      case 'wednesday':
        return DateTime.wednesday;
      case 'thursday':
        return DateTime.thursday;
      case 'friday':
        return DateTime.friday;
      case 'saturday':
        return DateTime.saturday;
      case 'sunday':
        return DateTime.sunday;
      default:
        return -1;
    }
  }

// Cập nhật để tránh lặp vô hạn và chỉ lấy các ngày trong tuần cần thông báo
  tz.TZDateTime _nextInstanceOfWeekday(
      tz.TZDateTime dateTime, Set<int> weekdaysSet) {
    tz.TZDateTime scheduledDate = tz.TZDateTime.from(dateTime, tz.local);
    do {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    } while (!weekdaysSet.contains(scheduledDate.weekday));
    return scheduledDate;
  }

  Future<void> cancelNotificationById(int id) async {
    try {
      await _localNotifications.cancel(id);
      print("Notification with ID $id canceled successfully.");
    } catch (e) {
      print("Error canceling notification: $e");
    }
  }

  Future<void> cancelAllNotifications() async {
    await _localNotifications.cancelAll();
  }

  Future<String> loadAllNotifications() async {
    String res = 'Có lỗi gì đó xảy ra';
    try {
      // Lấy lịch từ collection WorkoutSchedule của người dùng
      var workoutScheduleSnapshot = await _firestore
          .collection('WorkoutSchedule')
          .where('uid', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
          .get();
      // Duyệt qua các lịch và lên lịch lại thông báo
      for (var workoutScheduleDoc in workoutScheduleSnapshot.docs) {
        bool notify = workoutScheduleDoc['notify']; // Kiểm tra trường notify
        // Nếu notify là false, bỏ qua và không làm gì
        if (!notify) {
          continue; // Bỏ qua tài liệu này và tiếp tục với tài liệu tiếp theo
        }
        var workoutId = workoutScheduleDoc['id']; // Lấy ID của lịch
        var hour = workoutScheduleDoc['hour'];
        var day = workoutScheduleDoc['day'];
        var title = workoutScheduleDoc['name']; // Tiêu đề workout
        var repeatInterval = workoutScheduleDoc['repeat_interval'];
        var idCate = workoutScheduleDoc['id_cate'];
        var pic = workoutScheduleDoc['pic'];
        var diff = workoutScheduleDoc['difficulty'];

        final DateFormat dateFormat = DateFormat('dd/MM/yyyy');
        final DateFormat hourFormat = DateFormat('hh:mm a');
        DateTime selectedDay = dateFormat.parse(day);
        DateTime selectedHour = hourFormat.parse(hour);

        DateTime selectedDateTime = DateTime(
          selectedDay.year,
          selectedDay.month,
          selectedDay.day,
          selectedHour.hour,
          selectedHour.minute,
        );
        // Kiểm tra nếu lịch là trong quá khứ và không phải lịch lặp lại
        if (selectedDateTime.isBefore(DateTime.now()) &&
            repeatInterval == 'no') {
          continue;
        }
        // Lên lịch lại thông báo dựa trên thông tin từ Firestore
        String idNotify = await scheduleWorkoutNotification(
          id: workoutId,
          scheduledTime: selectedDateTime,
          workoutName: title,
          repeatInterval: repeatInterval,
          id_cate: idCate,
          pic: pic,
          diff: diff,
        );
        await _firestore
            .collection('WorkoutSchedule')
            .doc(workoutScheduleDoc.id) // Lấy ID tài liệu để cập nhật
            .update({
          'id_notify': idNotify, // Cập nhật id_notify với giá trị đã lấy
        });
        print('Notification ID updated for workout ${workoutScheduleDoc.id}');
      }

      var alarmScheduleSnapshot = await _firestore
          .collection('Alarm')
          .where('uid', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
          .get();

      for (var alarmScheduleDoc in alarmScheduleSnapshot.docs) {
        bool notifyBed = alarmScheduleDoc['notify_Bed'];
        bool notifyWakeup = alarmScheduleDoc['notify_Wakeup'];

        if (!notifyBed && !notifyWakeup) {
          continue;
        }
        var alarmId = alarmScheduleDoc['id'];
        var hourBed = alarmScheduleDoc['hourBed'];
        var hourWakeup = alarmScheduleDoc['hourWakeup'];
        var day = alarmScheduleDoc['day'];
        var repeatInterval = alarmScheduleDoc['repeat_interval'];
        var idNotify = alarmScheduleDoc['id_notify'];

        // Chuyển đổi chuỗi ngày và giờ thành DateTime
        final DateFormat dateFormat = DateFormat('dd/MM/yyyy');
        final DateFormat hourFormat = DateFormat('hh:mm a');
        DateTime selectedDay = dateFormat.parse(day);
        DateTime selectedHourBed = hourFormat.parse(hourBed);
        DateTime selectedHourWakeup = hourFormat.parse(hourWakeup);

        DateTime selectedDateTimeBed = DateTime(
          selectedDay.year,
          selectedDay.month,
          selectedDay.day,
          selectedHourBed.hour,
          selectedHourBed.minute,
        );

        DateTime selectedDateTimeWakeup = DateTime(
          selectedDay.year,
          selectedDay.month,
          selectedDay.day,
          selectedHourWakeup.hour,
          selectedHourWakeup.minute,
        );

        if (selectedDateTimeWakeup.isBefore(selectedDateTimeBed)) {
          selectedDateTimeWakeup =
              selectedDateTimeWakeup.add(const Duration(days: 1));
        }

        // Kiểm tra nếu lịch là trong quá khứ và không phải lịch lặp lại
        if (selectedDateTimeBed.isBefore(DateTime.now()) &&
            repeatInterval == 'no') {
          continue;
        }

        if (notifyBed) {
          idNotify = await scheduleBedtimeNotification(
            id: alarmId,
            bedtime: selectedDateTimeBed,
            repeatInterval: repeatInterval,
          );
        }
        if (notifyWakeup) {
          idNotify = await scheduleWakeUpNotification(
              id: alarmId,
              wakeUpTime: selectedDateTimeWakeup,
              repeatInterval: repeatInterval);
        }

        await _firestore.collection('Alarm').doc(alarmScheduleDoc.id).update({
          'id_notify': idNotify,
        });
      }

      // Bổ sung load lại notification cho MealSchedules
      var mealScheduleSnapshot = await _firestore
          .collection('MealSchedules')
          .where('uid', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
          .get();

      for (var mealScheduleDoc in mealScheduleSnapshot.docs) {
        final data = mealScheduleDoc.data();
        final dateStr = data['date'] as String;
        final date = DateFormat('yyyy-MM-dd').parse(dateStr);

        for (final type in ['breakfast', 'lunch', 'dinner', 'snacks']) {
          if (data.containsKey(type)) {
            final List<dynamic> meals = data[type];
            for (final m in meals) {
              // Nếu meal có notify = false thì bỏ qua
              if (m['notify'] == false) continue;

              final name = m['name'] ?? '';
              final pic = m['image'] ?? '';
              final mealType = type;
              final id = m['id_notify'] ?? '';
              final timeStr = m['time'] ?? '';
              if (id == '' || timeStr == '') continue;

              // Parse giờ (hh:mm a)
              DateTime mealTime;
              try {
                final time = DateFormat('hh:mm a').parse(timeStr);
                mealTime = DateTime(
                    date.year, date.month, date.day, time.hour, time.minute);
              } catch (e) {
                continue;
              }

              // Nếu lịch là trong quá khứ thì bỏ qua
              if (mealTime.isBefore(DateTime.now())) continue;

              // Lên lịch lại notification cho meal
              await scheduleMealNotification(
                id: id,
                mealType: mealType,
                Time: mealTime,
                Name: name,
                pic: pic,
              );
            }
          }
        }
      }
      res = "success";
    } catch (err) {
      return err.toString();
    }
    return res;
  }
}

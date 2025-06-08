import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../model/alarm_model.dart';
import 'notification_services.dart';

class AlarmService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationServices notificationServices = NotificationServices();

  Future<String> addAlarmSchedule({
    required String day,
    required String hourWakeup,
    required String hourBed,
    required String repeatInterval,
    required String uid,
    required bool notify_Bed,
    required bool notify_Wakeup,
  }) async {
    String res = "Có lỗi gì đó xảy ra";

    try {
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
      // Kiểm tra nếu thời gian đã chọn là quá khứ so với thời gian hiện tại
      if (selectedDateTimeBed.isBefore(DateTime.now())) {
        return "Error: The selected date and time cannot be in the past.";
      }
      if (selectedDateTimeWakeup.isBefore(selectedDateTimeBed)) {
        selectedDateTimeWakeup =
            selectedDateTimeWakeup.add(const Duration(days: 1));
      }
      CollectionReference alarmRef = _firestore.collection('Alarm');
      Map<String, dynamic> alarmData = {
        'day': day,
        'hourBed': hourBed,
        'hourWakeup': hourWakeup,
        'repeat_interval': repeatInterval,
        'uid': uid,
        'notify_Bed': notify_Bed,
        'notify_Wakeup': notify_Bed,
        'id_notify': '0',
      };
      DocumentReference docRef = await alarmRef.add(alarmData);
      await docRef.update({
        'id': docRef.id,
      });
      if (notify_Bed) {
        // Đặt lịch thông báo
        String idNotify =
            await notificationServices.scheduleBedtimeNotification(
          id: docRef.id,
          bedtime: selectedDateTimeBed,
          repeatInterval: repeatInterval,
        );
        await docRef.update({
          'id_notify': idNotify,
        });
      }
      if (notify_Wakeup) {
        String idNotify = await notificationServices.scheduleWakeUpNotification(
            id: docRef.id,
            wakeUpTime: selectedDateTimeWakeup,
            repeatInterval: repeatInterval);
        await docRef.update({
          'id_notify': idNotify,
        });
      }
      res = "success";
    } catch (e) {
      return "Error adding workout schedule: $e";
    }
    return res;
  }

  Future<List<AlarmSchedule>> fetchAlarmSchedules({required String uid}) async {
    List<AlarmSchedule> alarmSchedules = [];
    // Chuyển đổi chuỗi ngày và giờ thành DateTime
    final DateFormat dateFormat = DateFormat('dd/MM/yyyy');
    final DateFormat hourFormat = DateFormat('hh:mm a');

    try {
      // Lấy dữ liệu từ Firebase Collection
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('Alarm')
          .where('uid', isEqualTo: uid) // Lọc theo UID
          .orderBy('day') // Sắp xếp theo ngày tăng dần
          .get();

      for (var doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;

        // Chuyển đổi chuỗi ngày thành DateTime để xử lý
        final String day = data['day'];
        final String hourWakeup = data['hourWakeup'];

        DateTime selectedDay = dateFormat.parse(day);
        DateTime selectedHour = hourFormat.parse(hourWakeup);

        DateTime selectedDateTimeBed = DateTime(
          selectedDay.year,
          selectedDay.month,
          selectedDay.day,
          selectedHour.hour,
          selectedHour.minute,
        );
        // Lọc các lịch có repeat_interval là "no" và ngày đã qua
        if (data['repeat_interval'] == "no" &&
            selectedDateTimeBed.isBefore(DateTime.now())) {
          continue; // Bỏ qua lịch này
        }

        // Tạo đối tượng AlarmSchedule từ dữ liệu Firebase
        AlarmSchedule alarmSchedule = AlarmSchedule(
          day: data['day'],
          hourBed: data['hourBed'],
          hourWakeup: data['hourWakeup'],
          id: data['id'],
          idNotify: data['id_notify'],
          notifyBed: data['notify_Bed'],
          notifyWakeup: data['notify_Wakeup'],
          repeatInterval: data['repeat_interval'],
          uid: data['uid'],
        );

        alarmSchedules.add(alarmSchedule);
      }
    } catch (e) {
      print('Error fetching alarm schedules: $e');
    }

    return alarmSchedules;
  }

  Future<String> deleteAlarmSchedule({required String alarmId}) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('Alarm')
          .where('id', isEqualTo: alarmId)
          .get();

      var doc = snapshot.docs.first;
      String idNotify = doc['id_notify'];

      await notificationServices.cancelNotificationById(int.parse(idNotify));
      await notificationServices.removeAlarmNotifications(idNotify);
      await notificationServices
          .cancelNotificationById(int.parse(idNotify) + 1);
      await notificationServices
          .removeAlarmNotifications((int.parse(idNotify) + 1).toString());

      await FirebaseFirestore.instance
          .collection('Alarm')
          .doc(alarmId)
          .delete();

      return ('success');
    } catch (e) {
      return ('Error deleting workout schedule: $e');
    }
  }

  Future<String> updateAlarmSchedule({
    required String id,
    required String day,
    required String hourWakeup,
    required String hourBed,
    required String repeatInterval,
    required String uid,
    required bool notify_Bed,
    required bool notify_Wakeup,
    required String id_notify,
  }) async {
    String res = "Có lỗi gì đó xảy ra";
    String newidNotify = id_notify;
    try {
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
      await notificationServices.cancelNotificationById(int.parse(id_notify));
      await notificationServices.removeAlarmNotifications(id_notify);
      await notificationServices
          .cancelNotificationById(int.parse(id_notify) + 1);
      await notificationServices
          .removeAlarmNotifications((int.parse(id_notify) + 1).toString());

      if (notify_Bed) {
        // Đặt lịch thông báo
        newidNotify = await notificationServices.scheduleBedtimeNotification(
          id: id,
          bedtime: selectedDateTimeBed,
          repeatInterval: repeatInterval,
        );
      }
      if (notify_Wakeup) {
        newidNotify = await notificationServices.scheduleWakeUpNotification(
            id: id,
            wakeUpTime: selectedDateTimeWakeup,
            repeatInterval: repeatInterval);
      }

      // Cập nhật lại tài liệu với ID của tài liệu vào trường 'id'
      await _firestore.collection('Alarm').doc(id).update({
        'hourBed': hourBed,
        'hourWakeup': hourWakeup,
        'repeat_interval': repeatInterval,
        'notify_Bed': notify_Bed,
        'notify_Wakeup': notify_Wakeup,
        'id_notify': newidNotify,
        'day': day,
      });

      res = ("success");
    } catch (e) {
      return ("Error updating workout schedule: $e");
    }
    return res;
  }

  Future<List<AlarmSchedule>> fetchTodayAlarmSchedules(
      {required String uid}) async {
    List<AlarmSchedule> alarmSchedules = [];
    final DateFormat dateFormat = DateFormat('dd/MM/yyyy');
    final String currentDayOfWeek = DateFormat('EEEE').format(DateTime.now());
    final DateFormat hourFormat =
        DateFormat('hh:mm a'); // Lấy tên ngày hiện tại (e.g., Monday)

    try {
      // Lấy dữ liệu từ Firebase Collection
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('Alarm')
          .where('uid', isEqualTo: uid) // Lọc theo UID
          .orderBy('day') // Sắp xếp theo ngày tăng dần
          .get();

      for (var doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;

        // Kiểm tra ngày của lịch báo thức
        final String repeatInterval = data['repeat_interval'];

        // Chuyển đổi chuỗi ngày thành DateTime để xử lý
        final String day = data['day'];
        final String hourWakeup = data['hourWakeup'];

        DateTime selectedDay = dateFormat.parse(day);
        DateTime selectedHour = hourFormat.parse(hourWakeup);

        DateTime selectedDateTimeBed = DateTime(
          selectedDay.year,
          selectedDay.month,
          selectedDay.day,
          selectedHour.hour,
          selectedHour.minute,
        );

        bool isInRepeatInterval = repeatInterval.contains(currentDayOfWeek);

        // Lọc chỉ lấy ngày hợp lệ
        if (!selectedDateTimeBed.isBefore(DateTime.now()) ||
            repeatInterval == "Everyday" ||
            isInRepeatInterval) {
          AlarmSchedule alarmSchedule = AlarmSchedule(
            day: data['day'],
            hourBed: data['hourBed'],
            hourWakeup: data['hourWakeup'],
            id: data['id'],
            idNotify: data['id_notify'],
            notifyBed: data['notify_Bed'],
            notifyWakeup: data['notify_Wakeup'],
            repeatInterval: data['repeat_interval'],
            uid: data['uid'],
          );
          alarmSchedules.add(alarmSchedule);
        }
      }
    } catch (e) {
      print('Error fetching today alarm schedules: $e');
    }
    return alarmSchedules;
  }

  Future<int> calculateTotalSleepTime({required String uid}) async {
    int totalSleepMinutes = 0;
    final DateFormat dateFormat = DateFormat('dd/MM/yyyy');
    final DateFormat hourFormat = DateFormat('hh:mm a');

    // Xác định ngày hôm qua
    final DateTime yesterdayDate =
        DateTime.now().subtract(const Duration(days: 1));
    final DateTime yesterdayMidnight =
        DateTime(yesterdayDate.year, yesterdayDate.month, yesterdayDate.day);
    final String currentDayOfWeek = DateFormat('EEEE').format(yesterdayDate);

    try {
      // Lấy dữ liệu từ Firebase Collection
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('Alarm')
          .where('uid', isEqualTo: uid)
          .get();

      for (var doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;

        // Lấy các trường cần thiết
        final String repeatInterval = data['repeat_interval'];
        final String day = data['day'];
        final String hourBed = data['hourBed'];
        final String hourWakeup = data['hourWakeup'];

        // Chuyển đổi chuỗi thành DateTime
        DateTime? selectedDay;
        try {
          selectedDay = dateFormat.parse(day);
        } catch (e) {
          print('Invalid day format: $day');
          continue;
        }
        final DateTime selectedDayMidnight =
            DateTime(selectedDay.year, selectedDay.month, selectedDay.day);

        // Chuyển đổi giờ thành DateTime
        DateTime selectedHourBed = hourFormat.parse(hourBed);
        DateTime selectedHourWakeup = hourFormat.parse(hourWakeup);

        // Kết hợp ngày và giờ để tạo DateTime đầy đủ
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

        // Xử lý trường hợp giờ dậy là ngày tiếp theo
        if (selectedDateTimeWakeup.isBefore(selectedDateTimeBed)) {
          selectedDateTimeWakeup =
              selectedDateTimeWakeup.add(const Duration(days: 1));
        }

        // Kiểm tra nếu ngày hợp lệ
        bool isSameDay =
            selectedDayMidnight.isAtSameMomentAs(yesterdayMidnight);
        bool isInRepeatInterval = repeatInterval.contains(currentDayOfWeek);

        if (isSameDay ||
            repeatInterval == "Everyday" &&
                !selectedDay.isAfter(yesterdayMidnight) ||
            isInRepeatInterval) {
          // Tính tổng thời gian ngủ
          final int sleepDuration =
              selectedDateTimeWakeup.difference(selectedDateTimeBed).inMinutes;
          totalSleepMinutes +=
              sleepDuration >= 0 ? sleepDuration : (sleepDuration + 24 * 60);
        }
      }
    } catch (e) {
      print('Error fetching today alarm schedules: $e');
    }

    return totalSleepMinutes;
  }
}

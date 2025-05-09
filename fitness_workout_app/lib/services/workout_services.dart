import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../model/exercise_model.dart';
import '../model/workout_schedule_model.dart';
import 'notification_services.dart';

class WorkoutService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationServices notificationServices = NotificationServices();

  Future<List<Map<String, dynamic>>> fetchWorkoutList() async {
    List<Map<String, dynamic>> workoutList = [];

    try {
      // Truy vấn tất cả các Workouts
      QuerySnapshot workoutSnapshot =
      await _firestore.collection('Workouts').get();

      for (var workoutDoc in workoutSnapshot.docs) {
        String workoutId = workoutDoc.id;
        String image = workoutDoc['pic'];
        String title = workoutDoc['name'];
        List<String> exerciseNames = (workoutDoc['exercise_list'] as Map<dynamic, dynamic>)
            .values
            .map((e) => e.toString())
            .toList();
        List<String> levels = List<String>.from(workoutDoc['level']);
        List<String> tools = List<String>.from(workoutDoc['tool']);

        // Truy vấn Exercises với tên trong danh sách exercise_list
        QuerySnapshot exerciseSnapshot = await _firestore
            .collection('Exercises')
            .where('name', whereIn: exerciseNames)
            .get();

        // Tính toán tổng thời gian và calo
        int totalTimeInSeconds = 0;
        int totalCalo = 0;
        for (var exerciseDoc in exerciseSnapshot.docs) {
          var difficultyData = exerciseDoc['difficulty']['Beginner'];

          // Thời gian
          int exerciseTimeInSeconds = difficultyData['time'] ?? 0;
          totalTimeInSeconds += exerciseTimeInSeconds;

          // Calo
          int exerciseCalo = difficultyData['calo'] ?? 0;
          totalCalo += exerciseCalo;
        }

        // Chuyển đổi thời gian từ giây sang phút
        int totalTimeInMinutes = (totalTimeInSeconds / 60).round();

        // Thêm dữ liệu vào danh sách
        workoutList.add({
          'id': workoutId,
          'image': image,
          'title': title,
          'exercises': "${exerciseNames.length} Exercises",
          'time': "$totalTimeInMinutes Mins",
          'calo': "$totalCalo Calories Burn",
          'difficulty': 'Beginner',
          'levels': levels,
          'tools': tools,
        });
      }
    } catch (e) {
      print("Error fetching workouts: $e");
    }

    return workoutList;
  }

  Future<List<Map<String, dynamic>>> fetchWorkoutsByLevel({required String level}) async {
    List<Map<String, dynamic>> workoutList = [];

    try {
      // Truy vấn Workouts theo cấp độ
      QuerySnapshot workoutSnapshot = await _firestore
          .collection('Workouts')
          .where('level', arrayContains: level)
          .get();

      for (var workoutDoc in workoutSnapshot.docs) {
        String workoutId = workoutDoc.id;
        String image = workoutDoc['pic'];
        String title = workoutDoc['name'];
        List<String> exerciseNames = (workoutDoc['exercise_list'] as Map<dynamic, dynamic>)
            .values
            .map((e) => e.toString())
            .toList();

        // Truy vấn Exercises với tên bài tập trong exercise_list
        QuerySnapshot exerciseSnapshot = await _firestore
            .collection('Exercises')
            .where('name', whereIn: exerciseNames)
            .get();

        // Tính toán tổng thời gian và calo cho cấp độ Beginner
        int totalTimeInSeconds = 0;
        int totalCalo = 0;
        for (var exerciseDoc in exerciseSnapshot.docs) {
          var difficultyData = exerciseDoc['difficulty']['Beginner'];

          // Thời gian
          int exerciseTimeInSeconds = difficultyData['time'] ?? 0;
          totalTimeInSeconds += exerciseTimeInSeconds;

          // Calo
          int exerciseCalo = difficultyData['calo'] ?? 0;
          totalCalo += exerciseCalo;
        }

        // Chuyển đổi thời gian từ giây sang phút
        int totalTimeInMinutes = (totalTimeInSeconds / 60).round();

        // Thêm dữ liệu vào danh sách
        workoutList.add({
          'id': workoutId,
          'image': image,
          'title': title,
          'exercises': "${exerciseNames.length} Exercises",
          'time': "$totalTimeInMinutes Mins",
          'calo': "$totalCalo Calories Burn",
          'difficulty': 'Beginner',
        });
      }
    } catch (e) {
      print("Error fetching workouts by level: $e");
    }

    return workoutList;
  }

  Future<List<Map<String, dynamic>>> fetchToolsForWorkout(String workoutId) async {
    List<Map<String, dynamic>> toolsList = [];

    try {
      // Truy vấn tài liệu Workouts theo workoutId
      DocumentSnapshot workoutDoc = await FirebaseFirestore.instance
          .collection('Workouts')
          .doc(workoutId)
          .get();

      if (workoutDoc.exists) {
        // Lấy danh sách tools từ tài liệu Workouts
        List<String> toolNames = List<String>.from(workoutDoc['tool']);

        // Truy vấn chi tiết tools từ collection Tools
        QuerySnapshot toolsSnapshot = await FirebaseFirestore.instance
            .collection('Tools')
            .where('name', whereIn: toolNames)
            .get();

        // Chuyển đổi các document Tools thành map
        for (var toolDoc in toolsSnapshot.docs) {
          toolsList.add({
            'id': toolDoc.id,
            'title': toolDoc['name'],
            'image': toolDoc['pic'],
          });
        }
      }
    } catch (e) {
      print("Error fetching tools for workout: $e");
    }

    return toolsList;
  }

  Future<List<Exercise>> fetchExercisesFromWorkout({required String workoutId}) async {
    List<Exercise> exercises = [];

    try {
      // Bước 1: Lấy document của Workout
      DocumentSnapshot workoutDoc = await FirebaseFirestore.instance
          .collection('Workouts')
          .doc(workoutId)
          .get();

      if (workoutDoc.exists) {
        // Lấy danh sách name_exercise từ document
        List<String> exerciseNames = (workoutDoc['exercise_list'] as Map<dynamic, dynamic>)
            .values
            .map((e) => e.toString())
            .toList();

        if (exerciseNames.isNotEmpty) {
          // Bước 2: Lấy thông tin các bài tập từ collection Exercises
          QuerySnapshot exerciseSnapshot = await FirebaseFirestore.instance
              .collection('Exercises')
              .where('name', whereIn: exerciseNames)
              .get();

          // Bước 3: Chuyển đổi từng document thành đối tượng Exercise
          List<Exercise> unorderedExercises = exerciseSnapshot.docs
              .map((doc) => Exercise.fromJson(doc.data() as Map<String, dynamic>))
              .toList();

          // Bước 4: Sắp xếp danh sách theo thứ tự của exerciseNames
          exercises = exerciseNames.map((name) {
            return unorderedExercises.firstWhere((exercise) => exercise.name == name);
          }).toList();
        } else {
          print("No exercises found in workout $workoutId.");
        }
      } else {
        print("Workout with ID $workoutId does not exist.");
      }
    } catch (e) {
      print("Error fetching exercises from workout: $e");
    }

    return exercises;
  }

  Future<Map<String, String>> fetchTimeAndCalo({
    required String categoryId,
    required String difficulty,
  }) async {
    Map<String, String> data = {};

    try {
      // Bước 1: Truy vấn các bài tập thuộc category
      QuerySnapshot workoutSnapshot = await FirebaseFirestore.instance
          .collection('Workouts')
          .where('name', isEqualTo: categoryId)
          .get();

      // Bước 2: Tổng hợp thông tin từ từng bài tập
      int totalTimeInSeconds = 0;
      int totalCalo = 0;

      for (var workoutDoc in workoutSnapshot.docs) {
        // Lấy danh sách tên bài tập từ document
        List<String> exerciseNames = (workoutDoc['exercise_list'] as Map<dynamic, dynamic>)
            .values
            .map((e) => e.toString())
            .toList();

        if (exerciseNames.isNotEmpty) {
          // Truy vấn các bài tập dựa trên tên và độ khó
          QuerySnapshot exerciseSnapshot = await FirebaseFirestore.instance
              .collection('Exercises')
              .where('name', whereIn: exerciseNames)
              .get();

          for (var exerciseDoc in exerciseSnapshot.docs) {
            var difficultyData = exerciseDoc['difficulty'][difficulty];

            // Thời gian
            int exerciseTimeInSeconds = difficultyData['time'] ?? 0;
            totalTimeInSeconds += exerciseTimeInSeconds;

            // Calo
            int exerciseCalo = difficultyData['calo'] ?? 0;
            totalCalo += exerciseCalo;
          }
        }
      }

      // Bước 3: Chuyển đổi tổng thời gian sang phút
      int totalTimeInMinutes = (totalTimeInSeconds / 60).round();

      // Lưu kết quả vào map
      data['time'] = "$totalTimeInMinutes";
      data['calo'] = "$totalCalo";
    } catch (e) {
      print("Error fetching time and calo: $e");
    }
    return data;
  }

  Future<List<Map<String, dynamic>>> fetchWorkoutSchedule({
    required String userId,
  }) async {
    List<Map<String, dynamic>> workoutList = [];
    DateTime endDate = DateTime.now().add(Duration(days: 30));
    final DateFormat dateFormat = DateFormat(
        'dd/MM/yyyy hh:mm a'); // Định dạng mong muốn
    final DateFormat hourFormat = DateFormat(
        'hh:mm a'); // Định dạng giờ từ trường hour

    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('WorkoutSchedule')
          .where('uid', isEqualTo: userId)
          .get();

      for (var doc in snapshot.docs) {
        String repeatInterval = doc['repeat_interval'];
        DateTime startDate = DateFormat('dd/MM/yyyy').parse(doc['day']);
        String name = doc['name'];
        String hour = doc['hour'];
        String id = doc['id'];
        DateTime hourTime = hourFormat.parse(
            hour); // Chuyển chuỗi hour thành DateTime

        if (repeatInterval == "no") {
          // Nếu không có lặp lại, chỉ thêm sự kiện vào ngày đã chỉ định
          DateTime eventTime = DateTime(
              startDate.year, startDate.month, startDate.day,
              hourTime.hour, hourTime.minute
          );
          workoutList.add({
            "name": name,
            "start_time": dateFormat.format(eventTime),
            "id": id,
          });
        }
        else if (repeatInterval == "Everyday") {
          // Thêm sự kiện vào mỗi ngày từ ngày bắt đầu cho đến ngày kết thúc
          DateTime currentDate = startDate;
          while (currentDate.isBefore(endDate)) {
            DateTime eventTime = DateTime(
                currentDate.year, currentDate.month, currentDate.day,
                hourTime.hour, hourTime.minute
            );
            workoutList.add({
              "name": name,
              "start_time": dateFormat.format(eventTime), // Định dạng thời gian
              "id": id,
            });
            currentDate =
                currentDate.add(Duration(days: 1)); // Tiến tới ngày tiếp theo
          }
        }
        else {
          DateTime eventTime = DateTime(
              startDate.year, startDate.month, startDate.day,
              hourTime.hour, hourTime.minute
          );
          workoutList.add({
            "name": name,
            "start_time": dateFormat.format(eventTime),
            "id": id,
          });

          List<String> daysOfWeek = repeatInterval.split(',');
          DateTime currentDate = startDate;

          // Đảm bảo currentDate là ngày bắt đầu của tuần tính từ startDate
          currentDate =
              currentDate.subtract(Duration(days: currentDate.weekday - 1));

          while (currentDate.isBefore(endDate)) {
            for (var day in daysOfWeek) {
              DateTime eventTime = findNextDateForDay(day, currentDate);

              // Kiểm tra nếu eventTime là sau startDate và trước endDate
              if (eventTime.isAfter(startDate.subtract(Duration(days: 1))) &&
                  eventTime.isBefore(endDate)) {
                workoutList.add({
                  "name": name,
                  "start_time": dateFormat.format(DateTime(
                      eventTime.year, eventTime.month, eventTime.day,
                      hourTime.hour, hourTime.minute)),
                  "id": id,
                });
              }
            }

            // Tiến tới tuần tiếp theo, không thêm 7 ngày trực tiếp cho currentDate, chỉ tính lại ngày bắt đầu tuần mới
            currentDate = currentDate.add(Duration(days: 7));
          }
        }
      }
    } catch (e) {
      print("Error fetching workout schedule: $e");
    }
    //print("workout schedule: $workoutList");
    return workoutList;
  }

  DateTime findNextDateForDay(String day, DateTime currentDate) {
    // Mảng các ngày trong tuần
    List<String> days = [
      "Monday",
      "Tuesday",
      "Wednesday",
      "Thursday",
      "Friday",
      "Saturday",
      "Sunday"
    ];

    // Tìm chỉ số ngày trong tuần (0 = Monday, 6 = Sunday)
    int targetDayIndex = days.indexOf(day);

    // Tính số ngày còn lại để đến ngày mong muốn
    int daysToAdd = (targetDayIndex - (currentDate.weekday - 1) + 7) % 7;

    // Nếu daysToAdd là 0, nghĩa là ngày lặp lại là ngày hôm nay, ta chuyển sang tuần tiếp theo
    if (daysToAdd == 0) daysToAdd = 7;

    // Tính ngày tiếp theo
    return currentDate.add(Duration(days: daysToAdd));
  }

  Future<String> addWorkoutSchedule({
    required String day,
    required String difficulty,
    required String hour,
    required String name,
    required String repeatInterval,
    required String uid,
    required bool notify,
  }) async {
    String res = "Có lỗi gì đó xảy ra";

    try {
      // Kiểm tra nếu name hoặc difficulty trống
      if (name.isEmpty || difficulty.isEmpty) {
        return ("Error: Name and difficulty must not be empty.");
      }

      QuerySnapshot snapshot = await _firestore
          .collection('Workouts')
          .where('name', isEqualTo: name)
          .get();

      var doc = snapshot.docs.first;
      String id_workout = doc.id;
      String pic = doc['pic'];

      // Chuyển đổi chuỗi ngày và giờ thành DateTime
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

      // Kiểm tra nếu thời gian đã chọn là quá khứ so với thời gian hiện tại
      if (selectedDateTime.isBefore(DateTime.now())) {
        return "Error: The selected date and time cannot be in the past.";
      }

      bool isDuplicate = await _checkDuplicateEvent(
          uid, selectedDay, selectedHour);
      if (isDuplicate) {
        return "Error: A workout is already scheduled for this day and time.";
      }

      CollectionReference workoutScheduleRef = FirebaseFirestore.instance.collection('WorkoutSchedule');
      Map<String, dynamic> workoutData = {
        'day': day,
        'difficulty': difficulty,
        'hour': hour,
        'name': name,
        'repeat_interval': repeatInterval,
        'uid': uid,
        'notify': notify,
        'id_cate': id_workout,
        'pic': pic,
        'id_notify': '0',
      };
      DocumentReference docRef = await workoutScheduleRef.add(workoutData);
      await docRef.update({
        'id': docRef.id,
      });
      if(notify) {
        // Đặt lịch thông báo
        String id_notify = await notificationServices.scheduleWorkoutNotification(
          id: docRef.id,
          scheduledTime: selectedDateTime,
          workoutName: name,
          repeatInterval: repeatInterval,
          id_cate: id_workout,
          pic: pic,
          diff: difficulty,
        );
        await docRef.update({
          'id_notify': id_notify,
        });
      }

      res = "success";
    } catch (e) {
      return "Error adding workout schedule: $e";
    }

    return res;
  }

  Future<bool> _checkDuplicateEvent(String uid, DateTime day,
      DateTime hour) async {
    final DateFormat hourFormat = DateFormat('hh:mm a');

    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('WorkoutSchedule')
          .where('uid', isEqualTo: uid)
          .get();

      for (var doc in snapshot.docs) {
        DateTime eventDay = DateFormat('dd/MM/yyyy').parse(doc['day']);
        DateTime eventHour = hourFormat.parse(doc['hour']);

        // Kiểm tra nếu có sự kiện trùng lặp với ngày và giờ
        if (eventDay.isAtSameMomentAs(day) &&
            eventHour.isAtSameMomentAs(hour)) {
          return true; // Nếu trùng lặp, trả về true
        }
      }
    } catch (e) {
      print("Error checking duplicate event: $e");
    }
    return false; // Không có sự kiện trùng lặp
  }

  Future<bool> _checkDuplicateEventForUpdate(String uid, String id, DateTime day,
      DateTime hour) async {
    final DateFormat hourFormat = DateFormat('hh:mm a');

    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('WorkoutSchedule')
          .where('uid', isEqualTo: uid)
          .get();

      for (var doc in snapshot.docs) {
        DateTime eventDay = DateFormat('dd/MM/yyyy').parse(doc['day']);
        DateTime eventHour = hourFormat.parse(doc['hour']);

        if(doc.id == id) {continue;}
        // Kiểm tra nếu có sự kiện trùng lặp với ngày và giờ
        if (eventDay.isAtSameMomentAs(day) &&
            eventHour.isAtSameMomentAs(hour)) {
          return true; // Nếu trùng lặp, trả về true
        }
      }
    } catch (e) {
      print("Error checking duplicate event: $e");
    }
    return false; // Không có sự kiện trùng lặp
  }

  Future<String> deleteWorkoutSchedule({required String scheduleId}) async {
    try {

      QuerySnapshot snapshot = await _firestore
          .collection('WorkoutSchedule')
          .where('id', isEqualTo: scheduleId)
          .get();

      var doc = snapshot.docs.first;
      String id_notify = doc['id_notify'];
      String id_cate = doc['id_cate'];

      await notificationServices.cancelNotificationById(int.parse(id_notify));

      await notificationServices.removeNotification(id_cate);

      // Truy cập đến collection 'WorkoutSchedule' và xoá tài liệu theo id
      await FirebaseFirestore.instance
          .collection('WorkoutSchedule')
          .doc(scheduleId)
          .delete();

      return ('success');
    } catch (e) {
      return ('Error deleting workout schedule: $e');
    }
  }

  Future<WorkoutSchedule> getWorkoutScheduleById(
      {required String scheduleId}) async {
    DocumentSnapshot doc = await _firestore.collection("WorkoutSchedule")
        .doc(scheduleId)
        .get();
    return WorkoutSchedule.fromJson(doc.data() as Map<String, dynamic>);
  }

  Future<String> updateSchedule({
    required String id,
    required String day,
    required String difficulty,
    required String hour,
    required String name,
    required String repeatInterval,
    required String uid,
    required bool notify,
    required String id_notify,
  }) async {
    String res = "Có lỗi gì đó xảy ra";
    String newid_notify = id_notify;

    try {
      // Kiểm tra nếu name hoặc difficulty trống
      if (name.isEmpty || difficulty.isEmpty) {
        return ("Error: Name and difficulty must not be empty.");
      }

      QuerySnapshot snapshot = await _firestore
          .collection('Workouts')
          .where('name', isEqualTo: name)
          .get();

      var doc = snapshot.docs.first; // Lấy tài liệu đầu tiên
      String id_workout = doc.id;
      String pic = doc['pic'];

      // Chuyển day và hour thành DateTime để kiểm tra trùng lặp và thời gian hợp lệ
      final DateFormat dateFormat = DateFormat('dd/MM/yyyy');
      final DateFormat hourFormat = DateFormat('hh:mm a');
      DateTime selectedDay = dateFormat.parse(day); // Parse day thành DateTime
      DateTime selectedHour = hourFormat.parse(hour); // Parse hour thành DateTime
      // Kết hợp ngày và giờ thành một đối tượng DateTime
      DateTime selectedDateTime = DateTime(
          selectedDay.year,
          selectedDay.month,
          selectedDay.day,
          selectedHour.hour,
          selectedHour.minute
      );
      // Kiểm tra nếu thời gian đã chọn là quá khứ so với thời gian hiện tại
      if (selectedDateTime.isBefore(DateTime.now())) {
        return "Error: The selected date and time cannot be in the past.";
      }
      // Kiểm tra nếu đã có sự kiện trùng lặp trong Firestore
      bool isDuplicate = await _checkDuplicateEventForUpdate(
          uid, id, selectedDay, selectedHour);
      if (isDuplicate) {
        return "Error: A workout is already scheduled for this day and time.";
      }

      await notificationServices.cancelNotificationById(int.parse(id_notify));
      await notificationServices.removeNotification(name);

      if(notify) {
        newid_notify = await notificationServices.scheduleWorkoutNotification(
          id: id,
          scheduledTime: selectedDateTime,
          workoutName: name,
          repeatInterval: repeatInterval,
          id_cate: id_workout,
          pic: pic,
          diff: difficulty,
        );
      }

      // Cập nhật lại tài liệu với ID của tài liệu vào trường 'id'
      await _firestore.collection('WorkoutSchedule').doc(id).update({
        'difficulty': difficulty,
        'hour': hour,
        'name': name,
        'repeat_interval': repeatInterval,
        'notify': notify,
        'id_cate': id_workout,
        'pic': pic,
        'id_notify': newid_notify,
      });

      res = ("success");
    } catch (e) {
      return ("Error updating workout schedule: $e");
    }
    return res;
  }

  Future<String> createEmptyWorkoutHistory({
    required String uid,
    required String idCate,
    required List<Exercise> exercisesArr,
    required String difficulty,
  }) async {
    final historyData = {
      'uid': uid,
      'id_cate': idCate,
      'exercisesArr': exercisesArr.map((e) => e.toFirestore()).toList(),
      'index': 0,
      'duration': 0,
      'caloriesBurned': 0,
      'completedAt': null,
      'difficulty': difficulty,
    };

    // Lưu vào Firestore (hoặc MongoDB tùy vào cấu trúc database của bạn)
    final docRef = await FirebaseFirestore.instance
        .collection('WorkoutHistory')
        .add(historyData);

    await FirebaseFirestore.instance
        .collection('WorkoutHistory')
        .doc(docRef.id)
        .update({
      'id': docRef.id,
    });

    return docRef.id; // Trả về workoutId
  }

  Future<void> updateWorkoutHistory({
    required String historyId,
    required int index,
    required int duration,
    required int caloriesBurned,
    required DateTime completedAt,
  }) async {
    final collection = FirebaseFirestore.instance.collection('WorkoutHistory');

    // Lấy dữ liệu hiện tại của lịch sử
    final historyDoc = await collection.doc(historyId).get();

    final data = historyDoc.data();

    // Lấy tổng thời gian và calo đã lưu trước đó
    int previousTotalTime = data?['duration'] ?? 0;
    int previousTotalCalo = data?['caloriesBurned'] ?? 0;

    // print('calo: $previousTotalCalo');
    // print('time: $previousTotalTime');

    // Cộng dồn thời gian và calo
    int newTotalTime = previousTotalTime + duration;
    int newTotalCalo = previousTotalCalo + caloriesBurned;

    // print('New calo: $newTotalCalo');
    // print('New time: $newTotalTime');

    await FirebaseFirestore.instance
        .collection('WorkoutHistory')
        .doc(historyId)
        .update({
      'index': index,
      'duration': newTotalTime,
      'caloriesBurned': newTotalCalo,
      'completedAt': completedAt,
    });
  }

  Future<Map<String, int>> getWorkoutHistory({
    required String historyId,
  }) async {
    final collection = FirebaseFirestore.instance.collection('WorkoutHistory');

    try {
      // Lấy dữ liệu từ Firestore bằng historyId
      final historyDoc = await collection.doc(historyId).get();

      // Kiểm tra nếu tài liệu tồn tại
      if (historyDoc.exists) {
        final data = historyDoc.data();

        // Lấy giá trị caloriesBurned và duration từ dữ liệu
        int caloriesBurned = data?['caloriesBurned'] ?? 0;
        int duration = data?['duration'] ?? 0;

        return {
          'caloriesBurned': caloriesBurned,
          'duration': duration,
        };
      } else {
        // Trường hợp không tìm thấy tài liệu
        print('No workout history found for the given ID');
        return {
          'caloriesBurned': 0,
          'duration': 0,
        };
      }
    } catch (e) {
      print('Error fetching workout history: $e');
      return {
        'caloriesBurned': 0,
        'duration': 0,
      };
    }
  }

  Future<List<Map<String, dynamic>>> fetchWorkoutHistory({
    required String uid,
  }) async {
    List<Map<String, dynamic>> resultList = [];

    try {
      // Lấy danh sách tài liệu từ WorkoutHistory theo uid
      QuerySnapshot workoutSnapshot = await FirebaseFirestore.instance
          .collection('WorkoutHistory')
          .where('uid', isEqualTo: uid)
          .orderBy('completedAt', descending: true)
          .get();

      for (var doc in workoutSnapshot.docs) {
        final historyData = doc.data() as Map<String, dynamic>;

        // Lấy thông tin từ id_cate trong CategoryWorkout
        String idCate = historyData['id_cate'];
        DocumentSnapshot categorySnapshot = await FirebaseFirestore.instance
            .collection('Workouts')
            .doc(idCate)
            .get();

        final categoryData = categorySnapshot.data() as Map<String, dynamic>?;

        // Chuyển đổi exercisesArr từ List<dynamic> thành List<Exercise>
        List<Exercise> exercisesArr = (historyData['exercisesArr'] as List)
            .map((exercise) => Exercise.fromJson(exercise))
            .toList();

        // Tính toán 'process'
        int index = historyData['index'] ?? 0;
        double progress = exercisesArr.isNotEmpty ? ((index + 1) / exercisesArr.length) : 0.0;

        // Thêm vào danh sách kết quả
        resultList.add({
          'id': doc.id,
          'name': categoryData?['name'] ?? 'No Name',
          'image': categoryData?['pic'] ?? '',
          'index': index,
          'progress': progress,
          'exercisesArr': exercisesArr,
          'calo': historyData['caloriesBurned'] ?? 0,
          'time': (historyData['duration']! / 60) ?? 0,
          'completedAt': historyData['completedAt'],
          'difficulty': historyData['difficulty']
        });
      }
    } catch (e) {
      print('Error fetching workout history: $e');
    }
    return resultList;
  }

  Future<List<WorkoutSchedule>> getClosestWorkoutSchedules({
    required String uid,
  }) async {
    try {
      // Lấy toàn bộ danh sách theo uid
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('WorkoutSchedule')
          .where('uid', isEqualTo: uid)
          .get();
      // Chuyển đổi dữ liệu
      List<WorkoutSchedule> workoutSchedules = querySnapshot.docs
          .map((doc) => WorkoutSchedule.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
      // Lọc và sắp xếp
      List<WorkoutSchedule> filteredSchedules = workoutSchedules.where((doc) {
        DateTime? time = parseDate(doc.day, doc.hour);
        return time != null && !(time.isBefore(DateTime.now()) && doc.repeatInterval == 'no');
      }).toList();
      // Sắp xếp theo ngày tăng dần
      filteredSchedules.sort((a, b) {
        DateTime dateA = parseDate(a.day, a.hour)!;
        DateTime dateB = parseDate(b.day, b.hour)!;
        return dateA.compareTo(dateB);
      });

      return filteredSchedules.take(2).toList();
    } catch (e) {
      print("Lỗi khi lấy WorkoutSchedule: $e");
      return [];
    }
  }

  DateTime? parseDate(String day, String hour) {
    try {
      return DateFormat("dd/MM/yyyy h:mm a").parse("$day $hour");
    } catch (e) {
      print("Lỗi khi parse ngày giờ: $e");
      return null;
    }
  }

  Future<Map<String, List<FlSpot>>> generateWeeklyData({
    required String uid,
  }) async {
    DateTime now = DateTime.now();
    DateTime startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    //print("Start: $startOfWeek");
    DateTime endOfWeek = startOfWeek.add(Duration(days: 6));
    //print("End: $endOfWeek");

    Map<int, double> caloriesByDay = {for (int i = 1; i <= 7; i++) i: 0};
    Map<int, double> durationByDay = {for (int i = 1; i <= 7; i++) i: 0};

    QuerySnapshot workoutSnapshot = await FirebaseFirestore.instance
        .collection('WorkoutHistory')
        .where('uid', isEqualTo: uid)
        .where('completedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfWeek))
        .where('completedAt', isLessThanOrEqualTo: Timestamp.fromDate(endOfWeek))
        .get();

    for (var doc in workoutSnapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      DateTime completedAt = DateTime.fromMillisecondsSinceEpoch(data['completedAt'].seconds * 1000);
      int weekday = completedAt.weekday;

      caloriesByDay[weekday] = caloriesByDay[weekday]! + (data['caloriesBurned'] ?? 0.0);
      durationByDay[weekday] = durationByDay[weekday]! + (data['duration'] ?? 0.0);
    }

    List<FlSpot> calorieSpots = [];
    List<FlSpot> durationSpots = [];
    for (int i = 1; i <= 7; i++) {
      calorieSpots.add(FlSpot(i.toDouble(), caloriesByDay[i]!));
      durationSpots.add(FlSpot(i.toDouble(), durationByDay[i]!));
    }

    return {
      'calories': calorieSpots,
      'duration': durationSpots,
    };
  }
}





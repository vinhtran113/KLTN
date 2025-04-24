import 'dart:async';
import 'package:fitness_workout_app/view/workout_tracker/ready_view.dart';
import 'package:flutter/material.dart';
import 'package:fitness_workout_app/view/workout_tracker/breaktime_view.dart';
import 'package:provider/provider.dart';

import '../../common/colo_extension.dart';
import '../../model/exercise_model.dart';
import '../../services/workout_tracker.dart';
import 'finished_workout_view.dart';
import '../../main.dart';
import '../../localization/app_localizations.dart';

class WorkOutDet extends StatelessWidget {
  final List<Exercise> exercises;
  final int index;
  final String historyId;
  final String diff;

  const WorkOutDet({
    Key? key,
    required this.exercises,
    required this.index,
    required this.historyId,
    required this.diff,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currentExercise = exercises[index];
    final WorkoutService _workoutService = WorkoutService();
    bool darkmode = darkModeNotifier.value;

    return ChangeNotifierProvider<TimerModelSec>(
      create: (context) => TimerModelSec(
          context, currentExercise.difficulty[diff]!.time, exercises, index,
          historyId, diff),
      child: PopScope(
        canPop: false, // Ngừng việc quay lại màn hình trước
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) {
            // Hiển thị hộp thoại xác nhận hoặc xử lý gì đó nếu pop không thành công
            Provider.of<TimerModelSec>(context, listen: false).show();
          }
        },
        child: Scaffold(
          backgroundColor: darkmode? Colors.blueGrey[900] : TColor.white,
          body: Stack(
            children: [
              Container(
                child: Column(
                  children: [
                    Container(
                      height: 350,
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          fit: BoxFit.cover,
                          image: NetworkImage(currentExercise.pic.toString()),
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      currentExercise.name.toString(),
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 35),
                    ),
                    const Spacer(),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 80),
                      padding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 25),
                      decoration: BoxDecoration(
                        color: Colors.blueAccent,
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: currentExercise.difficulty[diff]!.rep == 0
                          ? Consumer<TimerModelSec>(
                        builder: (context, myModel, child) {
                          int minutes = myModel.countdown ~/ 60;
                          int seconds = myModel.countdown % 60;
                          return Text(
                            "${minutes.toString().padLeft(2, '0')} : ${seconds
                                .toString().padLeft(2, '0')}",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 30,
                              color: Colors.white,
                            ),
                          );
                        },
                      )
                          : Text(
                        "x${currentExercise.difficulty[diff]!.rep}",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 30,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const Spacer(),
                    const SizedBox(height: 30,),
                    Consumer<TimerModelSec>(
                      builder: (context, myModel, child) {
                        return ElevatedButton(onPressed: () {
                          myModel.show();
                        }, child: Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 10, horizontal: 15),
                            child: Text(
                                AppLocalizations.of(context)?.translate("PAUSE") ?? "PAUSE",
                              style: TextStyle(fontSize: 20),)));
                      },
                    ),
                    Spacer(),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 15),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          index != 0
                              ? Consumer<TimerModelSec>(
                            builder: (context, myModel, child) {
                              return TextButton(
                                onPressed: () async {
                                  // Tính toán thời gian thực tế và lượng calo
                                  final currentExercise = exercises[index];
                                  final realTime = currentExercise
                                      .difficulty[diff]!.time -
                                      myModel.countdown; // Thời gian thực tế
                                  final caloriesBurned = (realTime *
                                      currentExercise.difficulty[diff]!.calo) ~/
                                      currentExercise.difficulty[diff]!
                                          .time; // Tính calo

                                  // Cập nhật lịch sử trước khi chuyển bài
                                  await _workoutService.updateWorkoutHistory(
                                    historyId: historyId,
                                    index: index,
                                    duration: realTime,
                                    caloriesBurned: caloriesBurned,
                                    completedAt: DateTime.now(),
                                  );

                                  myModel.Pass(); // Dừng bộ đếm thời gian
                                  await Future.delayed(
                                      const Duration(seconds: 1));
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          BreakTime(
                                            exercises: exercises,
                                            index: index,
                                            historyId: historyId,
                                            diff: diff,
                                          ),
                                    ),
                                  );
                                },
                                child: Text(
                                    AppLocalizations.of(context)?.translate("Previous") ?? "Previous",
                                  style: TextStyle(fontSize: 16),
                                ),
                              );
                            },
                          )
                              : Container(),
                          Consumer<TimerModelSec>(
                            builder: (context, myModel, child) {
                              return TextButton(
                                onPressed: () async {
                                  // Tính toán thời gian thực tế và lượng calo
                                  final currentExercise = exercises[index];
                                  final realTime = currentExercise
                                      .difficulty[diff]!.time -
                                      myModel.countdown; // Thời gian thực tế
                                  final caloriesBurned = (realTime *
                                      currentExercise.difficulty[diff]!.calo) ~/
                                      currentExercise.difficulty[diff]!
                                          .time; // Tính calo

                                  // Cập nhật lịch sử trước khi chuyển bài
                                  await _workoutService.updateWorkoutHistory(
                                    historyId: historyId,
                                    index: index,
                                    duration: realTime,
                                    caloriesBurned: caloriesBurned,
                                    completedAt: DateTime.now(),
                                  );

                                  myModel.Pass(); // Dừng bộ đếm thời gian
                                  await Future.delayed(
                                      const Duration(seconds: 1));

                                  // Kiểm tra nếu đây là bài tập cuối cùng
                                  if (index == exercises.length - 1) {
                                    Navigator.of(context).pushAndRemoveUntil(
                                      MaterialPageRoute(
                                        builder: (context) => FinishedWorkoutView(historyId: historyId,),
                                      ),
                                          (route) => false, // Xóa toàn bộ route cũ
                                    );
                                  } else {
                                    // Nếu không, điều hướng đến bài tập tiếp theo
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            BreakTime(
                                              exercises: exercises,
                                              index: index + 1,
                                              historyId: historyId,
                                              diff: diff,
                                            ),
                                      ),
                                    );
                                  }
                                },
                                child: Text(
                                  index == exercises.length - 1
                                      ? AppLocalizations.of(context)?.translate("Finish") ?? "Finish"
                                      : AppLocalizations.of(context)?.translate("Next") ?? "Next",
                                  style: const TextStyle(fontSize: 16),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const Divider(thickness: 2,),
                    Align(
                        alignment: Alignment.bottomLeft,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 10, horizontal: 15),
                          child: Text("${AppLocalizations.of(context)?.translate("Next:") ?? "Next:"} ${index != exercises.length - 1
                              ? exercises[index + 1].name
                              : AppLocalizations.of(context)?.translate("Finish") ?? "Finish"}",
                            style: const TextStyle(fontSize: 18,
                                fontWeight: FontWeight.bold),),
                        ))
                  ],
                ),
              ),
              Consumer<TimerModelSec>(
                builder: (context, myModel, child) {
                  return Visibility(
                      visible: myModel.visible,
                      child: Container(
                        color: Colors.blueAccent.withOpacity(0.9),
                        height: MediaQuery
                            .of(context)
                            .size
                            .height,
                        width: MediaQuery
                            .of(context)
                            .size
                            .width,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(AppLocalizations.of(context)?.translate("Pause") ?? "Pause", style: TextStyle(fontSize: 40,
                                color: Colors.white,
                                fontWeight: FontWeight.bold),),
                            const SizedBox(height: 30,),
                            OutlinedButton(
                              onPressed: () {
                                // Hiển thị hộp thoại xác nhận
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title: const Text("Xác nhận"),
                                      content: const Text(
                                          "Bạn có chắc chắn muốn khởi động lại không?"),
                                      actions: <Widget>[
                                        TextButton(
                                          onPressed: () {
                                            // Nếu người dùng nhấn "Không", đóng hộp thoại
                                            Navigator.of(context).pop();
                                          },
                                          child: const Text("Không"),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            // Nếu người dùng nhấn "Có", điều hướng đến ReadyView
                                            Navigator.of(context)
                                                .pop(); // Đóng hộp thoại trước
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => ReadyView(
                                                  exercises: exercises,
                                                  index: 0,
                                                  historyId: historyId,
                                                  diff: diff,),
                                              ),
                                            );
                                          },
                                          child: const Text("Có"),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                              child: Container(
                                width: 180,
                                child: Text(
                                    AppLocalizations.of(context)?.translate("Restart") ?? "Restart",
                                  style: TextStyle(color: Colors.white),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                            OutlinedButton(
                              onPressed: () {
                                // Hiển thị hộp thoại xác nhận
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title: Text("Xác nhận"),
                                      content: Text(
                                          "Bạn có chắc chắn muốn thoát không?"),
                                      actions: <Widget>[
                                        TextButton(
                                          onPressed: () {
                                            // Nếu người dùng nhấn "Không", đóng hộp thoại
                                            Navigator.of(context).pop();
                                          },
                                          child: Text("Không"),
                                        ),
                                        TextButton(
                                          onPressed: () async {
                                            // Tính toán thời gian thực tế và lượng calo
                                            final currentExercise = exercises[index];
                                            final realTime = currentExercise
                                                .difficulty[diff]!.time -
                                                myModel
                                                    .countdown; // Thời gian thực tế
                                            final caloriesBurned = (realTime *
                                                currentExercise
                                                    .difficulty[diff]!.calo) ~/
                                                currentExercise
                                                    .difficulty[diff]!
                                                    .time; // Tính calo

                                            // Cập nhật lịch sử trước khi chuyển bài
                                            await _workoutService
                                                .updateWorkoutHistory(
                                              historyId: historyId,
                                              index: index,
                                              duration: realTime,
                                              caloriesBurned: caloriesBurned,
                                              completedAt: DateTime.now(),
                                            );

                                            // Nếu người dùng nhấn "Có", điều hướng đến WorkoutTrackerView
                                            Navigator.of(context)
                                                .pop(); // Đóng hộp thoại trước
                                            Navigator.of(context).pushAndRemoveUntil(
                                              MaterialPageRoute(
                                                builder: (context) => FinishedWorkoutView(historyId: historyId,),
                                              ),
                                                  (route) => false, // Xóa toàn bộ route cũ
                                            );
                                          },
                                          child: Text("Có"),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                              child: Container(
                                width: 180,
                                child: Text(
                                  AppLocalizations.of(context)?.translate("Quit") ?? "Quit",
                                  style: TextStyle(color: Colors.white),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                            OutlinedButton(onPressed: () {
                              myModel.hide();
                            }, child: Container(
                              width: 180,
                              child: Text(
                                AppLocalizations.of(context)?.translate("Resume") ?? "Resume", textAlign: TextAlign.center),
                            ), style: ButtonStyle(
                                backgroundColor: MaterialStateProperty.all(
                                    Colors.white)),)
                          ],
                        ),
                      )
                  );
                },
              )
            ],
          ),
        ),
      ),
    );
  }
}

class TimerModelSec with ChangeNotifier {
  int countdown;
  bool visible = false;
  bool isPassed = false;
  Timer? _timer;
  final String historyId;
  final WorkoutService _workoutService = WorkoutService();
  final String diff;

  TimerModelSec(BuildContext context, int initialTime, List<Exercise> exercises, int index, this.historyId, this.diff) : countdown = initialTime {
    _startTimer(context, exercises, index);
  }

  void _startTimer(BuildContext context, List<Exercise> exercises, int index) {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (!visible && !isPassed) {
        countdown--;
        notifyListeners();

        if (countdown <= 0) {
          timer.cancel();

          // Cập nhật lịch sử tập luyện sau khi hoàn thành bài tập
          final exercise = exercises[index];
          await _workoutService.updateWorkoutHistory(
            historyId: historyId,
            index: index,
            duration: exercise.difficulty[diff]!.time,
            caloriesBurned: exercise.difficulty[diff]!.calo,
            completedAt: DateTime.now(),
          );
          if (index >= exercises.length - 1) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (context) => FinishedWorkoutView(historyId: historyId,),
              ),
                  (route) => false, // Xóa toàn bộ route cũ
            );
          } else {
            // Chuyển đến bài tập tiếp theo
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    BreakTime(
                      exercises: exercises,
                      index: index + 1,
                      historyId: historyId,
                      diff: diff,
                    ),
              ),
            );
          }
        }
      } else if (isPassed) {
        timer.cancel();
      }
    });
  }

  void show() {
    visible = true;
    notifyListeners();
  }

  void hide() {
    visible = false;
    notifyListeners();
  }

  void Pass() {
    isPassed = true;
    _timer?.cancel();
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

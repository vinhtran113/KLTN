import 'package:fitness_workout_app/model/step_exercise_model.dart';

class Exercise {
  final String name;
  final String pic;
  final String descriptions;
  final Map<String, Difficulty> difficulty;
  final Map<int, StepExerciseModel> steps;
  final String video;

  Exercise({
    required this.name,
    required this.pic,
    required this.descriptions,
    required this.difficulty,
    required this.steps,
    required this.video,
  });

  // Chuyển đổi từ Firestore document thành đối tượng Exercise
  factory Exercise.fromJson(Map<String, dynamic> data) {
    // Parse difficulty thành map
    Map<String, Difficulty> parsedDifficulty = {};
    if (data['difficulty'] != null) {
      data['difficulty'].forEach((key, value) {
        parsedDifficulty[key] = Difficulty.fromJson(value);
      });
    }

    // Parse steps thành map
    Map<int, StepExerciseModel> parsedSteps = {};
    if (data['step'] != null) {
      data['step'].forEach((key, value) {
        parsedSteps[int.parse(key)] = StepExerciseModel.fromJson(value);
      });
    }

    return Exercise(
      name: data['name'] ?? '',
      pic: data['pic'] ?? '',
      descriptions: data['descriptions'] ?? '',
      difficulty: parsedDifficulty,
      steps: parsedSteps,
      video: data['video'] ?? '',
    );
  }

  // Chuyển đổi đối tượng Exercise thành Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'pic': pic,
      'descriptions': descriptions,
      'difficulty': difficulty.map((key, value) => MapEntry(key, value.toFirestore())),
      'step': steps.map((key, value) => MapEntry(key.toString(), value.toFirestore())),
      'video': video,
    };
  }
}

class Difficulty {
  final int calo;
  final int rep;
  final int time;

  Difficulty({
    required this.calo,
    required this.rep,
    required this.time,
  });

  // Chuyển đổi từ Firestore document thành đối tượng Difficulty
  factory Difficulty.fromJson(Map<String, dynamic> data) {
    return Difficulty(
      calo: data['calo'] ?? 0,
      rep: data['rep'] ?? 0,
      time: data['time'] ?? 0,
    );
  }

  // Chuyển đổi đối tượng Difficulty thành Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'calo': calo,
      'rep': rep,
      'time': time,
    };
  }
}



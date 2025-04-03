class StepExerciseModel {
  final String title;
  final String detail;

  StepExerciseModel({
    required this.title,
    required this.detail,
  });

  // Chuyển đổi từ Firestore document thành đối tượng Step
  factory StepExerciseModel.fromJson(Map<String, dynamic> data) {
    return StepExerciseModel(
      title: data['title'] ?? '',
      detail: data['detail'] ?? '',
    );
  }

  // Chuyển đổi đối tượng Step thành Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'detail': detail,
    };
  }
}

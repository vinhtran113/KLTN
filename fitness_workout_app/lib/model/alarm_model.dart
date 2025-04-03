class AlarmSchedule {
  final String day;
  final String hourBed;
  final String hourWakeup;
  final String id;
  final String idNotify;
  final bool notifyBed;
  final bool notifyWakeup;
  final String repeatInterval;
  final String uid;

  AlarmSchedule({
    required this.day,
    required this.hourBed,
    required this.hourWakeup,
    required this.id,
    required this.idNotify,
    required this.notifyBed,
    required this.notifyWakeup,
    required this.repeatInterval,
    required this.uid,
  });

  // Phương thức để chuyển từ JSON sang đối tượng Dart
  factory AlarmSchedule.fromJson(Map<String, dynamic> json) {
    return AlarmSchedule(
      day: json['day'] as String,
      hourBed: json['hourBed'] as String,
      hourWakeup: json['hourWakeup'] as String,
      id: json['id'] as String,
      idNotify: json['id_notify'] as String,
      notifyBed: json['notify_Bed'] as bool,
      notifyWakeup: json['notify_Wakeup'] as bool,
      repeatInterval: json['repeat_interval'] as String,
      uid: json['uid'] as String,
    );
  }

  // Phương thức để chuyển từ đối tượng Dart sang JSON
  Map<String, dynamic> toJson() {
    return {
      'day': day,
      'hourBed': hourBed,
      'hourWakeup': hourWakeup,
      'id': id,
      'id_notify': idNotify,
      'notify_Bed': notifyBed,
      'notify_Wakeup': notifyWakeup,
      'repeat_interval': repeatInterval,
      'uid': uid,
    };
  }
}

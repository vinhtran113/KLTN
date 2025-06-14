import 'package:flutter/material.dart';
import '../common/colo_extension.dart';
import '../../localization/app_localizations.dart';

class RepetitionsRow extends StatefulWidget {
  final String icon;
  final String title;
  final Color color;
  final TextEditingController repetitionController;

  const RepetitionsRow({
    super.key,
    required this.icon,
    required this.title,
    required this.color,
    required this.repetitionController,
  });

  @override
  _RepetitionsRowState createState() => _RepetitionsRowState();
}

class _RepetitionsRowState extends State<RepetitionsRow> {
  List<String> daysOfWeek = [
    "Monday",
    "Tuesday",
    "Wednesday",
    "Thursday",
    "Friday",
    "Saturday",
    "Sunday"
  ];

  Map<String, bool> selectedDays = {
    "Monday": false,
    "Tuesday": false,
    "Wednesday": false,
    "Thursday": false,
    "Friday": false,
    "Saturday": false,
    "Sunday": false
  };

  bool isEveryday = false;

  @override
  void initState() {
    super.initState();
    _initializeRepetitions();
  }

  // Hàm này sẽ được gọi để khởi tạo giá trị dựa trên dữ liệu đã truyền vào
  void _initializeRepetitions() {
    String repetition = widget.repetitionController.text;

    if (repetition == "Everyday") {
      isEveryday = true;
      selectedDays.updateAll((key, value) => true); // Chọn tất cả các ngày
    } else if (repetition == "no") {
      isEveryday = false;
      selectedDays.updateAll((key, value) => false); // Hủy chọn tất cả các ngày
    } else {
      isEveryday = false;
      // Nếu là chuỗi các ngày, tách và đánh dấu những ngày tương ứng
      List<String> daysList = repetition.split(",");
      for (String day in daysList) {
        if (selectedDays.containsKey(day)) {
          selectedDays[day] = true;
        }
      }
    }
    setState(() {});
  }

  void _showRepetitionSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              padding: const EdgeInsets.all(15),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Checkbox cho "Everyday"
                    CheckboxListTile(
                      title: Text(
                          AppLocalizations.of(context)?.translate("everyday") ??
                              "Everyday"),
                      value: isEveryday,
                      onChanged: (bool? value) {
                        setState(() {
                          isEveryday = value ?? false;
                          if (isEveryday) {
                            selectedDays.updateAll((key, value) => true);
                          } else {
                            selectedDays.updateAll((key, value) => false);
                          }
                        });
                        _updateRepetition();
                      },
                    ),

                    // Checkbox cho các ngày trong tuần
                    ...daysOfWeek.map((day) {
                      return CheckboxListTile(
                        title: Text(AppLocalizations.of(context)
                                ?.translate(day.toLowerCase()) ??
                            day),
                        value: selectedDays[day],
                        onChanged: (bool? value) {
                          setState(() {
                            selectedDays[day] = value ?? false;

                            // Kiểm tra nếu tất cả các ngày đều được chọn thì chọn "Everyday"
                            if (selectedDays.values
                                .every((isChecked) => isChecked)) {
                              isEveryday = true;
                            } else {
                              isEveryday = false;
                            }
                          });
                          _updateRepetition();
                        },
                      );
                    }),

                    // Nút Lưu
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Text(
                          AppLocalizations.of(context)?.translate("Save") ??
                              "Save"),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _updateRepetition() {
    String repetition;
    if (isEveryday) {
      repetition = "Everyday";
    } else {
      List<String> selectedDaysList = [];
      selectedDays.forEach((key, value) {
        if (value) {
          selectedDaysList.add(key);
        }
      });
      repetition = selectedDaysList.join(",");
    }
    if (repetition == "") {
      repetition = "no";
    }
    // Lưu giá trị vào controller
    widget.repetitionController.text = repetition;
    print("Selected Repetition: $repetition");
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        _showRepetitionSelector(context);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 15),
        decoration: BoxDecoration(
          color: TColor.lightGray,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Icon ở bên trái
            Container(
              width: 30,
              height: 30,
              alignment: Alignment.center,
              child: Image.asset(
                widget.icon,
                width: 16,
                height: 16,
                fit: BoxFit.contain,
              ),
            ),

            const SizedBox(width: 8),

            // Title ở giữa, sử dụng Expanded để chiếm hết không gian còn lại
            Expanded(
              child: Text(
                widget.title,
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ),

            // Icon mũi tên ở bên phải
            InkWell(
              onTap: () {
                _showRepetitionSelector(context);
              },
              child: Container(
                width: 25,
                height: 25,
                alignment: Alignment.center,
                child: Image.asset(
                  "assets/img/p_next.png", // Sử dụng icon "p_next.png" của bạn
                  width: 12,
                  height: 12,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

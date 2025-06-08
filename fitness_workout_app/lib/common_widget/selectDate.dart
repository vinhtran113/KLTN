import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class DatePickerHelper {
  // Hàm để hiển thị DatePicker
  static Future<void> selectDate(
      BuildContext context, TextEditingController controller) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(), // Ngày mặc định là ngày hiện tại
      firstDate: DateTime(1970), // Giới hạn ngày bắt đầu
      lastDate: DateTime.now(), // Giới hạn ngày kết thúc (ngày hiện tại)
    );
    if (picked != null) {
      // Cập nhật giá trị của TextEditingController với ngày đã chọn
      controller.text = "${picked.day}/${picked.month}/${picked.year}";
    }
  }

  static Future<Timestamp?> selectDate2(
      BuildContext context, TextEditingController controller) async {
    DateTime now = DateTime.now();
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(2000),
      lastDate: now,
    );

    if (picked != null) {
      // Cập nhật giao diện (TextField)
      controller.text = "${picked.day}/${picked.month}/${picked.year}";

      // Trả về Timestamp để lưu trong Firestore
      return Timestamp.fromDate(
        DateTime(picked.year, picked.month, picked.day),
      );
    }

    return null;
  }

  static Future<void> selectDate3(
      BuildContext context, TextEditingController controller) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(), // Ngày mặc định là ngày hiện tại
      firstDate: DateTime.now(), // Giới hạn ngày bắt đầu
      lastDate: DateTime(2050), // Giới hạn ngày kết thúc
    );
    if (picked != null) {
      // Cập nhật giá trị của TextEditingController với ngày đã chọn
      controller.text = "${picked.day}/${picked.month}/${picked.year}";
    }
  }
}

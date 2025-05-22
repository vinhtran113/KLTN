import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class PhotoService {
  static String? validateUserData({
    required String weight,
    required String height,
  }) {
    final parsedWeight = double.tryParse(weight);
    if (parsedWeight == null || parsedWeight <= 30) {
      return "Cân nặng phải là số và lớn hơn 30.";
    }

    final parsedHeight = double.tryParse(height);
    if (parsedHeight == null || parsedHeight <= 50 || parsedHeight >= 300) {
      return "Chiều cao phải là số và lớn hơn 50 và nhỏ hơn 300.";
    }

    return null; // Không có lỗi
  }

  static Future<String> savePhoto({
    required String uid,
    required File imageFile,
    required String weight,
    required String height,
    required String bodyFat,
  }) async {
    // Validate đầu vào
    String? error = validateUserData(weight: weight, height: height);
    if (error != null) return error;

    try {
      // Upload ảnh
      final fileName = "${DateTime.now().millisecondsSinceEpoch}.jpg";
      final ref = FirebaseStorage.instance
          .ref("users/$uid/body_progress/$fileName");
      final uploadTask = await ref.putFile(imageFile);
      final imageUrl = await ref.getDownloadURL();

      // Tạo document Firestore
      final progress = {
        "imageUrl": imageUrl,
        "weight": weight,
        "height": height,
        "bodyFat": bodyFat,
        "date": DateTime.now(),
      };

      await FirebaseFirestore.instance
          .collection("users")
          .doc(uid)
          .collection("body_progress")
          .add(progress);

      await FirebaseFirestore.instance
          .collection("users")
          .doc(uid)
          .update({
        'height': height,
        'weight': weight,
        'body_fat': bodyFat,
      });

      return "success"; // Thành công
    } catch (e) {
      return "Lỗi khi lưu ảnh: $e";
    }
  }

  static Future<String> updatePhotoProgress({
    required String uid,
    required String docId,
    required String imageUrl,
    File? newImageFile,
    required String weight,
    required String height,
    required String bodyFat,
  }) async {
    // Validate dữ liệu
    String? error = validateUserData(weight: weight, height: height);
    if (error != null) return error;

    try {
      String finalImageUrl = imageUrl;

      // Nếu có đổi ảnh, xoá ảnh cũ và upload ảnh mới
      if (newImageFile != null) {
        final oldRef = FirebaseStorage.instance.refFromURL(imageUrl);
        await oldRef.delete();

        final fileName = DateTime.now().millisecondsSinceEpoch.toString();
        final newRef = FirebaseStorage.instance
            .ref()
            .child("body_progress/$uid/$fileName.jpg");
        await newRef.putFile(newImageFile);
        finalImageUrl = await newRef.getDownloadURL();
      }

      // Cập nhật Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('body_progress')
          .doc(docId)
          .update({
        'imageUrl': finalImageUrl,
        'weight': weight,
        'height': height,
        'bodyFat': bodyFat,
      });

      // Cập nhật thông tin user nếu muốn
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .update({
        'height': height,
        'weight': weight,
        'body_fat': bodyFat,
      });

      return "success";
    } catch (e) {
      return "Lỗi khi cập nhật: $e";
    }
  }

  static Future<void> deletePhotos({
    required String uid,
    required List<String> docIds,
  }) async {
    final firestore = FirebaseFirestore.instance;
    final storage = FirebaseStorage.instance;

    for (String docId in docIds) {
      final docRef = firestore
          .collection('users')
          .doc(uid)
          .collection('body_progress')
          .doc(docId);

      final docSnap = await docRef.get();
      if (!docSnap.exists) continue;

      final imageUrl = docSnap['imageUrl'];
      // Xoá ảnh khỏi Storage
      try {
        final ref = storage.refFromURL(imageUrl);
        await ref.delete();
      } catch (e) {
        print("Lỗi khi xoá ảnh từ Storage: $e");
      }

      // Xoá document Firestore
      await docRef.delete();
    }
  }

}

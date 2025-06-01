import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:collection/collection.dart';


class PhotoService {
  static String? validateUserData({
    required String weight,
    required String height,
    required String style,
  }) {
    if (style == "") {
      return "Vui lòng chọn kiểu ảnh.";
    }

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
    required BuildContext context,
    required String uid,
    required File imageFile,
    required String weight,
    required String height,
    required String bodyFat,
    required String style,
    required Timestamp date,
  }) async {
    // Validate đầu vào
    String? error = validateUserData(weight: weight, height: height, style: style);
    if (error != null) return error;

    final firestore = FirebaseFirestore.instance;
    final storage = FirebaseStorage.instance;

    final now = date.toDate();
    final dateOnly = DateTime(now.year, now.month, now.day);

    final collectionRef = firestore
        .collection("users")
        .doc(uid)
        .collection("body_progress");

    try {
      // Lấy các ảnh của ngày đó
      final todayPhotosSnapshot = await collectionRef
          .where("dateOnly", isEqualTo: Timestamp.fromDate(dateOnly))
          .get();

      final todayPhotos = todayPhotosSnapshot.docs;

      // Kiểm tra ảnh cùng style trong ngày
      final existingStyleDoc = todayPhotos.firstWhereOrNull(
            (doc) => doc['style'] == style,
      );

      // 1. Nếu có ảnh cùng style thì hỏi có thay thế không
      bool? confirmReplace = true;
      if (existingStyleDoc != null) {
        confirmReplace = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: Text("Replace image"),
            content: Text("You saved the \"$style\" image today. Do you want to replace it with a new image?"),
            actions: [
              TextButton(
                child: Text("Cancel"),
                onPressed: () => Navigator.of(context).pop(false),
              ),
              ElevatedButton(
                child: Text("Replace"),
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ],
          ),
        );

        if (confirmReplace != true) return "Cancel saving photo";
      }

      // 2. Kiểm tra tính nhất quán thông số với các ảnh khác trong ngày (khác style)
      bool needUpdateAll = false;
      for (var doc in todayPhotos) {
        if (doc['style'] != style &&
            (doc['weight'] != weight || doc['height'] != height || doc['bodyFat'] != bodyFat)) {
          final confirmUpdateAll = await showDialog<bool>(
            context: context,
            builder: (_) => AlertDialog(
              title: Text("Different parameters"),
              content: Text("Today's body parameters are different from the saved photo(s). Do you want to update all parameters for today's photos?"),
              actions: [
                TextButton(
                  child: Text("Cancel"),
                  onPressed: () => Navigator.of(context).pop(false),
                ),
                ElevatedButton(
                  child: Text("Yes"),
                  onPressed: () => Navigator.of(context).pop(true),
                ),
              ],
            ),
          );

          if (confirmUpdateAll != true) {
            return "Image not saved due to different parameters";
          } else {
            needUpdateAll = true;
          }
          break;
        }
      }

      // 3. Upload ảnh mới trước
      final fileName = "${DateTime.now().millisecondsSinceEpoch}_$style.jpg";
      final ref = storage.ref("users/$uid/body_progress/$fileName");

      await ref.putFile(imageFile);
      final imageUrl = await ref.getDownloadURL();

      // 4. Nếu có ảnh cũ cùng style và người dùng đồng ý thay thế, xóa ảnh cũ và doc cũ
      if (existingStyleDoc != null && confirmReplace == true) {
        final oldUrl = existingStyleDoc['imageUrl'];
        final oldRef = storage.refFromURL(oldUrl);
        await oldRef.delete();
        await collectionRef.doc(existingStyleDoc.id).delete();
      }

      // 5. Nếu cần cập nhật tất cả ảnh hôm nay về thông số mới, dùng batch update
      if (needUpdateAll) {
        final batch = firestore.batch();
        for (var doc in todayPhotos) {
          batch.update(doc.reference, {
            'weight': weight,
            'height': height,
            'bodyFat': bodyFat,
          });
        }
        await batch.commit();
      }

      // 6. Thêm document mới cho ảnh vừa upload
      final newPhoto = {
        "imageUrl": imageUrl,
        "weight": weight,
        "height": height,
        "bodyFat": bodyFat,
        "style": style,
        "date": date,
        "dateOnly": Timestamp.fromDate(dateOnly),
      };

      await collectionRef.add(newPhoto);

      // 7. Nếu ảnh của ngày hôm nay, cập nhật thông tin user
      final nowDate = DateTime.now();
      final todayDate = DateTime(nowDate.year, nowDate.month, nowDate.day);
      if (dateOnly == todayDate) {
        await firestore.collection('users').doc(uid).update({
          'weight': weight,
          'height': height,
          'body_fat': bodyFat,
        });
      }

      return "success";
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
    required String style,
    required BuildContext context,
    required Timestamp date,
  }) async {
    String? error = validateUserData(weight: weight, height: height, style: style);
    if (error != null) return error;

    final firestore = FirebaseFirestore.instance;
    final storage = FirebaseStorage.instance;

    try {
      final docRef = firestore.collection('users').doc(uid).collection('body_progress').doc(docId);
      final docSnap = await docRef.get();
      if (!docSnap.exists) return "Ảnh không tồn tại để cập nhật";

      final newDate = date.toDate();
      final dateOnly = DateTime(newDate.year, newDate.month, newDate.day);

      final collectionRef = firestore.collection("users").doc(uid).collection("body_progress");

      final todayPhotosSnapshot = await collectionRef.where("dateOnly", isEqualTo: Timestamp.fromDate(dateOnly)).get();
      final todayPhotos = todayPhotosSnapshot.docs;

      // 1. Kiểm tra style mới có bị trùng với ảnh khác không
      final otherDocWithSameStyle = todayPhotos.firstWhereOrNull(
            (doc) => doc.id != docId && doc['style'] == style,
      );

      if (otherDocWithSameStyle != null) {
        final confirmReplace = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: Text("Replace image"),
            content: Text("You already have a \"$style\" photo on this day. Replace it with this one?"),
            actions: [
              TextButton(
                child: Text("Cancel"),
                onPressed: () => Navigator.pop(context, false),
              ),
              ElevatedButton(
                child: Text("Replace"),
                onPressed: () => Navigator.pop(context, true),
              ),
            ],
          ),
        );

        if (confirmReplace != true) return "Cancel updating photo";

        // Upload ảnh mới trước khi xóa ảnh cũ để tránh mất dữ liệu
        String finalImageUrl = imageUrl;
        if (newImageFile != null) {
          final fileName = "${DateTime.now().millisecondsSinceEpoch}_$style.jpg";
          final newRef = storage.ref("users/$uid/body_progress/$fileName.jpg");
          await newRef.putFile(newImageFile);
          finalImageUrl = await newRef.getDownloadURL();

          // Xóa ảnh cũ trùng style
          final oldUrl = otherDocWithSameStyle['imageUrl'];
          final oldRef = storage.refFromURL(oldUrl);
          await oldRef.delete();

          // Xóa document cũ
          await collectionRef.doc(otherDocWithSameStyle.id).delete();

          // Cập nhật document hiện tại với URL mới
          await docRef.update({'imageUrl': finalImageUrl});
        } else {
          // Nếu không có ảnh mới, vẫn xóa ảnh cũ + doc cũ và update ảnh hiện tại
          final oldUrl = otherDocWithSameStyle['imageUrl'];
          final oldRef = storage.refFromURL(oldUrl);
          await oldRef.delete();

          await collectionRef.doc(otherDocWithSameStyle.id).delete();
        }
      } else {
        // Nếu không trùng style và có ảnh mới thì upload ảnh mới
        String finalImageUrl = imageUrl;
        if (newImageFile != null) {
          final fileName = "${DateTime.now().millisecondsSinceEpoch}_$style.jpg";
          final newRef = storage.ref("users/$uid/body_progress/$fileName.jpg");
          await newRef.putFile(newImageFile);
          finalImageUrl = await newRef.getDownloadURL();

          // Cập nhật document ảnh mới
          await docRef.update({'imageUrl': finalImageUrl});
        }
      }

      // 2. Kiểm tra inconsistency thông số với ảnh khác
      final inconsistent = todayPhotos.any((doc) =>
      doc.id != docId &&
          (doc['weight'] != weight || doc['height'] != height || doc['bodyFat'] != bodyFat));

      if (inconsistent) {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text("Update All"),
            content: Text("Today's body parameters are inconsistent. Do you want to update them all?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text("Cancel"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text("Yes"),
              ),
            ],
          ),
        );

        if (confirm == true) {
          // Sử dụng batch để cập nhật nhanh hơn
          final batch = firestore.batch();
          for (var doc in todayPhotos) {
            batch.update(doc.reference, {
              'weight': weight,
              'height': height,
              'bodyFat': bodyFat,
            });
          }
          await batch.commit();
        } else {
          return "Image not saved due to different parameters";
        }
      }

      // 3. Cập nhật các trường còn lại (weight, height, bodyFat, style, date)
      await docRef.update({
        'weight': weight,
        'height': height,
        'bodyFat': bodyFat,
        'style': style,
        'date': date,
        'dateOnly': Timestamp.fromDate(dateOnly),
      });

      // 4. Nếu là ngày hôm nay thì cập nhật thông tin user
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      if (dateOnly == today) {
        await firestore.collection('users').doc(uid).update({
          'weight': weight,
          'height': height,
          'body_fat': bodyFat,
        });
      }

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

    // Lấy list các future để xóa song song, tránh chờ lần lượt
    final futures = <Future>[];

    for (String docId in docIds) {
      futures.add(() async {
        final docRef = firestore.collection('users').doc(uid).collection('body_progress').doc(docId);
        final docSnap = await docRef.get();
        if (!docSnap.exists) return;

        final imageUrl = docSnap['imageUrl'];
        try {
          final ref = storage.refFromURL(imageUrl);
          await ref.delete();
        } catch (e) {
          print("Lỗi khi xoá ảnh từ Storage: $e");
        }

        await docRef.delete();
      }());
    }

    await Future.wait(futures);
  }

  static Future<List<Map<String, dynamic>>> getPhotosByDate({
    required String uid,
    required Timestamp dateOnly,
  }) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('body_progress')
          .where('dateOnly', isEqualTo: dateOnly)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id; // Nếu cần dùng id
        return data;
      }).toList();
    } catch (e) {
      print('Lỗi khi lấy ảnh theo dateOnly: $e');
      return [];
    }
  }

}

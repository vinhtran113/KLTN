import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitness_workout_app/chatbox/models/message.dart';
import 'package:fitness_workout_app/chatbox/services/chat_service.dart';
import 'package:fitness_workout_app/chatbox/services/firestore_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image/image.dart' as img;

class ChatState {
  final List<Message> messages;
  final bool isLoading;
  final TextEditingController inputController;
  final File? selectedImage;

  ChatState({
    required this.messages,
    required this.isLoading,
    required this.inputController,
    this.selectedImage,
  });

  ChatState copyWith({
    List<Message>? messages,
    bool? isLoading,
    TextEditingController? inputController,
    File? selectedImage,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      inputController: inputController ?? this.inputController,
      selectedImage: selectedImage,
    );
  }
}

class ChatController extends StateNotifier<ChatState> {
  final String userId;
  String chatId = '';
  bool _isImagePickerActive = false;

  ChatController({required this.userId})
      : super(ChatState(
          messages: [],
          isLoading: false,
          inputController: TextEditingController(),
        )) {
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    try {
      chatId = await FirestoreService.getOrCreateCurrentChat(userId);
      final messages = await FirestoreService.loadMessages(chatId);
      setMessages(messages);
    } catch (e) {
      print("❌ Error initializing chat: $e");
    }
  }

  void setMessages(List<Message> messages) {
    state = state.copyWith(messages: messages);
  }

  void clearImage() {
    state = state.copyWith(selectedImage: null);
  }

  Future<void> pickImage(ImageSource source) async {
    if (_isImagePickerActive) return;
    _isImagePickerActive = true;

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile != null) {
      state = state.copyWith(selectedImage: File(pickedFile.path));
    }

    _isImagePickerActive = false;
  }

  Future<File> compressImage(File file) async {
    final imageBytes = await file.readAsBytes();
    final image = img.decodeImage(Uint8List.fromList(imageBytes));

    if (image == null) {
      throw Exception("Không thể đọc ảnh");
    }

    final compressedImage = img.encodeJpg(image, quality: 85);
    final compressedFile = File(file.path)..writeAsBytesSync(compressedImage);
    return compressedFile;
  }

  Future<String?> uploadImage(File file) async {
    final compressedFile = await compressImage(file);
    final fileName = DateTime.now().millisecondsSinceEpoch.toString();
    final storageRef =
        FirebaseStorage.instance.ref().child('chat_images/$fileName.jpg');
    await storageRef.putFile(compressedFile);
    return await storageRef.getDownloadURL();
  }

  Future<void> sendChatMessage() async {
    final text = state.inputController.text.trim();
    final File? imageFile = state.selectedImage;

    if (text.isEmpty && imageFile == null) return;

    state = state.copyWith(isLoading: true);
    final DateTime timestamp = DateTime.now();
    String? imageUrl;

    if (imageFile != null) {
      try {
        imageUrl = await uploadImage(imageFile);
      } catch (e) {
        print("❌ Lỗi upload ảnh: $e");
      }
    }

    final userMessage = Message(
      id: UniqueKey().toString(),
      text: text.isNotEmpty ? text : '[Đã gửi ảnh]',
      imageUrl: imageUrl,
      isUser: true,
      timestamp: timestamp,
    );

    try {
      await FirestoreService.saveMessage(chatId, userMessage);
    } catch (e) {
      print("❌ Lỗi lưu message người dùng: $e");
    }

    // 👉 Thêm tin nhắn vào danh sách tạm để lấy lịch sử
    final updatedMessages = [...state.messages, userMessage];
    state = state.copyWith(messages: updatedMessages);

    try {
      final userInfo = await FirestoreService.getUserInfo(userId);
      final extraInfo = await FirestoreService.getUserExtraInfo(
          userId); // Lấy thêm thông tin sức khoẻ

      // 👉 Lấy 3 cặp user-assistant gần nhất
      final history = _buildHistoryMessages(updatedMessages);

      final botResponse = await ChatService.sendMessageToGPT(
        userMessage: text,
        imageUrl: imageUrl,
        gender: userInfo['gender'] ?? '',
        height: userInfo['height'] ?? '',
        weight: userInfo['weight'] ?? '',
        bodyFat: extraInfo['body_fat'] ?? '',
        medicalHistory: extraInfo['medical_history'] ?? [],
        medicalHistoryOther: extraInfo['medical_history_other'] ?? [],
        medicalNote: extraInfo['medical_note'] ?? '',
        historyMessages: history, // 👈 truyền vào GPT
      );

      if (botResponse != null && botResponse.isNotEmpty) {
        final botMessage = Message(
          id: UniqueKey().toString(),
          text: botResponse,
          imageUrl: null,
          isUser: false,
          timestamp: DateTime.now(),
        );

        await FirestoreService.saveMessage(chatId, botMessage);

        state = state.copyWith(
          messages: [...state.messages, botMessage],
        );
      }
    } catch (e) {
      print("❌ Lỗi xử lý GPT hoặc lấy user info: $e");
    } finally {
      state.inputController.clear();
      clearImage();
      state = state.copyWith(isLoading: false);
    }
  }

  List<Message> _buildHistoryMessages(List<Message> fullList) {
    final history = <Message>[];
    int count = 0;

    for (int i = fullList.length - 1; i >= 0 && count < 4; i--) {
      final m = fullList[i];
      if (m.text.isNotEmpty) {
        history.insert(0, m);
        count++;
        print("chat: ${m.text}");
      }
    }

    return history;
  }

  Future<void> deleteChatHistory() async {
    state = state.copyWith(isLoading: true);

    try {
      await FirestoreService.deleteAllMessages(chatId);
      state = state.copyWith(messages: []);
    } catch (e) {
      print("❌ Lỗi khi xoá lịch sử: $e");
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }
}

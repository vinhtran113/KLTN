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
    final storageRef = FirebaseStorage.instance.ref().child('chat_images/$fileName.jpg');
    await storageRef.putFile(compressedFile);
    return await storageRef.getDownloadURL();
  }

  // Thêm phương thức gửi tin nhắn hình ảnh
  Future<void> sendImageMessage(File imageFile) async {
    try {
      final imageUrl = await uploadImage(imageFile);
      if (imageUrl != null) {
        final imageMessage = Message(
          id: UniqueKey().toString(),
          text: '',  // Tin nhắn ảnh sẽ không có nội dung văn bản
          imageUrl: imageUrl,
          isUser: true,
          timestamp: DateTime.now(),
        );

        // Lưu tin nhắn ảnh vào Firestore
        await FirestoreService.saveMessage(chatId, imageMessage);

        // Cập nhật lại state nếu tin nhắn ảnh đã được gửi thành công
        state = state.copyWith(
          messages: List.from(state.messages)..add(imageMessage), // Dùng List.from để tránh thay đổi danh sách trực tiếp
        );
      }
    } catch (e) {
      print("❌ Lỗi upload ảnh: $e");
    } finally {
      // Xóa ảnh đã chọn sau khi gửi
      clearImage();
    }
  }


  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty && state.selectedImage == null) return;

    // Danh sách tin nhắn mới (tạm thời lưu trữ tin nhắn cần thêm vào state)
    final List<Message> newMessages = [];

    // Gửi ảnh nếu có
    if (state.selectedImage != null) {
      try {
        await sendImageMessage(state.selectedImage!);
      } catch (e) {
        print("❌ Lỗi gửi ảnh: $e");
      } finally {
        clearImage();
      }
    }

    // Gửi text nếu có
    if (text.trim().isNotEmpty) {
      final userMessage = Message(
        id: UniqueKey().toString(),
        text: text,
        isUser: true,
        timestamp: DateTime.now(),
      );

      // Lưu tin nhắn người dùng vào Firestore
      try {
        await FirestoreService.saveMessage(chatId, userMessage);
        // Chỉ thêm tin nhắn vào danh sách nếu lưu thành công
        newMessages.add(userMessage);
      } catch (e) {
        print("❌ Lỗi lưu tin nhắn người dùng: $e");
      }
    }

    // Nếu không có tin nhắn nào để gửi, thoát sớm
    if (newMessages.isEmpty) return;

    // Cập nhật state để hiển thị tin nhắn người dùng đã gửi
    state = state.copyWith(
      messages: [...state.messages, ...newMessages],
      isLoading: true,
    );

    // Xử lý phản hồi từ chatbot
    try {
      final lastUserMessage = newMessages.lastWhere(
            (m) => m.text.isNotEmpty,
        orElse: () => Message.empty(),
      );

      if (lastUserMessage.text.isNotEmpty) {
        // Lấy thông tin người dùng (nếu cần)
        final userInfo = await FirestoreService.getUserInfo(userId);

        // Gửi tin nhắn đến GPT và nhận phản hồi
        final botResponse = await ChatService.sendMessageToGPT(
          userMessage: lastUserMessage.text,
          gender: userInfo['gender'] ?? '',
          height: userInfo['height'] ?? '',
          weight: userInfo['weight'] ?? '',
        );

        if (botResponse != null) {
          // Tạo tin nhắn phản hồi từ chatbot
          final botMessage = Message(
            id: UniqueKey().toString(),
            text: botResponse,
            isUser: false,
            timestamp: DateTime.now(),
          );

          // Lưu tin nhắn chatbot vào Firestore
          await FirestoreService.saveMessage(chatId, botMessage);

          // Cập nhật state với tin nhắn phản hồi từ chatbot
          state = state.copyWith(
            messages: [...state.messages, botMessage],
          );
        }
      }
    } catch (e) {
      print("❌ Error sending message: $e");
    } finally {
      // Dọn dẹp input sau khi xử lý xong
      state.inputController.clear();
      state = state.copyWith(isLoading: false);
    }
  }



}


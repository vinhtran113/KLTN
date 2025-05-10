import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fitness_workout_app/chatbox/models/message.dart';

class ChatState {
  final List<Message> messages;
  final TextEditingController inputController;
  final bool isLoading;
  final XFile? pickedImage; // Ảnh được chọn nhưng chưa gửi

  ChatState({
    required this.messages,
    required this.inputController,
    required this.isLoading,
    this.pickedImage,
  });

  ChatState copyWith({
    List<Message>? messages,
    TextEditingController? inputController,
    bool? isLoading,
    XFile? pickedImage,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      inputController: inputController ?? this.inputController,
      isLoading: isLoading ?? this.isLoading,
      pickedImage: pickedImage ?? this.pickedImage,
    );
  }
}

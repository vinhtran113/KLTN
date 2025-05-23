import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fitness_workout_app/chatbox/screens/chat/widgets/chat_input_field.dart';
import 'package:fitness_workout_app/chatbox/screens/chat/widgets/message_list.dart';
import 'package:fitness_workout_app/chatbox/services/firestore_service.dart';
import 'package:fitness_workout_app/chatbox/providers/chat_provider.dart';
import 'package:fitness_workout_app/chatbox/providers/speech_provider.dart';

import '../../../common/colo_extension.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  @override
  void initState() {
    super.initState();
    _loadInitialMessages();
  }

  Future<void> _loadInitialMessages() async {
    String userId = FirebaseAuth.instance.currentUser!.uid;
    final chatId = await FirestoreService.getOrCreateCurrentChat(userId);
    final messages = await FirestoreService.loadMessages(chatId);
    ref.read(chatControllerProvider.notifier).setMessages(messages);
    print('check uid: ${userId}');
  }

  void _handleImagePick(ImageSource source) async {
    print('Picking image from source: $source');
    await ref.read(chatControllerProvider.notifier).pickImage(source);
    final image = ref.read(chatControllerProvider).selectedImage;
    print('Selected image: ${image?.path}'); // In ra đường dẫn của ảnh được chọn
  }

  void _handleSendMessage(String text, File? image) async {
    final controller = ref.read(chatControllerProvider.notifier);

    // Gán text vào inputController
    controller.state.inputController.text = text;

    // Nếu có ảnh, gán ảnh vào state
    if (image != null) {
      controller.state = controller.state.copyWith(selectedImage: image);
      print('Sending image message: ${image.path}');
    }

    print('Sending chat message...');
    await controller.sendChatMessage(); // Gọi hàm đã có sẵn
  }

  void _handleImageClear([File? _]) {
    print('Clearing selected image');
    ref.read(chatControllerProvider.notifier).clearImage();
  }

  void _handleVoiceRecord() async {
    // Lấy state hiện tại
    final speechState = ref.read(speechProvider);

    // Kiểm tra thiết bị có hỗ trợ không
    if (!speechState.isAvailable) {
      print("❌ Micro không khả dụng trên thiết bị này.");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Micro không khả dụng trên thiết bị này.")),
      );
      return;
    }

    final controller = ref.read(chatControllerProvider).inputController;
    final speechNotifier = ref.read(speechProvider.notifier);

    if (speechState.isListening) {
      print("🛑 Dừng voice recognition...");
      await speechNotifier.stopListening();
    } else {
      print("🎙️ Bắt đầu voice recognition...");
      controller.clear();

      await speechNotifier.startListening((recognizedText) {
        controller.text = recognizedText;
        print("✅ Voice recognized: $recognizedText");
      });
    }
  }




  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatControllerProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: TColor.white,
        centerTitle: true,
        elevation: 0,
        leading: InkWell(
          onTap: () {
            Navigator.pop(context);
          },
          child: Container(
            margin: const EdgeInsets.all(8),
            height: 40,
            width: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: TColor.lightGray,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Image.asset(
              "assets/img/black_btn.png",
              width: 15,
              height: 15,
              fit: BoxFit.contain,
            ),
          ),
        ),
        title: Text(
          "Health Bot",
          style: TextStyle(
            color: TColor.black,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.black),
            tooltip: 'Xoá lịch sử',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Xác nhận xoá lịch sử'),
                  content: const Text('Bạn có chắc muốn xoá toàn bộ lịch sử trò chuyện không?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Huỷ'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Xoá'),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                await ref.read(chatControllerProvider.notifier).deleteChatHistory();
              }
            },
          )
        ],
      ),

      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: MessageList(messages: chatState.messages),
            ),
            ChatInputField(
              controller: chatState.inputController,
              selectedImage: chatState.selectedImage, // Giờ lấy trực tiếp từ state
              onSend: _handleSendMessage,
              onImagePick: _handleImagePick,
              onImageClear: _handleImageClear,
              onVoiceRecord: _handleVoiceRecord,
            ),
          ],
        ),
      ),
    );
  }
}
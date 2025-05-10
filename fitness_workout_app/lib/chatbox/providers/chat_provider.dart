import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitness_workout_app/chatbox/screens/chat/controller/chat_controller.dart';



/// Provider quản lý trạng thái Chat thông qua ChatController
final chatControllerProvider = StateNotifierProvider<ChatController, ChatState>(
      (ref) => ChatController(userId: FirebaseAuth.instance.currentUser!.uid),
);
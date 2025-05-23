// lib/chatbox/providers/speech_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitness_workout_app/chatbox/services/speech_service.dart'; // Import SpeechService và SpeechState

// Định nghĩa StateNotifierProvider cho SpeechService
final speechProvider = StateNotifierProvider<SpeechService, SpeechState>(
      (ref) => SpeechService(),
);
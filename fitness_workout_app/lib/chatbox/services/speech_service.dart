import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';

/// State chứa toàn bộ thông tin liên quan đến trạng thái của micro
class SpeechState {
  final bool isListening;
  final bool isAvailable;
  final String recognizedText;
  final String error;

  SpeechState({
    this.isListening = false,
    this.isAvailable = false,
    this.recognizedText = '',
    this.error = '',
  });

  SpeechState copyWith({
    bool? isListening,
    bool? isAvailable,
    String? recognizedText,
    String? error,
  }) {
    return SpeechState(
      isListening: isListening ?? this.isListening,
      isAvailable: isAvailable ?? this.isAvailable,
      recognizedText: recognizedText ?? this.recognizedText,
      error: error ?? this.error,
    );
  }
}

class SpeechService extends StateNotifier<SpeechState> {
  final SpeechToText _speech = SpeechToText();
  StreamController<String> _textStreamController = StreamController.broadcast();

  Stream<String> get textStream => _textStreamController.stream;

  SpeechService() : super(SpeechState()) {
    _init();
  }

  Future<void> _init() async {
    // Xin quyền từ permission_handler
    final micStatus = await Permission.microphone.request();
    if (!micStatus.isGranted) {
      print('❌ Microphone permission denied');
      state = state.copyWith(isAvailable: false);
      return;
    }

    // Kiểm tra lại xem SpeechToText có quyền chưa
    final hasPermission = await _speech.hasPermission;
    if (!hasPermission) {
      print('❌ SpeechToText chưa có quyền truy cập micro.');
      state = state.copyWith(isAvailable: false);
      return;
    }

    // Khởi tạo speech recognition
    final available = await _speech.initialize(
      onStatus: _onStatus,
      onError: _onError,
    );

    print("🎤 Speech to text initialized: $available");

    // In các locale hỗ trợ
    final locales = await _speech.locales();
    for (var locale in locales) {
      print('🌐 Available locale: ${locale.localeId}');
    }

    // Cập nhật state
    state = state.copyWith(isAvailable: available);
  }


  void _onStatus(String status) {
    print('📢 Status: $status');
    if (status == 'listening') {
      state = state.copyWith(isListening: true);
    } else {
      state = state.copyWith(isListening: false);
    }
  }

  void _onError(dynamic error) {
    final errorMsg = error.errorMsg ?? 'Unknown error';
    print('❌ Lỗi: $errorMsg');
    state = state.copyWith(error: errorMsg, isListening: false);
  }

// Khi startListening thì cần truyền locale hợp lệ
  Future<void> startListening(Function(String) onResultCallback) async {
    if (!state.isAvailable) {
      print("⚠️ SpeechService không sẵn sàng.");
      return;
    }

    final locales = await _speech.locales();
    final selectedLocale = locales.firstWhere(
          (locale) => locale.localeId == 'vi_VN',
      orElse: () => locales.first,
    );

    print("📢 Sử dụng localeId: ${selectedLocale.localeId}");

    state = state.copyWith(isListening: true);

    await _speech.listen(
      onResult: (result) {
        final text = result.recognizedWords;
        print("🗣️ Đã nghe: $text");
        onResultCallback(text);
      },
      listenMode: ListenMode.dictation,
      partialResults: true,
      localeId: selectedLocale.localeId,
    );
  }


  Future<void> stopListening() async {
    _speech.stop();
    state = state.copyWith(isListening: false);
  }

  void cancelListening() {
    _speech.cancel();
    state = state.copyWith(isListening: false);
  }

  @override
  void dispose() {
    _textStreamController.close();
    _speech.cancel();
    super.dispose();
  }
}

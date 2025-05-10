import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ChatInputField extends StatefulWidget {
  final TextEditingController controller;
  final Function(String text, File? imageFile) onSend;
  final Function(ImageSource) onImagePick;
  final Function(File?) onImageClear;
  final File? selectedImage;

  const ChatInputField({
    Key? key,
    required this.controller,
    required this.onSend,
    required this.onImagePick,
    required this.onImageClear,
    this.selectedImage,
  }) : super(key: key);

  @override
  State<ChatInputField> createState() => _ChatInputFieldState();
}

class _ChatInputFieldState extends State<ChatInputField> {
  void _send() {
    final text = widget.controller.text.trim();
    final image = widget.selectedImage;

    // Kiểm tra nếu không có text và ảnh thì không gửi
    if (text.isEmpty && image == null) return;

    // Gửi tin nhắn và ảnh (nếu có)
    widget.onSend(text, image);
    widget.controller.clear();  // Xóa nội dung trong TextField
    widget.onImageClear(null);  // Xóa ảnh đã chọn
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF343541),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Column(
        children: [
          // Hiển thị ảnh preview nếu có
          if (widget.selectedImage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Stack(
                alignment: Alignment.topRight,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      widget.selectedImage!,
                      height: 120,
                      fit: BoxFit.cover,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => widget.onImageClear(null),  // Xóa ảnh
                  ),
                ],
              ),
            ),
          Row(
            children: [
              // Nút chọn ảnh từ thư viện
              IconButton(
                icon: const Icon(Icons.photo, color: Colors.white),
                onPressed: () => widget.onImagePick(ImageSource.gallery),
              ),
              // Nút chụp ảnh từ máy ảnh
              IconButton(
                icon: const Icon(Icons.camera_alt, color: Colors.white),
                onPressed: () => widget.onImagePick(ImageSource.camera),
              ),
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: "Send a message...",
                    hintStyle: const TextStyle(color: Colors.white54),
                    filled: true,
                    fillColor: const Color(0xFF40414F),
                    contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onSubmitted: (_) => _send(),  // Gửi tin nhắn khi nhấn Enter
                ),
              ),
              const SizedBox(width: 8),
              // Nút gửi tin nhắn
              IconButton(
                icon: const Icon(Icons.send, color: Colors.white),
                onPressed: _send,  // Gửi tin nhắn khi nhấn nút gửi
              ),
            ],
          ),
        ],
      ),
    );
  }
}

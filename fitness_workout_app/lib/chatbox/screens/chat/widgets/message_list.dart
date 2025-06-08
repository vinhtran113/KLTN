import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:fitness_workout_app/chatbox/models/message.dart';

class MessageList extends StatefulWidget {
  final List<Message> messages;

  const MessageList({super.key, required this.messages});

  @override
  State<MessageList> createState() => _MessageListState();
}

class _MessageListState extends State<MessageList> {
  final ScrollController _scrollController = ScrollController();

  @override
  void didUpdateWidget(MessageList oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.messages.length != oldWidget.messages.length) {
      // Có tin nhắn mới => scroll xuống cuối
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.messages.isEmpty) {
      return const Center(
        child: Text(
          'Chưa có tin nhắn nào.',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      itemCount: widget.messages.length,
      itemBuilder: (context, index) {
        final msg = widget.messages[index];
        final isUser = msg.isUser;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment:
              isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            if (!isUser)
              Padding(
                padding: const EdgeInsets.only(right: 8.0, bottom: 4),
                child: CircleAvatar(
                  backgroundColor: Colors.blueGrey[200],
                  radius: 18,
                  child: Icon(Icons.smart_toy, color: Colors.white),
                ),
              ),
            Flexible(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 6),
                padding: const EdgeInsets.all(14),
                constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.7),
                decoration: BoxDecoration(
                  color: isUser ? const Color(0xFF343541) : Colors.grey[200],
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                    bottomLeft: Radius.circular(isUser ? 16 : 4),
                    bottomRight: Radius.circular(isUser ? 4 : 16),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (msg.imageUrl != null && msg.imageUrl!.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          msg.imageUrl!,
                          fit: BoxFit.cover,
                          width: 220,
                          height: 180,
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return Container(
                              width: 220,
                              height: 180,
                              color: Colors.grey[200],
                              child: const Center(
                                  child: CircularProgressIndicator()),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                            width: 220,
                            height: 180,
                            color: Colors.grey[300],
                            child: const Icon(Icons.broken_image,
                                color: Colors.red),
                          ),
                        ),
                      ),
                    if (msg.text.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: MarkdownBody(
                          data: msg.text,
                          styleSheet:
                              MarkdownStyleSheet.fromTheme(Theme.of(context))
                                  .copyWith(
                            p: TextStyle(
                              color: isUser ? Colors.white : Colors.black87,
                              fontSize: 15,
                            ),
                            code: const TextStyle(
                              backgroundColor: Color(0xFF3C3C3C),
                              color: Colors.greenAccent,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                      ),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Text(
                        _formatTime(msg.timestamp),
                        style: TextStyle(
                          color: isUser ? Colors.white54 : Colors.black38,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (isUser)
              Padding(
                padding: const EdgeInsets.only(left: 8.0, bottom: 4),
                child: CircleAvatar(
                  backgroundColor: Colors.blue[300],
                  radius: 18,
                  child: Icon(Icons.person, color: Colors.white),
                ),
              ),
          ],
        );
      },
    );
  }

  String _formatTime(DateTime? time) {
    if (time == null) return '';
    final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final minute = time.minute.toString().padLeft(2, '0');
    final ampm = time.hour >= 12 ? 'PM' : 'AM';
    final date =
        '${time.day.toString().padLeft(2, '0')}/${time.month.toString().padLeft(2, '0')}/${time.year}';
    return '$hour:$minute $ampm  $date';
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String id;
  final String text;
  final String? imageUrl;
  final bool isUser;
  final DateTime timestamp;

  Message({
    required this.id,
    required this.text,
    this.imageUrl,
    required this.isUser,
    required this.timestamp,
  });

  // Static method to return an empty message
  static Message empty() {
    return Message(
      id: '',
      text: '',
      isUser: false,
      timestamp: DateTime.now(),
    );
  }

  // Create a Message from a Map
  factory Message.fromMap(Map<String, dynamic> map, String docId) {
    return Message(
      id: docId,
      text: map['text'] ?? '',
      imageUrl: map['imageUrl'],
      isUser: map['isUser'] ?? false,
      timestamp: (map['timestamp'] as Timestamp).toDate(),
    );
  }

  // Convert Message to Map
  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'imageUrl': imageUrl,
      'isUser': isUser,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  // Convert Message to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'imageUrl': imageUrl,
      'isUser': isUser,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  // Create a Message from JSON
  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'],
      text: json['text'],
      imageUrl: json['imageUrl'],
      isUser: json['isUser'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}
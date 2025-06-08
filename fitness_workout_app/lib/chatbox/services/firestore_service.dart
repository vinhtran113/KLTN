import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/message.dart';

class FirestoreService {
  static final _firestore = FirebaseFirestore.instance;

  static bool _isCreatingChat = false; // Thêm biến chặn

  static Future<String> getOrCreateCurrentChat(String userId) async {
    // Nếu đang tạo thì chờ 1 chút để tránh đụng nhau
    while (_isCreatingChat) {
      await Future.delayed(Duration(milliseconds: 200));
    }

    _isCreatingChat = true;

    final chatsRef = _firestore.collection('chats');
    final userChat = await chatsRef
        .where('userId', isEqualTo: userId)
        .orderBy('lastUpdated', descending: true)
        .limit(1)
        .get();

    if (userChat.docs.isNotEmpty) {
      _isCreatingChat = false;
      return userChat.docs.first.id;
    }

    // Nếu không có, tạo mới
    final newChat = await chatsRef.add({
      'userId': userId,
      'createdAt': FieldValue.serverTimestamp(),
      'lastUpdated': FieldValue.serverTimestamp(),
    });

    _isCreatingChat = false;
    return newChat.id;
  }

  // Lưu tin nhắn vào Firestore
  static Future<void> saveMessage(String chatId, Message message) async {
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add({
      'id': message.id,
      'text': message.text, // Văn bản của tin nhắn
      'imageUrl': message.imageUrl, // URL ảnh (nếu có)
      'isUser': message.isUser, // Tin nhắn do người dùng gửi hay không
      'timestamp': FieldValue.serverTimestamp(), // Thời gian gửi
    });

    // Cập nhật thời gian 'lastUpdated' cho chat
    await _firestore.collection('chats').doc(chatId).update({
      'lastUpdated': FieldValue.serverTimestamp(),
    });
  }

  // Tải danh sách tin nhắn từ Firestore
  static Future<List<Message>> loadMessages(String chatId) async {
    final snapshot = await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp')
        .get();

    // Chuyển đổi dữ liệu snapshot thành danh sách đối tượng Message
    return snapshot.docs.map((doc) {
      final data = doc.data();
      return Message(
        id: doc.id, // ID của document
        text: data['text'] ?? '', // Văn bản tin nhắn
        imageUrl: data['imageUrl'], // URL ảnh (nếu có)
        isUser: data['isUser'] ?? false, // Xác định tin nhắn của ai
        timestamp: (data['timestamp'] as Timestamp?)?.toDate() ??
            DateTime.now(), // Thời gian
      );
    }).toList();
  }

  // Lấy thông tin người dùng từ Firestore
  static Future<Map<String, String>> getUserInfo(String userId) async {
    final userDoc = await _firestore.collection('users').doc(userId).get();

    if (userDoc.exists) {
      final data = userDoc.data()!;
      return {
        'gender': data['gender'] ?? 'không rõ',
        'height': data['height']?.toString() ?? 'không rõ',
        'weight': data['weight']?.toString() ?? 'không rõ',
      };
    }

    return {
      'gender': 'không rõ',
      'height': 'không rõ',
      'weight': 'không rõ',
    };
  }

  static Future<void> deleteAllMessages(String chatId) async {
    final chatRef = FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages');

    final messages = await chatRef.get();
    for (var doc in messages.docs) {
      await doc.reference.delete();
    }
  }

  static Future<Map<String, dynamic>> getUserExtraInfo(String userId) async {
    final userDoc = await _firestore.collection('users').doc(userId).get();

    if (userDoc.exists) {
      final data = userDoc.data()!;
      return {
        'body_fat': data['body_fat'] ?? '',
        'medical_history': List<String>.from(data['medical_history'] ?? []),
        'medical_history_other':
            List<String>.from(data['medical_history_other'] ?? []),
        'medical_note': data['medical_note'] ?? '',
      };
    }

    return {
      'body_fat': '',
      'medical_history': <String>[],
      'medical_history_other': <String>[],
      'medical_note': '',
    };
  }
}

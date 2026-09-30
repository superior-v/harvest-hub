import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _chatsRef => _firestore.collection('chats');

  /// Generates a deterministic chat ID for a donation + pair of users,
  /// or gets an existing chat document.
  Future<String> getOrCreateChat({
    required String donationId,
    required String donationTitle,
    required String donorId,
    required String donorName,
    required String recipientId,
    required String recipientName,
  }) async {
    // Unique chat id per donation between these 2 users
    final chatId = '${donationId}_${donorId}_$recipientId';
    final chatDoc = _chatsRef.doc(chatId);
    final snapshot = await chatDoc.get();

    if (!snapshot.exists) {
      await chatDoc.set({
        'chatId': chatId,
        'donationId': donationId,
        'donationTitle': donationTitle,
        'donorId': donorId,
        'donorName': donorName,
        'recipientId': recipientId,
        'recipientName': recipientName,
        'participants': [donorId, recipientId],
        'participantNames': {
          donorId: donorName,
          recipientId: recipientName,
        },
        'lastMessage': 'Chat started for $donationTitle',
        'lastMessageAt': FieldValue.serverTimestamp(),
        'lastSenderId': '',
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    return chatId;
  }

  /// Send a text message in the given chat
  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String senderName,
    required String text,
    bool isQuickReply = false,
  }) async {
    if (text.trim().isEmpty) return;

    final trimmed = text.trim();
    final messageDoc = _chatsRef.doc(chatId).collection('messages').doc();

    final batch = _firestore.batch();

    // 1. Add message doc
    batch.set(messageDoc, {
      'messageId': messageDoc.id,
      'chatId': chatId,
      'senderId': senderId,
      'senderName': senderName,
      'text': trimmed,
      'isQuickReply': isQuickReply,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // 2. Update chat metadata
    batch.update(_chatsRef.doc(chatId), {
      'lastMessage': trimmed,
      'lastMessageAt': FieldValue.serverTimestamp(),
      'lastSenderId': senderId,
    });

    await batch.commit();
  }

  /// Stream of messages in a conversation, ordered chronologically
  Stream<QuerySnapshot> getMessagesStream(String chatId) {
    return _chatsRef
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .snapshots();
  }

  /// Stream of all chats the user is participating in
  Stream<QuerySnapshot> getUserChatsStream(String userId) {
    if (userId.isEmpty) {
      return const Stream.empty();
    }
    return _chatsRef
        .where('participants', arrayContains: userId)
        .snapshots();
  }

  /// Launch phone dialer without exposing raw numbers directly in-text
  static Future<bool> launchMaskedCall(String? phoneNumber) async {
    if (phoneNumber == null || phoneNumber.trim().isEmpty) {
      return false;
    }
    final clean = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    final uri = Uri.parse('tel:$clean');
    if (await canLaunchUrl(uri)) {
      return await launchUrl(uri);
    }
    return false;
  }
}

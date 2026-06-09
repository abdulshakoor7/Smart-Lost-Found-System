import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 1. GET CHAT STREAM (Real-time Listener)
  Stream<QuerySnapshot> getMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false) // Oldest at top
        .snapshots();
  }

  // 2. SEND MESSAGE
  Future<void> sendMessage(String chatId, String message) async {
    final String currentUserId = _auth.currentUser!.uid;
    final String userEmail = _auth.currentUser!.email!;
    final Timestamp timestamp = Timestamp.now();

    // Create message object
    Map<String, dynamic> newMessage = {
      'senderId': currentUserId,
      'senderEmail': userEmail,
      'message': message,
      'timestamp': timestamp,
    };

    // Add to database
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add(newMessage);
  }
}
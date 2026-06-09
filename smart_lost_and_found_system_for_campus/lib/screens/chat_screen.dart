import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import '../services/chat_service.dart';
import '../services/api_service.dart';
import '../user_session.dart'; // Ensure UserSession is imported to get the name

class ChatScreen extends StatefulWidget {
  final String chatId; // Unique Room ID (e.g., "room_20")
  final String title;
  final String receiverEmail;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.title,
    required this.receiverEmail
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ChatService _chatService = ChatService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // --- THEME ---
  final Color _bg = const Color(0xFF121212);
  final Color _surface = const Color(0xFF1E1E1E);
  final Color _primaryBlue = const Color(0xFF2563EB);
  final Color _receivedBubble = const Color(0xFF2A2A2A);

  // ✅ FINALIZED SEND MESSAGE LOGIC WITH DJANGO TRIGGER
  void _sendMessage() async {
    String content = _controller.text.trim();
    if (content.isNotEmpty) {
      // Capture the message before clearing the controller
      String messageToSend = content;

      // 1. Send to Firebase (Real-time chat delivery)
      await _chatService.sendMessage(widget.chatId, messageToSend);

      // Clear the controller immediately for a snappy UI feeling
      _controller.clear();

      // 2. TRIGGER BACKEND NOTIFICATION (Django)
      // This creates the record so it appears in the 'Updates' page
      try {
        await http.post(
          Uri.parse("${ApiService.baseUrl}/items/chat_alert/"),
          headers: ApiService.headers,
          body: jsonEncode({
            "receiver_email": widget.receiverEmail,
            "sender_name": UserSession.name, // Professional: Shows actual user name
            "message_text": messageToSend,   // Sends the actual message preview
            "item_id": widget.chatId.split('_').last, // Extracts ID from 'room_20'
          }),
        );
      } catch (e) {
        // Log error to console without interrupting the user's chat session
        debugPrint("❌ Django Notification Error: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(widget.title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          // --- 1. REAL-TIME MESSAGES LIST ---
          Expanded(
            child: StreamBuilder(
              stream: _chatService.getMessages(widget.chatId),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.hasError) return const Center(child: Text("Error loading chats", style: TextStyle(color: Colors.white)));
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

                var docs = snapshot.data!.docs;

                return ListView.builder(
                  reverse: false, // Set to true if your Firebase query is descending
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    Map<String, dynamic> data = docs[index].data() as Map<String, dynamic>;
                    return _buildMessageBubble(data);
                  },
                );
              },
            ),
          ),

          // --- 2. INPUT AREA ---
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(color: _surface, border: Border(top: BorderSide(color: Colors.grey[900]!))),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Type a message...",
                      hintStyle: const TextStyle(color: Colors.grey),
                      filled: true,
                      fillColor: _bg,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                CircleAvatar(
                  backgroundColor: _primaryBlue,
                  radius: 24,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 20),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> data) {
    bool isMe = data['senderId'] == _auth.currentUser!.uid;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isMe ? _primaryBlue : _receivedBubble,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isMe ? const Radius.circular(16) : Radius.zero,
            bottomRight: isMe ? Radius.zero : const Radius.circular(16),
          ),
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(data['message'] ?? "", style: const TextStyle(color: Colors.white, fontSize: 15)),
          ],
        ),
      ),
    );
  }
}
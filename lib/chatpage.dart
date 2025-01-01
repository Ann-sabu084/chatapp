import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatScreen extends StatefulWidget {
  final String username; // Username of the person the current user is chatting with

  ChatScreen({required this.username});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late String _chatDocId;

  // Initialize chatDocId based on current user and selected username
  @override
  void initState() {
    super.initState();
    _chatDocId = _getChatDocId();
  }

  // Create a unique chat document ID based on the user pair
  String _getChatDocId() {
    String currentUserId = FirebaseAuth.instance.currentUser!.uid;
    String otherUserId = widget.username;
    List<String> ids = [currentUserId, otherUserId];
    ids.sort(); // Sorting ensures the chat document is consistent regardless of the order
    return '${ids[0]}_${ids[1]}';
  }

  // Send a message to Firestore
  void sendMessage() {
    String message = _messageController.text.trim();
    if (message.isNotEmpty) {
      _firestore.collection('chats').doc(_chatDocId)
          .collection('messages').add({
        'message': message,
        'sentAt': Timestamp.now(),
        'sender': FirebaseAuth.instance.currentUser!.uid,
      });
      _messageController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat with ${widget.username}'),
      ),
      body: Column(
        children: [
          // Display messages
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('chats').doc(_chatDocId)
                  .collection('messages').orderBy('sentAt')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                var messages = snapshot.data!.docs;
                return ListView.builder(
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    var message = messages[index];
                    bool isSentByCurrentUser =
                        message['sender'] == FirebaseAuth.instance.currentUser!.uid;

                    return ListTile(
                      title: Align(
                        alignment: isSentByCurrentUser
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                          decoration: BoxDecoration(
                            color: isSentByCurrentUser
                                ? Colors.blue[200]
                                : Colors.grey[300],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            message['message'],
                            style: TextStyle(
                              color: isSentByCurrentUser
                                  ? Colors.white
                                  : Colors.black,
                            ),
                          ),
                        ),
                      ),
                      subtitle: Text(
                        message['sentAt'].toDate().toString(),
                        style: TextStyle(fontSize: 12),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          
          // Input field for sending messages
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(hintText: 'Type a message'),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

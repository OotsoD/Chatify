import 'package:cb/firebase_service.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatScreen extends StatefulWidget {
  final String receiverUID;
  final String userName;

  ChatScreen({required this.receiverUID, required this.userName});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class ChatBubble extends StatelessWidget {
  final String message;
  final bool sent;
  final VoidCallback onLongPress;

  ChatBubble({required this.message, required this.sent, required this.onLongPress});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: onLongPress,
      child: Align(
        alignment: sent ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: EdgeInsets.all(8.0),
          padding: EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            color: sent ? Colors.blue[900] : Colors.blueGrey,
            borderRadius: BorderRadius.circular(12.0),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withOpacity(0.5),
                spreadRadius: 1,
                blurRadius: 2,
              )
            ],
          ),
          child: Text(
            message,
            style: TextStyle(
              color: Colors.black,
              fontSize: 16.0,
            ),
          ),
        ),
      ),
    );
  }
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController(); // Controller init
  final User? user = FirebaseAuth.instance.currentUser;
  final FirebaseService _firebaseService = FirebaseService();

  Stream<QuerySnapshot> _messageStream() {
    final senderUID = user?.uid;
    final chatDocID = senderUID!.compareTo(widget.receiverUID) > 0 
      ? '$senderUID\_${widget.receiverUID}'
      : '${widget.receiverUID}_$senderUID';

    print("Listening to chatDocID: $chatDocID");

    return FirebaseFirestore.instance
      .collection('chats')
      .doc(chatDocID)
      .collection('messages')
      .orderBy('timestamp', descending: true)
      .snapshots();
  }

  void _sendMessage() async {
    if (_controller.text.isNotEmpty) {
      final messageContent = _controller.text;
      _controller.clear();
      await _firebaseService.sendMessage(messageContent, widget.receiverUID);
    }
  }

  void _updateMessage(String messageId, String newContent) async {
    final senderUID = user?.uid;
    final chatDocID = senderUID!.compareTo(widget.receiverUID) > 0 
      ? '$senderUID\_${widget.receiverUID}'
      : '${widget.receiverUID}_$senderUID';
    
    await FirebaseFirestore.instance
      .collection('chats')
      .doc(chatDocID)
      .collection('messages')
      .doc(messageId)
      .update({'messageContent': newContent});
  }

  void _deleteMessage(String messageId) async {
    final senderUID = user?.uid;
    final chatDocID = senderUID!.compareTo(widget.receiverUID) > 0 
      ? '$senderUID\_${widget.receiverUID}'
      : '${widget.receiverUID}_$senderUID';
    
    await FirebaseFirestore.instance
      .collection('chats')
      .doc(chatDocID)
      .collection('messages')
      .doc(messageId)
      .delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.userName, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white70)),
        backgroundColor: const Color.fromARGB(255, 4, 55, 78),
        elevation: 20.0,
        shadowColor: Colors.black,
        
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _messageStream(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data!.docs;

                print("Fetched Messages: $messages");

                if (messages.isEmpty) {
                  return Center(child: Text("No messages yet"));
                }

                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    return ChatBubble(
                      message: message['messageContent'],
                      sent: message['senderUID'] == user?.uid,
                      onLongPress: () {
                        if (message['senderUID'] == user?.uid) {
                          showDialog(
                            context: context,
                            builder: (context) {
                              final TextEditingController _editController = TextEditingController();
                              _editController.text = message['messageContent'];
                              return AlertDialog(
                                title: Text('Edit Message'),
                                content: TextField(
                                  controller: _editController,
                                  decoration: InputDecoration(hintText: 'Edit your message'),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                      _updateMessage(message.id, _editController.text);
                                    },
                                    child: Text('Update'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                    child: Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                      _deleteMessage(message.id);
                                    },
                                    child: Text('Delete'),
                                    style: TextButton.styleFrom(iconColor:  Colors.red),
                                  ),
                                ],
                              );
                            },
                          );
                        }
                      },
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: EdgeInsets.all(10.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Type a message',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        vertical: 10.0,
                        horizontal: 20.0,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send, color: Colors.blue[900]),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
      backgroundColor: const Color.fromARGB(255, 4, 55, 78),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();

  void _sendMessage() {
    if (_messageController.text.isNotEmpty) {
      FirebaseFirestore.instance.collection('messages').add({
        'text': _messageController.text,
        'createdAt': Timestamp.now(),
        'userId': FirebaseAuth.instance.currentUser?.uid,
      });
      _messageController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat Room'),
        backgroundColor: Colors.blueGrey,
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection('messages')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (ctx, AsyncSnapshot<QuerySnapshot> chatSnapshot) {
                if (chatSnapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                final chatDocs = chatSnapshot.data!.docs;
                return ListView.builder(
                  reverse: true,
                  itemCount: chatDocs.length,
                  itemBuilder: (ctx, index) {
                    var isMe = chatDocs[index]['userId'] == FirebaseAuth.instance.currentUser?.uid;
                    return ListTile(
                      leading: isMe ? null : CircleAvatar(child: Icon(Icons.person)),
                      title: Container(
                        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                        margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.grey[300] : Colors.blue[400],
                          borderRadius: isMe
                              ? BorderRadius.only(
                            topLeft: Radius.circular(12),
                            topRight: Radius.circular(12),
                            bottomLeft: Radius.circular(12),
                          )
                              : BorderRadius.only(
                            topLeft: Radius.circular(12),
                            topRight: Radius.circular(12),
                            bottomRight: Radius.circular(12),
                          ),
                        ),
                        child: Text(
                          chatDocs[index]['text'],
                          style: TextStyle(color: isMe ? Colors.black : Colors.white),
                        ),
                      ),
                      trailing: isMe ? CircleAvatar(child: Icon(Icons.person)) : null,
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      labelText: 'Send a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.send, color: Colors.blueGrey),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

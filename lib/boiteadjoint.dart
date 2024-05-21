import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // For date formatting

class AdjointBoite extends StatefulWidget {
  AdjointBoite({Key? key, this.title = "Adjoint Boite"}) : super(key: key);

  final String title;

  @override
  _AdjointBoiteState createState() => _AdjointBoiteState();
}

class _AdjointBoiteState extends State<AdjointBoite> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? _selectedUserId;
  String? _selectedUserName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
        automaticallyImplyLeading: false, // Disables the back arrow
        title: Text(
        'Chat avec Enseignants',
        style: TextStyle(
          color: Colors.blueGrey,
        fontWeight: FontWeight.bold, // Adds boldness to the title for emphasis
        fontSize: 20, // Increases the font size
    ),
    ),
    // Sets a deep blue-grey as the background color
    elevation: 2,),
      body: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Row(
          children: [
            Expanded(
              flex: 1,
              child: usersListWidget(),
            ),
            Expanded(
              flex: 2,
              child: _selectedUserId == null
                  ? Center(
                      child: Text(
                          'Sélectionnez un enseignant pour commencer à discuter'))
                  : ChatPage(
                      userId: _selectedUserId!, userName: _selectedUserName!),
            ),
          ],
        ),
      ),
    );
  }

  Widget usersListWidget() {
    return StreamBuilder(
      stream: _firestore.collection('users').snapshots(),
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (!snapshot.hasData)
          return Center(child: CircularProgressIndicator());
        var users = snapshot.data!.docs;
        if (users.isEmpty)
          return Center(child: Text("Aucun utilisateur disponible."));

        return ListView.separated(
          itemCount: users.length,
          separatorBuilder: (context, index) =>
              Divider(height: 2), // Add a divider between each item
          itemBuilder: (context, index) {
            var user = users[index];
            return Card(
              // Wrap each user tile in a Card widget for nicer styling
              elevation: 2, // Optional: adds shadow under the card
              margin: EdgeInsets.symmetric(
                  horizontal: 10, vertical: 15), // Add margin around each card
              child: userTile(
                  user), // Assuming userTile is a widget function that builds the content for each user
            );
          },
        );
      },
    );
  }

  Widget userTile(QueryDocumentSnapshot user) {
    return StreamBuilder(
      stream: _firestore
          .collection('messagesadjointprof')
          .doc('chats')
          .collection('adjoint${user['uid']}')
          .where('read', isEqualTo: false)
          .snapshots(),
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        int unreadCount = snapshot.hasData ? snapshot.data!.docs.length : 0;

        return ListTile(
          leading: Icon(Icons.person),
          title: Text(user['displayName']),
          subtitle: Text(user['grade']),
          trailing: unreadCount > 0
              ? CircleAvatar(
                  radius: 10,
                  backgroundColor: Colors.red,
                  child: Text(unreadCount.toString(),
                      style: TextStyle(color: Colors.white, fontSize: 10)),
                )
              : SizedBox.shrink(),
          onTap: () {
            setState(() {
              _selectedUserId = user['uid'];
              _selectedUserName = user['displayName'];
            });
          },
        );
      },
    );
  }
}

class ChatPage extends StatefulWidget {
  final String userId;
  final String userName;

  ChatPage({required this.userId, required this.userName});

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void _sendMessage() {
    if (_messageController.text.isNotEmpty) {
      _firestore
          .collection('messagesadjointprof')
          .doc('chats')
          .collection('adjoint${widget.userId}')
          .add({
        'senderId': 'adjoint',
        'receiverId': widget.userId,
        'timestamp': FieldValue.serverTimestamp(),
        'content': _messageController.text,
        'read': false,
      });
      _markMessagesAsRead();
      _messageController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Column(
        children: [
          Expanded(child: messagesListWidget()),
          messageInputWidget(),
        ],
      ),
    );
  }

  Widget messagesListWidget() {
    return StreamBuilder(
      stream: _firestore
          .collection('messagesadjointprof')
          .doc('chats')
          .collection('adjoint${widget.userId}')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (!snapshot.hasData)
          return Center(child: CircularProgressIndicator());

        var messages = snapshot.data!.docs;
        if (messages.isEmpty) return Center(child: Text("Pas de messages."));

        return ListView.builder(
          reverse: true,
          itemCount: messages.length,
          itemBuilder: (context, index) {
            var message = messages[index];
            return messageBubble(message);
          },
        );
      },
    );
  }

  Widget messageBubble(QueryDocumentSnapshot message) {
    bool isSentByCurrentUser = message['senderId'] == 'adjoint';
    var alignment =
        isSentByCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    var color = isSentByCurrentUser ? Colors.blue[300] : Colors.grey[300];

    return Container(
      margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Column(
        crossAxisAlignment: alignment,
        children: [
          Container(
            padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: color,
            ),
            child: Text(message['content']),
          ),
          SizedBox(height: 4),
          Text(
            DateFormat('HH:mm:ss')
                .format((message['timestamp'] as Timestamp).toDate()),
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget messageInputWidget() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: "Entrez votre message...",
                border: InputBorder.none,
                filled: true,
                fillColor: Colors.white,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.send, color: Theme.of(context).primaryColor),
            onPressed: _sendMessage,
          ),
        ],
      ),
    );
  }



  void _markMessagesAsRead() {
    if (widget.userId != null) {
      _firestore
          .collection('messagesadjointprof')
          .doc('chats')
          .collection('adjoint${widget.userId}')
          .where('read', isEqualTo: false)
          .get()
          .then((snapshot) {
        for (var doc in snapshot.docs) {
          doc.reference.update({'read': true});
        }
      });
    }
  }


}

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_2/chatpage.dart';
import 'package:flutter_application_2/login.dart';


class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get the list of usernames excluding the current logged-in user
  Future<List<String>> _getUsernames() async {
    User? currentUser = _auth.currentUser;
    if (currentUser == null) return [];

    // Query all users except the current user
    QuerySnapshot snapshot = await _firestore.collection('users').get();
    List<String> usernames = [];
    for (var doc in snapshot.docs) {
      if (doc.id != currentUser.uid) {
        usernames.add(doc.id);  // User ID is used as username
      }
    }
    return usernames;
  }

  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat Home'),
        actions: [
          IconButton(
            icon: Icon(Icons.exit_to_app),
            onPressed: logout,
          ),
        ],
      ),
      body: FutureBuilder<List<String>>(
        future: _getUsernames(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No users found.'));
          }

          // Display the list of users
          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              String username = snapshot.data![index];
              return ListTile(
                title: Text(username),
                onTap: () {
                  // Navigate to the chat screen with the selected user
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatScreen(username: username),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

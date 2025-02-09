import 'package:flutter/material.dart';
import 'package:cb/firebase_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cb/pages/chatscreen.dart';

class UserListScreen extends StatefulWidget {
  @override
  _UserListScreenState createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _filteredUsers = [];
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
    _searchController.addListener(_filterUsers);
  }

  void _fetchUsers() async {
    try {
      print('Fetching users...');
      final QuerySnapshot result = await FirebaseFirestore.instance.collection('users').get();
      final List<DocumentSnapshot> documents = result.docs;

      setState(() {
        _users = documents.map((doc) => {
          ...doc.data() as Map<String, dynamic>,
          'uid': doc.id // Add the document ID as a new key-value pair
        }).toList();
        _filteredUsers = _users;
        _isLoading = false;
      });
      print('Users fetched: ${_users.length}');
    } catch (e) {
      print('Error fetching users: $e');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed To Load Users'),
        backgroundColor: Colors.red,
      ));
    }
  }

  void _logout() async {
    await _firebaseService.signOut();
    Navigator.pushReplacementNamed(context, 'signin');
  }

  void _filterUsers() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredUsers = _users.where((user) {
        return user['name']!.toLowerCase().contains(query) ||
            user['email']!.toLowerCase().contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('User List'),
        backgroundColor: const Color.fromARGB(255, 4, 55, 78),
        actions: [
          IconButton(icon: Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: EdgeInsets.all(8.0),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search By Name or Email',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        vertical: 8.0,
                        horizontal: 16.0,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _filteredUsers.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(_filteredUsers[index]['name']!),
                        subtitle: Text(_filteredUsers[index]['email']!),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatScreen(
                                userName: _filteredUsers[index]['name']!,
                                receiverUID: _filteredUsers[index]['uid'],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

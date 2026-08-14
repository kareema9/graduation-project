import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ShowUserPage extends StatefulWidget {
  const ShowUserPage({super.key});

  @override
  State<ShowUserPage> createState() => _ShowUserPageState();
}

class _ShowUserPageState extends State<ShowUserPage> {
  final CollectionReference usersCollection =
      FirebaseFirestore.instance.collection('users');

  String searchQuery = ""; // search text

  //function to update status
  Future<void> _updateStatus(String userId, int newStatus) async {
    try {
      await usersCollection.doc(userId).update({'status': newStatus});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Status updated to $newStatus')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating status: $e')),
      );
    }
  }

  // مربع حوار لتغيير الحالة باستخدام Dropdown
  void _showEditDialog(String userId, int currentStatus) {
    int selectedStatus = currentStatus;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Status'),
        content: StatefulBuilder(
          builder: (context, setStateDialog) => DropdownButton<int>(
            value: selectedStatus,
            items: const [
              DropdownMenuItem(value: 0, child: Text('Inactive')),
              DropdownMenuItem(value: 1, child: Text('Active')),
            ],
            onChanged: (value) {
              if (value != null) {
                setStateDialog(() {
                  selectedStatus = value;
                });
              }
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',style: TextStyle(color: Colors.black),),
          ),
          ElevatedButton(
            onPressed: () {
              _updateStatus(userId, selectedStatus);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1C621B),
            ),
            child: const Text('Save',style: TextStyle(color: Colors.white,)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1C621B),
        title: TextField(
          onChanged: (value) {
            setState(() {
              searchQuery = value.trim().toLowerCase();
            });
          },
          decoration: const InputDecoration(
            hintText: ' Search by name...',
            hintStyle: TextStyle(color: Colors.white70),
            border: InputBorder.none,
          ),
          style: const TextStyle(color: Colors.white, fontSize: 18),
          cursorColor: Colors.white,
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: usersCollection.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final users = snapshot.data?.docs ?? [];

          // filter by name
          final filteredUsers = users.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final name = (data['name'] ?? '').toString().toLowerCase();
            return name.contains(searchQuery);
          }).toList();

          if (filteredUsers.isEmpty) {
            return const Center(child: Text('No users found'));
          }

          return ListView.builder(
            itemCount: filteredUsers.length,
            itemBuilder: (context, index) {
              final userDoc = filteredUsers[index];
              final data = userDoc.data() as Map<String, dynamic>;

              final name = (data['name'] ?? 'No name').toString();
              final email = (data['email'] ?? 'No email').toString();
              final status = data['status'] is int ? data['status'] : 0;

              return Card(
                margin:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFF1C621B),
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Email: $email'),
                      Text('Status: $status'),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit, color: Color(0xFF1C621B)),
                    onPressed: () => _showEditDialog(userDoc.id, status),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'staff_creation_page.dart';

class StaffListPage extends StatefulWidget {
  const StaffListPage({super.key});

  @override
  State<StaffListPage> createState() => _StaffListPageState();
}

class _StaffListPageState extends State<StaffListPage> {
  final String _sortField = 'timestamp';
  final bool _sortDescending = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5EAFE),

      appBar: AppBar(
        backgroundColor: const Color(0xFF4B0082),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Staff Directory",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF4B0082),
        foregroundColor: Colors.white,
        onPressed: () async {
          final result = await Navigator.pushNamed(context, '/create');
          if (result == 'created' || result == 'updated') {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Staff ${result == 'created' ? 'added' : 'updated'} successfully'),
                backgroundColor: const Color(0xFF4B0082),
              ),
            );
          }
        },
        child: const Icon(Icons.add),
      ),

      body: Column(
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.25,
            width: double.infinity,
            child: Image.asset(
              'assets/images/header.jpg',
              fit: BoxFit.cover,
            ),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestoreStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error: ${snapshot.error}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.group_off,
                            size: 80,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'No staff records found',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF4B0082),
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Start by adding your first staff member',
                            style: TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4B0082),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 12, horizontal: 24),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              textStyle: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            onPressed: () async {
                              final result = await Navigator.pushNamed(context, '/create');
                              if (result == 'created') {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Staff added successfully'),
                                    backgroundColor: Color(0xFF4B0082),
                                  ),
                                );
                              }
                            },
                            child: const Text('Add First Staff'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final doc = snapshot.data!.docs[index];
                    final staff = doc.data() as Map<String, dynamic>;
                    return _buildStaffItem(context, staff, doc.id);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Stream<QuerySnapshot> _firestoreStream() {
    return FirebaseFirestore.instance
        .collection('staff')
        .orderBy(_sortField, descending: _sortDescending)
        .snapshots();
  }

  Widget _buildStaffItem(
      BuildContext context, Map<String, dynamic> staff, String docId) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFF4B0082), width: 1.5),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: const CircleAvatar(
          backgroundColor: Color(0xFF4B0082),
          child: Icon(Icons.person, color: Colors.white),
        ),
        title: Text(
          staff['name'],
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Color(0xFF4B0082),
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('ID: ${staff['id']}'),
              Text('Age: ${staff['age']}'),
            ],
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: () async {
                final result = await Navigator.pushNamed(
                  context,
                  '/create',
                  arguments: {'id': docId, ...staff},
                );
                if (result == 'updated') {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Staff updated successfully'),
                      backgroundColor: Color(0xFF4B0082),
                    ),
                  );
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _confirmDelete(context, docId),
            ),
          ],
        ),
        onTap: () async {
          final result = await Navigator.pushNamed(
            context,
            '/create',
            arguments: {'id': docId, ...staff},
          );
          if (result == 'updated') {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Staff updated successfully'),
                backgroundColor: Color(0xFF4B0082),
              ),
            );
          }
        },
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, String docId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Delete this staff member permanently?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await FirebaseFirestore.instance
            .collection('staff')
            .doc(docId)
            .delete();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Staff deleted successfully'),
            backgroundColor: Color(0xFF4B0082),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Delete failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
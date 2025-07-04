import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StaffCreationPage extends StatefulWidget {
  final Map<String, dynamic>? staffData;

  const StaffCreationPage({super.key, this.staffData});

  @override
  State<StaffCreationPage> createState() => _StaffCreationPageState();
}

class _StaffCreationPageState extends State<StaffCreationPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isEditing = false;
  String? _originalId;
  String _statusMessage = '';

  @override
  void initState() {
    super.initState();
    _isEditing = widget.staffData != null;
    if (_isEditing) {
      _nameController.text = widget.staffData!['name'];
      _idController.text = widget.staffData!['id'];
      _ageController.text = widget.staffData!['age'].toString();
      _originalId = widget.staffData!['id'];
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _idController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _submitStaff() async {
    if (_formKey.currentState!.validate()) {
      try {
        final staffData = {
          'name': _nameController.text.trim(),
          'id': _idController.text.trim(),
          'age': int.parse(_ageController.text),
          'timestamp': FieldValue.serverTimestamp(),
        };

        if (!_isEditing) {
          await _firestore.collection('staff').doc(_idController.text.trim()).set(staffData);
          setState(() => _statusMessage = 'Staff added successfully');
        } else {
          if (_idController.text.trim() != _originalId) {
            await _firestore.collection('staff').doc(_idController.text.trim()).set(staffData);
            await _firestore.collection('staff').doc(_originalId).delete();
          } else {
            await _firestore.collection('staff').doc(_originalId).update(staffData);
          }
          setState(() => _statusMessage = 'Staff updated successfully');
        }
      } catch (e) {
        setState(() => _statusMessage = 'Error: ${e.toString()}');
      }
    }
  }

  Future<void> _deleteStaff() async {
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
        await _firestore.collection('staff').doc(_originalId).delete();
        if (!mounted) return;
        Navigator.pop(context);
      } catch (e) {
        setState(() => _statusMessage = 'Delete failed: ${e.toString()}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5EAFE),
      appBar: AppBar(
        backgroundColor: const Color(0xFF4B0082),
        elevation: 0,
        title: const Text(
          'Staff Form',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deleteStaff,
              color: Colors.redAccent,
            ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.25,
            width: double.infinity,
            child: Image.asset('assets/images/header.jpg', fit: BoxFit.cover),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter staff name';
                        }
                        if (value.length < 3) {
                          return 'Name must be at least 3 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _idController,
                      decoration: const InputDecoration(
                        labelText: 'Staff ID',
                        prefixIcon: Icon(Icons.badge),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter staff ID';
                        }
                        final regex = RegExp(r'^MF-\d{4}$');
                        if (!regex.hasMatch(value)) {
                          return 'ID must start with "MF-" followed by 4 digits (e.g. MF-1234)';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _ageController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Age',
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter age';
                        }
                        final age = int.tryParse(value);
                        if (age == null) {
                          return 'Enter a valid number';
                        }
                        if (age < 18 || age > 65) {
                          return 'Age must be between 18 and 65';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4B0082),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      onPressed: _submitStaff,
                      child: Text(_isEditing ? 'UPDATE STAFF' : 'ADD STAFF'),
                    ),
                    if (_statusMessage.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Text(
                        _statusMessage,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _statusMessage.contains('successfully') ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ]
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

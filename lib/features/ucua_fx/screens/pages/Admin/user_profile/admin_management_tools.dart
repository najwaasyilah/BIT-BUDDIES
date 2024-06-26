import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminUserManagementScreen extends StatefulWidget {
  const AdminUserManagementScreen({super.key});

  @override
  _AdminUserManagementScreenState createState() =>
      _AdminUserManagementScreenState();
}

class _AdminUserManagementScreenState extends State<AdminUserManagementScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Color mainColor = const Color.fromARGB(255, 33, 82, 243);

  void _addUser(Map<String, dynamic> user, String password) async {
    try {
      await _auth
          .createUserWithEmailAndPassword(
        email: user['email'],
        password: password,
      )
          .then((userCredential) {
        user['uid'] = userCredential.user!.uid;
        _firestore.collection('users').doc(userCredential.user!.uid).set(user);
        userCredential.user!.sendEmailVerification();
        _auth.signOut();
        _auth.signInWithEmailAndPassword(
          email: 'admin@example.com',
          password: 'adminpassword',
        );
      });
    } catch (e) {
      print("Error adding user: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding user: $e')),
      );
    }
  }

  void _updateUser(String userId, Map<String, dynamic> user) async {
    try {
      DocumentSnapshot docSnapshot =
          await _firestore.collection('users').doc(userId).get();
      if (docSnapshot.exists) {
        Map<String, dynamic> currentUserData =
            docSnapshot.data() as Map<String, dynamic>;
        if (user['email'] != currentUserData['email']) {
          User? userAuth = _auth.currentUser;
          if (userAuth != null) {
            await _verifyBeforeUpdateEmail(userAuth, user['email']);
          }
        }
      }
      _firestore.collection('users').doc(userId).update(user);
    } catch (e) {
      print("Error updating user: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating user: $e')),
      );
    }
  }

  void _deleteUser(String userId) {
    _firestore.collection('users').doc(userId).delete();
  }

  Future<void> _sendEmailVerification(User user) async {
    try {
      await user.sendEmailVerification();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email verification sent!')),
      );
    } catch (e) {
      print("Error sending email verification: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending email verification: $e')),
      );
    }
  }

  Future<void> _verifyBeforeUpdateEmail(User user, String newEmail) async {
    try {
      await user.verifyBeforeUpdateEmail(newEmail);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Verification email sent for email update!')),
      );
    } catch (e) {
      print("Error verifying email before update: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error verifying email before update: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text(
              'Manage Users',
              style: TextStyle(color: Colors.white),
            ),
            const Spacer(),
            Image.asset(
              'assets/manage.png',
              color: Colors.white,
              scale: 11,
            ),
          ],
        ),
        backgroundColor: mainColor,
      ),
      body: StreamBuilder(
        stream: _firestore.collection('users').snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              DocumentSnapshot doc = snapshot.data!.docs[index];
              Map<String, dynamic> user = doc.data() as Map<String, dynamic>;
              String firstName = user['firstName'] ?? 'No Name';
              String lastName = user['lastName'] ?? 'No Last Name';
              String staffID = user['staffID'] ?? 'No ID';
              String email = user['email'] ?? 'No Email';
              String role = user['role'] ?? 'No Role';
              String phone = user['phone'] ?? 'No Phone';
              String? profileImageUrl = user['profileImageUrl'];

              return Card(
                color: Colors.cyan,
                margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                child: ListTile(
                  leading: CircleAvatar(
                    radius: 30,
                    backgroundImage: profileImageUrl != null
                        ? NetworkImage(profileImageUrl)
                        : const AssetImage('assets/default_profile_picture.png')
                            as ImageProvider,
                  ),
                  title: Text(
                    '$firstName $lastName',
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Staff ID: $staffID',
                        style: const TextStyle(color: Colors.white),
                      ),
                      Text(
                        'Email: $email',
                        style: const TextStyle(color: Colors.white),
                      ),
                      Text(
                        'Phone: $phone',
                        style: const TextStyle(color: Colors.white),
                      ),
                      Text(
                        'Role: $role',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Color.fromARGB(255, 146, 8, 144)),
                        onPressed: () {
                          _showUserForm(context, userId: doc.id, user: user);
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.remove_circle, color: Colors.red.shade800),
                        onPressed: () {
                          _deleteUser(doc.id);
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showUserForm(context);
        },
        backgroundColor: mainColor,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showUserForm(BuildContext context,
      {String? userId, Map<String, dynamic>? user}) {
    final formKey = GlobalKey<FormState>();
    final TextEditingController nameController =
        TextEditingController(text: user?['firstName']);
    final TextEditingController lastNameController =
        TextEditingController(text: user?['lastName']);
    final TextEditingController emailController =
        TextEditingController(text: user?['email']);
    final TextEditingController roleController =
        TextEditingController(text: user?['role']);
    final TextEditingController staffIDController =
        TextEditingController(text: user?['staffID']);
    final TextEditingController phoneController =
        TextEditingController(text: user?['phone']);
    final TextEditingController profileImageUrlController =
        TextEditingController(text: user?['profileImageUrl']);
    final TextEditingController passwordController = TextEditingController();

    showDialog(
      barrierColor: Colors.blue,
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(user == null ? 'Add User' : 'Edit User'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'First Name'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a first name';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: lastNameController,
                    decoration: const InputDecoration(labelText: 'Last Name'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a last name';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: emailController,
                    decoration: const InputDecoration(labelText: 'Email'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter an email';
                      }
                      return null;
                    },
                  ),
                  if (user == null)
                    TextFormField(
                      controller: passwordController,
                      decoration: const InputDecoration(labelText: 'Password'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a password';
                        }
                        return null;
                      },
                    ),
                  TextFormField(
                    controller: roleController,
                    decoration: const InputDecoration(labelText: 'Role'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a role';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: staffIDController,
                    decoration: const InputDecoration(labelText: 'Staff ID'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a staff ID';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: phoneController,
                    decoration: const InputDecoration(labelText: 'Phone'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a phone number';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: profileImageUrlController,
                    decoration:
                        const InputDecoration(labelText: 'Profile Image URL'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Map<String, dynamic> newUser = {
                    'firstName': nameController.text,
                    'lastName': lastNameController.text,
                    'email': emailController.text,
                    'role': roleController.text,
                    'staffID': staffIDController.text,
                    'phone': phoneController.text,
                    'profileImageUrl': profileImageUrlController.text,
                  };
                  if (userId == null) {
                    _addUser(newUser, passwordController.text);
                  } else {
                    _updateUser(userId, newUser);
                  }
                  Navigator.of(context).pop();
                }
              },
              child: Text('Save', style: TextStyle(color: mainColor)),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel', style: TextStyle(color: mainColor)),
            ),
          ],
        );
      },
    );
  }
}

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:ucua_staging/features/ucua_fx/screens/pages/SafetyDept/navbar.dart';

class SafetyDeptHomePage extends StatefulWidget {
  const SafetyDeptHomePage({super.key});

  @override
  State<SafetyDeptHomePage> createState() => _SafetyDeptHomePageState();
}

class _SafetyDeptHomePageState extends State<SafetyDeptHomePage> {
  String accountName = 'Default Name';
  String accountEmail = 'default@example.com';

  @override
  void initState() {
    super.initState();
    _initializeUserDetails();
  }

  void _initializeUserDetails() {
    final user = FirebaseAuth.instance.currentUser;
    setState(() {
      accountName = user?.displayName ?? 'Default Name';
      accountEmail = user?.email ?? 'default@example.com';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: NavBar(
        accountName: accountName,
        accountEmail: accountEmail,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            color: Colors.blue,
            child: const Text(
              "Welcome to Safety Department Homepage",
              style: TextStyle(
                  fontSize: 27,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              padding: const EdgeInsets.all(20),
              children: [
                _buildBox(context, "UCUA Form", _navigateToUCUAForm),
                _buildBox(context, "View Profile", _navigateToViewProfile),
                _buildBox(context, "Sign Out", _signOut),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBox(BuildContext context, String text, Function() onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(
            text,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  void _navigateToUCUAForm() {
    // Navigate to UCUA Form page
  }

  void _navigateToViewProfile() {
    // Navigate to View Profile page
  }

  void _signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.pushNamed(context, "/login");
    } catch (e) {
      print("Error signing out: $e");
      // Handle the error as needed, e.g., show a snackbar or toast with the error message.
    }
  }
}

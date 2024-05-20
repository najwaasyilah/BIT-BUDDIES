import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
//import 'package:ucua_staging/features/ucua_fx/screens/pages/SafetyDept/navbar.dart';


class SafetyDeptHomePage extends StatefulWidget {
  const SafetyDeptHomePage({super.key});

  @override
  State<SafetyDeptHomePage> createState() => _SafetyDeptHomePageState();
}

class _SafetyDeptHomePageState extends State<SafetyDeptHomePage> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: _signOut,
          ),
        ],
        automaticallyImplyLeading: false, // Remove the back button
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            color: Colors.white,
            child: const Center(
              child: Text(
                "UCUA",
                style: TextStyle(fontSize: 27, fontWeight: FontWeight.bold, color: Colors.black),
              ),
            ),
          ),
          const SizedBox(height: 60),
          _buildSafetyDepartmentCard("Safety Department"), // Inserting the Esafety department Card
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Color.fromARGB(255, 33, 82, 243), // Change the selected item color
        unselectedItemColor: Colors.grey, // Change the unselected item color
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildSafetyDepartmentCard(String safetyDepartmentName) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          height: 150,
          padding: EdgeInsets.all(15),
          margin: EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 33, 82, 243),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.5),
                spreadRadius: 2,
                blurRadius: 5,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    safetyDepartmentName,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  SizedBox(height: 10),
                  Text(
                    "Aiman Haiqal",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  SizedBox(height: 5),
                  Text(
                    "010203",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              ),
              Positioned(
                top: 10,
                right: 10,
                child: CircleAvatar(
                  radius: 40,
                  backgroundImage: AssetImage('assets/profile_picture.png'),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildSquareRoundedBox("Unsafe Action"),
            SizedBox(width: 20),
            _buildSquareRoundedBox("Unsafe Condition"),
          ],
        ),
        SizedBox(height: 20),
        _buildRectangleRoundedBox("Unsafe Action Report List"),
        SizedBox(height: 20),
        _buildRectangleRoundedBox("Unsafe Condition Report List"),
      ],
    );
  }

  Widget _buildSquareRoundedBox(String description) {
    return GestureDetector(
      onTap: () {
        if (description == "Unsafe Action") {
          Navigator.pushNamed(context, "/sdUAForm");
        } else if (description == "Unsafe Condition") {
          Navigator.pushNamed(context, "/sdUCForm");
        }
      },
      child: Container(
        width: 150,
        height: 150,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.5),
              spreadRadius: 2,
              blurRadius: 5,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.description, size: 40, color: Colors.black),
            SizedBox(height: 10),
            Text(
              description,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRectangleRoundedBox(String text) {
    return GestureDetector(
      onTap: () {
        if (text == "Unsafe Action Report List") {
          Navigator.pushNamed(context, "/sdUAFormList");
        } else if (text == "Unsafe Condition Report List") {
          Navigator.pushNamed(context, "/sdUCFormList");
        }
      },
      child: Container(
        width: 300,
        padding: EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Color.fromARGB(255, 33, 82, 243),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.5),
              spreadRadius: 2,
              blurRadius: 5,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
    );
  }

  void _signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.pushNamed(context, "/login");
    } catch (e) {
      print("Error signing out: $e");
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      switch (index) {
        case 0:
          Navigator.pushNamedAndRemoveUntil(context, "/safetyHome", (route) => false); // Navigate without back button
          break;
        case 1:
          Navigator.pushNamed(context, "/safeDeptProfile");
          break;
      }
    });
  }
}

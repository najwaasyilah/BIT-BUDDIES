// ignore_for_file: prefer_const_constructors, avoid_print, camel_case_types
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:ucua_staging/features/ucua_fx/screens/pages/SafetyDept/action_form/viewAction_form.dart';

class safeDeptListAllUAForm extends StatefulWidget {
  const safeDeptListAllUAForm({super.key});

  @override
  State<safeDeptListAllUAForm> createState() => _safeDeptListAllUAFormState();
}

class _safeDeptListAllUAFormState extends State<safeDeptListAllUAForm> {
  String? currentUserStaffID;

  @override
  void initState() {
    super.initState();
    getCurrentUserStaffID();
  }


  Future<void> getCurrentUserStaffID() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      final uid = currentUser.uid;
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final staffID = userDoc.get('staffID');
      setState(() {
        currentUserStaffID = staffID;
      });
    }
  }

  Future<void> deleteImages(String docId) async {
    try {
      final documentSnapshot = await FirebaseFirestore.instance.collection('uaform').doc(docId).get();
      if (documentSnapshot.exists) {
        if (documentSnapshot.data()!.containsKey('imageURLs')) {
          final imageURLs = List<String>.from(documentSnapshot.get('imageURLs') ?? []);
          final storage = FirebaseStorage.instance;

          for (final url in imageURLs) {
            try {
              print('Attempting to delete image from URL: $url');
              await storage.refFromURL(url).delete();
              print('Successfully deleted image: $url');
            } catch (e) {
              print('Error deleting image at $url: $e');
            }
          }
        } else {
          print('No imageURLs field found in document with ID: $docId');
        }
      } else {
        print('Document with ID $docId does not exist');
      }
    } catch (e) {
      print('Error fetching document for deletion with ID $docId: $e');
    }
  }

  Future<void> deleteActionForm(String docId) async {
    try {
        DocumentReference mainDocRef = FirebaseFirestore.instance.collection('uaform').doc(docId);
        await deleteImages(docId);

        Future<void> deleteSubcollection(CollectionReference collectionRef) async {
            QuerySnapshot snapshot;
            do {
                snapshot = await collectionRef.limit(10).get();
                for (DocumentSnapshot doc in snapshot.docs) {
                    await doc.reference.delete();
                }
            } while (snapshot.size == 10);
        }

        await deleteSubcollection(mainDocRef.collection('uafollowup'));
        await deleteSubcollection(mainDocRef.collection('notifications'));
        await mainDocRef.delete();

        print('Successfully deleted main document and its subcollections: $docId');
    } catch (e) {
        print('Error deleting form: $e');
    }
  }

  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'pending':
        return Color.fromARGB(255, 212, 192, 6);
      default:
        return Colors.grey; 
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("List of Unsafe Action Forms"),
      ),
      body: Container(
        color: Colors.grey.withOpacity(.35),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.5),
                    spreadRadius: 5,
                    blurRadius: 7,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Center(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'LIST OF UNSAFE ACTION REPORT',
                        style: TextStyle(
                          fontSize: 23.0,
                          fontWeight: FontWeight.w900,
                          color: Color.fromARGB(255, 199, 26, 230),
                        ),
                      ),
                      SizedBox(height: 20),
                      StreamBuilder(
                        stream: FirebaseFirestore.instance
                          .collection('uaform')
                          .orderBy('date', descending: true)
                          .snapshots(),
                        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
                          if (snapshot.hasError) {
                            return Text('Error: ${snapshot.error}');
                          }

                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return CircularProgressIndicator();
                          }

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (DocumentSnapshot document in snapshot.data!.docs)
                                Container(
                                  margin: EdgeInsets.only(bottom: 20),
                                  padding: EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${document['uaformid']}',
                                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                      ),
                                      SizedBox(height: 5),
                                      Text(
                                        'Date Created: ${document['date']}',
                                        style: TextStyle(fontSize: 16),
                                      ),
                                      SizedBox(height: 5),
                                      if ((document.data() as Map<String, dynamic>).containsKey('status'))
                                      Row(
                                        children: [
                                          Container(
                                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: getStatusColor(document['status']), 
                                              borderRadius: BorderRadius.circular(5),
                                            ),
                                            child: Text(
                                              'Status: ${document['status']}', 
                                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 10),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                                        children: [
                                          ElevatedButton(
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) => safeDeptViewUAForm(docId: document.id),
                                                ),
                                              );
                                            },
                                            child: Text('View'),
                                          ),
                                          ElevatedButton(
                                            onPressed: () {
                                              deleteActionForm(document.id);
                                            },
                                            child: Text('Delete'),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
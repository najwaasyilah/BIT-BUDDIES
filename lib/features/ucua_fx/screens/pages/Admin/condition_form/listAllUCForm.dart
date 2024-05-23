import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:ucua_staging/features/ucua_fx/screens/pages/Admin/condition_form/viewCondition_form.dart';

class adminListAllUCForm extends StatefulWidget {
  const adminListAllUCForm({super.key});

  @override
  State<adminListAllUCForm> createState() => _adminListAllUCFormState();
}

class _adminListAllUCFormState extends State<adminListAllUCForm> {
  String? currentUserStaffID;

  @override
  void initState() {
    super.initState();
    //getCurrentUserStaffID();
  }

  /*Future<void> getCurrentUserStaffID() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      final uid = currentUser.uid;
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final staffID = userDoc.get('staffID');
      setState(() {
        currentUserStaffID = staffID;
      });
    }
  }*/

  Future<void> deleteImages(String docId) async {
    try {
      final documentSnapshot = await FirebaseFirestore.instance.collection('ucform').doc(docId).get();
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

  void deleteConditionForm(String docId) async {
    try {
      await deleteImages(docId); 

      final followupCollectionRef = FirebaseFirestore.instance.collection('ucform').doc(docId).collection('ucfollowup');
      final followupDocs = await followupCollectionRef.get();
      for (final followupDoc in followupDocs.docs) {
        try {
          await followupDoc.reference.delete();
          print('Deleted follow-up document: ${followupDoc.id}');
        } catch (e) {
          print('Error deleting follow-up document: ${followupDoc.id} - $e');
        }
      }

      await FirebaseFirestore.instance.collection('ucform').doc(docId).delete();
      print('Successfully deleted main document: $docId');
    } catch (e) {
      print('Error deleting form: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("List of Unsafe Condition Forms"),
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
                        'LIST OF UNSAFE CONDITION REPORT',
                        style: TextStyle(
                          fontSize: 23.0,
                          fontWeight: FontWeight.w900,
                          color: Color.fromARGB(255, 199, 26, 230),
                        ),
                      ),
                      SizedBox(height: 20),
                      StreamBuilder(
                        stream: FirebaseFirestore.instance
                            .collection('ucform')
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
                                        'Unsafe Condition Form',
                                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                      ),
                                      SizedBox(height: 5),
                                      Text(
                                        'Date Created: ${document['date']}',
                                        style: TextStyle(fontSize: 16),
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
                                                  builder: (context) => adminViewUCForm(docId: document.id),
                                                ),
                                              );
                                            },
                                            child: Text('View'),
                                          ),
                                          ElevatedButton(
                                            onPressed: () {
                                              deleteConditionForm(document.id);
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
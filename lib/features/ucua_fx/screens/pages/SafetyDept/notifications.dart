import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:intl/intl.dart';
import 'package:ucua_staging/features/ucua_fx/screens/pages/SafetyDept/action_form/viewAction_form.dart';
import 'package:ucua_staging/features/ucua_fx/screens/pages/SafetyDept/condition_form/viewCondition_form.dart';
import '../../../../../notification.dart';
import 'package:badges/badges.dart' as badges;

class SafeDeptNotyPage extends StatefulWidget {
  const SafeDeptNotyPage({super.key});

  @override
  _SafeDeptNotyPageState createState() => _SafeDeptNotyPageState();
}

class _SafeDeptNotyPageState extends State<SafeDeptNotyPage> {
  int _selectedIndex = 0;
  int _unreadNotifications = 0;
  final List<Map<String, dynamic>> _notifications = [];
  late NotificationService _notificationService;

  @override
  void initState() {
    super.initState();
    _notificationService = NotificationService();

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        final data = message.data;
        final String type = data['type'] ?? 'unknown';
        final String formId = data['formId'] ?? '';
        final String notificationId = data['notificationId'] ?? '';

        setState(() {
          _notifications.add({
            'title': message.notification!.title ?? 'No Title',
            'body': message.notification!.body ?? 'No Body',
            'formType': type,
            'formId': formId,
            'notificationId': notificationId,
            'sdNotiStatus': 'unread',
          });
          _unreadNotifications++;
        });
      }
    });

    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    try {
      QuerySnapshot ucFormSnapshot = await FirebaseFirestore.instance.collection('ucform').get();
      QuerySnapshot uaFormSnapshot = await FirebaseFirestore.instance.collection('uaform').get();
      int unreadCount = 0;

      unreadCount += await _processFormNotifications(ucFormSnapshot, 'ucform');
      unreadCount += await _processFormNotifications(uaFormSnapshot, 'uaform');

      _notifications.sort((a, b) {
        Timestamp timestampA = a['timestamp'] as Timestamp;
        Timestamp timestampB = b['timestamp'] as Timestamp;
        return timestampB.compareTo(timestampA);
      });

      setState(() {
        _unreadNotifications = unreadCount;
      });
    } catch (e) {
      print('Error fetching notifications: $e');
    }
  }

  Future<int> _processFormNotifications(QuerySnapshot formSnapshot, String type) async {
    int unreadCount = 0;
    for (QueryDocumentSnapshot formDoc in formSnapshot.docs) {
      CollectionReference notificationsRef = formDoc.reference.collection('notifications');
      QuerySnapshot notificationSnapshot = await notificationsRef.get();
      for (QueryDocumentSnapshot notificationDoc in notificationSnapshot.docs) {
        var notificationData = notificationDoc.data() as Map<String, dynamic>?;
        if (notificationData != null) {
          String sdNotiStatus = notificationData.containsKey('sdNotiStatus') ? notificationData['sdNotiStatus'] : 'unread';
          _notifications.add({
            'title': notificationData['department'] ?? 'No department',
            'body': notificationData['message'] ?? 'No message',
            'timestamp': notificationData['timestamp'] ?? Timestamp.now(),
            'type': type,
            'formId': formDoc.id,
            'notificationId': notificationDoc.id,
            'sdNotiStatus': sdNotiStatus,
          });
          if (sdNotiStatus == 'unread') {
            unreadCount++;
          }
        }
      }
    }
    return unreadCount;
  }

  String timeAgo(DateTime date) {
    Duration difference = DateTime.now().difference(date);

    if (difference.inDays > 8) {
      return DateFormat('dd/MM/yyyy').format(date);
    } else if ((difference.inDays / 7).floor() >= 1) {
      return '${(difference.inDays / 7).floor()}w';
    } else if (difference.inDays >= 1) {
      return '${difference.inDays}d';
    } else if (difference.inHours >= 1) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes >= 1) {
      return '${difference.inMinutes}m';
    } else if (difference.inSeconds >= 1) {
      return '${difference.inSeconds}s';
    } else {
      return 'just now';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Notifications'),
        centerTitle: true,
      ),
      body: ListView.builder(
        itemCount: _notifications.length,
        itemBuilder: (context, index) {
          var notification = _notifications[index];
          var timestamp = notification['timestamp'] as Timestamp;
          var date = timestamp.toDate();
          var formattedTime = timeAgo(date);

          return ListTile(
            title: Text(
              notification['title']!,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(notification['body']!),
                ),
                Flexible(
                  child: Text(formattedTime, style: const TextStyle(color: Colors.grey)),
                ),
              ],
            ),
            trailing: notification['sdNotiStatus'] == 'unread'
                ? const Icon(Icons.circle, color: Colors.blue, size: 10)
                : null,
            onTap: () async {
              String formType = notification['type'];
              String formId = notification['formId'];

              if (formType == 'ucform' || formType == 'uaform') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => formType == 'ucform'
                        ? safeDeptViewUCForm(docId: formId)
                        : safeDeptViewUAForm(docId: formId),
                  ),
                );
              }

              bool isSafetyDepartment = true; // Change this based on your role-checking logic

              if (isSafetyDepartment && notification['sdNotiStatus'] != 'read') {
                try {
                  final docRef = FirebaseFirestore.instance
                      .collection(formType)
                      .doc(formId)
                      .collection('notifications')
                      .doc(notification['notificationId']);

                  await docRef.update({
                    'sdNotiStatus': 'read',
                  }).then((_) {
                    setState(() {
                      _notifications[index]['sdNotiStatus'] = 'read';
                      _unreadNotifications--;
                    });
                  }).catchError((error) {
                    print('Error updating document: $error');
                  });
                } catch (e) {
                  print('Error marking notifications as read: $e');
                }
              }
            },
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, "/safetyHome");
        },
        backgroundColor: const Color.fromARGB(255, 33, 82, 243),
        child: const Icon(
          Icons.home,
          size: 30,
          color: Colors.white,
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: const Color.fromARGB(255, 33, 82, 243),
        unselectedItemColor: Colors.grey,
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: badges.Badge(
              badgeContent: Text(
                '$_unreadNotifications',
                style: const TextStyle(color: Colors.white),
              ),
              showBadge: _unreadNotifications > 0,
              child: const Icon(Icons.notifications),
            ),
            label: 'Notifications',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      switch (index) {
        case 0:
          Navigator.pushNamed(context, "/safeDeptNoty");
          break;
        case 1:
          Navigator.pushNamed(context, "/safeDeptProfile");
          break;
      }
    });
  }
}

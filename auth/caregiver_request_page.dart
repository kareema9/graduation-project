import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CaregiverRequestsPage extends StatelessWidget {
  const CaregiverRequestsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final String patientUid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: Text("Caregiver Requests"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('caregiver_requests')
            .where('patientUid', isEqualTo: patientUid)
            .where('approved', isEqualTo: false)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text("No pending requests"),
            );
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final request = snapshot.data!.docs[index];
              final caregiverUid = request['caregiverUid'];

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(caregiverUid)
                    .get(),
                builder: (context, caregiverSnapshot) {
                  if (!caregiverSnapshot.hasData) {
                    return SizedBox();
                  }

                  final caregiverData =
                      caregiverSnapshot.data!.data() as Map<String, dynamic>;

                  return Card(
                    margin: EdgeInsets.all(10),
                    child: ListTile(
                      title: Text(caregiverData['name']),
                      subtitle: Text(caregiverData['email']),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.check, color: Colors.green),
                            onPressed: () async {
                              await FirebaseFirestore.instance
                                  .collection('caregiver_requests')
                                  .doc(request.id)
                                  .update({'approved': true});

                              await FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(patientUid)
                                  .update({
                                'caregivers':
                                    FieldValue.arrayUnion([caregiverUid])
                              });

                              await FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(caregiverUid)
                                  .update({
                                'patientAccessApproved': true
                              });
                            },
                          ),
                          IconButton(
                            icon: Icon(Icons.close, color: Colors.red),
                            onPressed: () async {
                              await FirebaseFirestore.instance
                                  .collection('caregiver_requests')
                                  .doc(request.id)
                                  .delete();
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

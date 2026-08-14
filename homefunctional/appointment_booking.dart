import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'doctor_schedule_page.dart';

class BookingschedulesPage extends StatefulWidget {
  const BookingschedulesPage({super.key});

  @override
  State<BookingschedulesPage> createState() => _BookingschedulesPageState();
}

class _BookingschedulesPageState extends State<BookingschedulesPage> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  bool isLoading = true;
  List<Map<String, dynamic>> doctors = [];

  @override
  void initState() {
    super.initState();
    loadDoctors();
  }

  Future<void> loadDoctors() async {
    final snapshot =
        await firestore
            .collection('users')
            .where('userType', isEqualTo: 'doctor')
            .get();

    doctors =
        snapshot.docs
            .map((d) => {'id': d.id, 'name': d['name'] ?? 'Doctor'})
            .toList();

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1C621B),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Doctors Schedule",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
        centerTitle: false,
        elevation: 0,
      ),

      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: doctors.length,
                itemBuilder: (_, i) {
                  final d = doctors[i];
                  return Card(
                    child: ListTile(
                      title: Text(d['name']),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (_) => DoctorSchedulePage(
                                  doctorId: d['id'],
                                  doctorName: d['name'],
                                ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
    );
  }
}
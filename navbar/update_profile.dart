import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:first_app/component/buttonauth.dart';
import 'package:first_app/navbar/nav.dart';
import 'package:flutter/material.dart';

class EditProfile extends StatefulWidget {
  final String docid;
  final oldname;
  final oldphone;
  final String? oldBirthDate;

  const EditProfile({
    super.key,
    required this.docid,
    required this.oldname,
    required this.oldphone,
    this.oldBirthDate,
  });

  @override
  State<EditProfile> createState() => _EditProfile();
}

class _EditProfile extends State<EditProfile> {
  final GlobalKey<FormState> formState = GlobalKey();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController birthDateController = TextEditingController();

  CollectionReference editUser = FirebaseFirestore.instance.collection("users");

  editProfile() async {
    await editUser.doc(widget.docid).update({
      "name": nameController.text,
      "phone": phoneController.text,
      "birthDate": birthDateController.text,
    });
  }

  @override
  void initState() {
    super.initState();
    nameController.text = widget.oldname;
    phoneController.text = widget.oldphone;
    birthDateController.text = widget.oldBirthDate ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1C621B),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Edit Profile",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Container(
          color: const Color.fromARGB(255, 253, 254, 252),
          width: double.infinity,
          child: Padding(
            padding: const EdgeInsets.all(30),
            child: Form(
              key: formState,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --------------------------------------name field
                    TextFormField(
                      controller: nameController,
                      validator: (val) {
                        if (val == null || val.isEmpty) {
                          return "The  Name is required!";
                        }
                        return null;
                      },
                      decoration: InputDecoration(
                        labelText: ' Name',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // ----------------------------------------phone field
                    TextFormField(
                      controller: phoneController,
                      validator: (val) {
                        if (val == null || val.isEmpty) {
                          return "The  phone is required!";
                        }
                        return null;
                      },
                      decoration: InputDecoration(
                        labelText: ' phone',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ------------------------------------birthDay field
                    TextFormField(
                      controller: birthDateController,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'Birth Date',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      validator: (val) {
                        if (val == null || val.isEmpty) {
                          return "The birth date is required!";
                        }
                        return null;
                      },
                      onTap: () async {
                        DateTime? pickedDate = await showDatePicker(
                          context: context,
                          initialDate:
                              DateTime.tryParse(birthDateController.text) ??
                              DateTime(2000),
                          firstDate: DateTime(1900),
                          lastDate: DateTime.now(),
                        );
                        if (pickedDate != null) {
                          setState(() {
                            birthDateController.text =
                                "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      child: CustomButton(
                        onPressed: () {
                          if (nameController.text.isEmpty ||
                              phoneController.text.isEmpty ||
                              birthDateController.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "Please fill all fields!",
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            );
                            return;
                          }

                          editProfile().then((_) {
                            
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => NavPage(initialIndex:1),
                              ),
                             
                            );
                          });
                        },

                        title: 'Save ',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

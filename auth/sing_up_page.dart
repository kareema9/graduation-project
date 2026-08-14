import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:first_app/component/buttonauth.dart';
import 'package:first_app/component/iconauth.dart';
import 'package:first_app/component/textformfield.dart';
import 'package:first_app/auth/login_page.dart';
import 'package:flutter/material.dart';

class SingUp extends StatefulWidget {
  const SingUp({super.key});

  @override
  State<SingUp> createState() => _SingUp();
}

class _SingUp extends State<SingUp> {
  String? selectedType;
  bool obsecur = true;

  TextEditingController username = TextEditingController();
  TextEditingController email = TextEditingController();
  TextEditingController emailPatient = TextEditingController();
  TextEditingController password = TextEditingController();
  TextEditingController conform = TextEditingController();
  TextEditingController phone = TextEditingController();
  DateTime? selectedBirthDate;
  TextEditingController birthDateController = TextEditingController();

  final GlobalKey<FormState> formState = GlobalKey<FormState>();
  String? errorMessage;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final List<String> userType = ['patient', 'doctor', 'caregiver'];

  // ================== SIGN UP FUNCTION ==================
  Future<void> signup() async {
    if (!formState.currentState!.validate()) return;

    try {
      String? patientUid;

      // ====== CHECK PATIENT IF CAREGIVER ======
      if (selectedType == 'caregiver') {
        final query = await _firestore
            .collection('users')
            .where('email', isEqualTo: emailPatient.text.trim())
            .where('userType', isEqualTo: 'patient')
            .limit(1)
            .get();

        if (query.docs.isEmpty) {
          setState(() {
            errorMessage =
                "This patient is not registered. Please check the patient's email.";
          });
          return;
        }

        patientUid = query.docs.first.id;
      }

      // ====== CREATE AUTH ACCOUNT ======
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: email.text.trim(),
        password: password.text,
      );

      await credential.user!.sendEmailVerification();
      String uid = credential.user!.uid;

      // ====== SAVE USER DATA ======
      await _firestore.collection('users').doc(uid).set({
        'name': username.text.trim(),
        'phone': phone.text.trim(),
        'email': email.text.trim(),
        'userType': selectedType,
        'birthDate': selectedBirthDate?.toIso8601String(),
        'status': 1,
        'patientAccessApproved':
            selectedType == 'caregiver' ? false : true,
        'stage': 0,
        'stage_caregiver': 0,
        'stage_doctor': 0,
        'stage_system': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // ====== SEND CAREGIVER REQUEST ======
      if (selectedType == 'caregiver') {
        await _firestore.collection('caregiver_requests').add({
          'caregiverUid': uid,
          'patientUid': patientUid,
          'caregiverName': username.text.trim(),
          'caregiverEmail': email.text.trim(),
          'approved': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      // ====== GO TO LOGIN ======
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => Login()),
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        if (e.code == 'weak-password') {
          errorMessage = "The password provided is too weak.";
        } else if (e.code == 'email-already-in-use') {
          errorMessage = "The account already exists for that email.";
        } else {
          errorMessage = e.message;
        }
      });
    }
  }

  // ================== UI ==================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10,horizontal: 30),
            child: Form(
              key: formState,
              child: Column(
                children: [
                  IconAuth(),

                  if (errorMessage != null)
                    Text(
                      errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),

                  const SizedBox(height: 20),

                  CustomTextForm(
                    labeltext: "Name",
                    mycontroller: username,
                    validator: (val) =>
                        val!.isEmpty ? "Name is required" : null,
                  ),

                  const SizedBox(height: 10),

                  CustomTextForm(
                    labeltext: "Email",
                    mycontroller: email,
                    validator: (val) {
                      if (val!.isEmpty) return "Email is required";
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                          .hasMatch(val)) {
                        return "Invalid email";
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 10),

                 
                     TextFormField(
                          validator: (val) {
                            if (val == "") return "*The Password is required";
                            if (val!.length < 8)
                              return "Password is too weak. Use at least 8 characters";
                            if (!RegExp(r'\d').hasMatch(val))
                              return "Password is too weak. Use at least one number";
                            if (!RegExp(r'[A-Z]').hasMatch(val))
                              return "Password is too weak. Use at least one uppercase letter";
                          },
                          controller: password,
                          obscureText: obsecur,
                          decoration: InputDecoration(
                            suffixIcon: IconButton(
                              icon: Icon(
                                obsecur
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                              onPressed: () {
                                setState(() {
                                  obsecur = !obsecur;
                                });
                              },
                            ),
                            labelText: "Password",
                            filled: true,
                            fillColor: Color(0xFFE1F3DF),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        SizedBox(height: 10),
                        TextFormField(
                          validator: (val) {
                            if (password.text != val)
                              return "The Conform Password is not matching";
                          },
                          controller: conform,
                          obscureText: obsecur,
                          decoration: InputDecoration(
                            suffixIcon: IconButton(
                              icon: Icon(
                                obsecur
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                              onPressed: () {
                                setState(() {
                                  obsecur = !obsecur;
                                });
                              },
                            ),
                            labelText: "Confirm Password",
                            filled: true,
                            fillColor: Color(0xFFE1F3DF),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),

                  const SizedBox(height: 10),

                  CustomTextForm(
                    labeltext: "Phone",
                    mycontroller: phone,
                    validator: (val) =>
                        val!.isEmpty ? "Phone is required" : null,
                  ),
  SizedBox(height: 10),
                        TextFormField(
                          controller: birthDateController,
                          readOnly: true,
                          decoration: InputDecoration(
                            labelText: "Birth Date",
                            filled: true,
                            fillColor: Color(0xFFE1F3DF),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                            suffixIcon: Icon(Icons.calendar_today),
                          ),
                          validator: (val) {
                            if (val == null || val.isEmpty)
                              return "Please select your birth date";
                            return null;
                          },
                          onTap: () async {
                            DateTime? pickedDate = await showDatePicker(
                              context: context,
                              initialDate: DateTime(2000),
                              firstDate: DateTime(1900),
                              lastDate: DateTime.now(),
                            );

                            if (pickedDate != null) {
                              setState(() {
                                selectedBirthDate = pickedDate;
                                birthDateController.text =
                                    "${pickedDate.day}/${pickedDate.month}/${pickedDate.year}";
                              });
                            }
                          },
                        ),
                  const SizedBox(height: 10),

                  DropdownButtonFormField<String>(
                    value: selectedType,
                    decoration: const InputDecoration(
                      labelText: "User Type",
                      border: OutlineInputBorder(),
                    ),
                    items: userType
                        .map(
                          (e) => DropdownMenuItem(
                            value: e,
                            child: Text(e),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      setState(() {
                        selectedType = val;
                      });
                    },
                    validator: (val) =>
                        val == null ? "Please select user type" : null,
                  ),

                  // ===== CAREGIVER ONLY =====
                  if (selectedType == 'caregiver')
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: CustomTextForm(
                        labeltext: "Patient Email",
                        mycontroller: emailPatient,
                        validator: (val) {
                          if (val!.isEmpty) {
                            return "Patient email is required";
                          }
                          return null;
                        },
                      ),
                    ),

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: CustomButton(
                      title: "Sign Up",
                      onPressed: signup,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}










// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:first_app/component/buttonauth.dart';
// import 'package:first_app/component/iconauth.dart';
// import 'package:first_app/component/textformfield.dart';
// import 'package:first_app/auth/login_page.dart';
// import 'package:flutter/material.dart';

// class SingUp extends StatefulWidget {
//   const SingUp({super.key});

//   @override
//   State<SingUp> createState() => _SingUp();
// }

// class _SingUp extends State<SingUp> {
//   String? selectedType;
//   bool obsecur = true;

//   TextEditingController username = TextEditingController();
//   TextEditingController email = TextEditingController();
//   TextEditingController emailPatient = TextEditingController();
//   TextEditingController password = TextEditingController();
//   TextEditingController conform = TextEditingController();
//   TextEditingController phone = TextEditingController();
//   DateTime? selectedBirthDate;
//   TextEditingController birthDateController = TextEditingController();

//   final GlobalKey<FormState> formState = GlobalKey<FormState>();
//   final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
//       GlobalKey<ScaffoldMessengerState>();

//   String? errorMessage;
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;

//   final List<String> userType = ['patient', 'doctor', 'caregiver'];

//   //================signup function======================
//   Future<void> signup() async {
//     if (formState.currentState!.validate()) {
//       try {
//         String? patientUid;

//         // if (selectedType == 'caregiver') {
//         //   final query =
//         //       await _firestore
//         //           .collection('users')
//         //           .where('email', isEqualTo: emailPatient.text.trim())
//         //           .where('userType', isEqualTo: 'patient')
//         //           .limit(1)
//         //           .get();

          

//         //   patientUid = query.docs.first.id;
//         // }
        

//         final credential = await FirebaseAuth.instance
//             .createUserWithEmailAndPassword(
//               email: email.text.trim(),
//               password: password.text,
//             );

//         await credential.user!.sendEmailVerification();

//         String uid = credential.user!.uid;

//         await _firestore.collection('users').doc(uid).set({
//           'name': username.text.trim(),
//           'phone': phone.text.trim(),
//           'email': email.text.trim(),
//           'userType': selectedType,
//           'birthDate': selectedBirthDate?.toIso8601String(),
//           'status': 1,
//           'patientAccessApproved': selectedType == 'caregiver' ? false : true,
//           'stage': 0,
//           'stage_caregiver': 0,
//           'stage_doctor': 0,
//           'stage_system': 0,
//           'createdAt': FieldValue.serverTimestamp(),
//         });

//         // if (selectedType == 'caregiver') {
//         //   await _firestore.collection('caregiver_requests').add({
//         //     'caregiverUid': uid,
//         //     'patientUid': patientUid,
//         //     'caregiver_name': username.text.trim(),
//         //     'approved': false,
//         //     'createdAt': FieldValue.serverTimestamp(),
//         //   });
//         // }

//         ///////////////Login
//         Navigator.of(
//           context,
//         ).pushReplacement(MaterialPageRoute(builder: (context) => Login()));

//         print("=============================User signed up successfully!");
//       } on FirebaseAuthException catch (e) {
//         if (e.code == 'weak-password') {
//           setState(() {
//             errorMessage = "The password provided is too weak.";
//           });
//         } else if (e.code == 'email-already-in-use') {
//           setState(() {
//             errorMessage = "The account already exists for that email.";
//           });
//         }
//       } catch (e) {
//         print(e);
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: SafeArea(
//         child: Center(
//           child: SingleChildScrollView(
//             child: Container(
//               padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
//               width: MediaQuery.of(context).size.width * 0.9,
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.center,
//                 children: [
//                   IconAuth(),
//                   Form(
//                     key: formState,
//                     child: Column(
//                       children: [
//                         if (errorMessage != null)
//                           Padding(
//                             padding: EdgeInsets.only(top: 5),
//                             child: Text(
//                               errorMessage!,
//                               style: TextStyle(fontSize: 16, color: Colors.red),
//                             ),
//                           ),
//                         SizedBox(height: 20),
//                         CustomTextForm(
//                           validator: (val) {
//                             if (val == "") return "*The Name is required";
//                           },
//                           labeltext: "Name",
//                           mycontroller: username,
//                         ),
//                         SizedBox(height: 10),
//                         TextFormField(
//                           validator: (val) {
//                             if (val == "") return "*The email is required";
//                             bool emailValid = RegExp(
//                               r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
//                             ).hasMatch(val!);
//                             if (!emailValid)
//                               return "Please enter a valid email";
//                           },
//                           controller: email,
//                           keyboardType: TextInputType.emailAddress,
//                           autofillHints: [AutofillHints.email],
//                           decoration: InputDecoration(
//                             labelText: "Email",
//                             filled: true,
//                             fillColor: Color(0xFFE1F3DF),
//                             border: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(10),
//                               borderSide: BorderSide.none,
//                             ),
//                           ),
//                         ),
//                         SizedBox(height: 10),
//                         TextFormField(
//                           validator: (val) {
//                             if (val == "") return "*The Password is required";
//                             if (val!.length < 8)
//                               return "Password is too weak. Use at least 8 characters";
//                             if (!RegExp(r'\d').hasMatch(val))
//                               return "Password is too weak. Use at least one number";
//                             if (!RegExp(r'[A-Z]').hasMatch(val))
//                               return "Password is too weak. Use at least one uppercase letter";
//                           },
//                           controller: password,
//                           obscureText: obsecur,
//                           decoration: InputDecoration(
//                             suffixIcon: IconButton(
//                               icon: Icon(
//                                 obsecur
//                                     ? Icons.visibility_off
//                                     : Icons.visibility,
//                               ),
//                               onPressed: () {
//                                 setState(() {
//                                   obsecur = !obsecur;
//                                 });
//                               },
//                             ),
//                             labelText: "Password",
//                             filled: true,
//                             fillColor: Color(0xFFE1F3DF),
//                             border: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(10),
//                               borderSide: BorderSide.none,
//                             ),
//                           ),
//                         ),
//                         SizedBox(height: 10),
//                         TextFormField(
//                           validator: (val) {
//                             if (password.text != val)
//                               return "The Conform Password is not matching";
//                           },
//                           controller: conform,
//                           obscureText: obsecur,
//                           decoration: InputDecoration(
//                             suffixIcon: IconButton(
//                               icon: Icon(
//                                 obsecur
//                                     ? Icons.visibility_off
//                                     : Icons.visibility,
//                               ),
//                               onPressed: () {
//                                 setState(() {
//                                   obsecur = !obsecur;
//                                 });
//                               },
//                             ),
//                             labelText: "Confirm Password",
//                             filled: true,
//                             fillColor: Color(0xFFE1F3DF),
//                             border: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(10),
//                               borderSide: BorderSide.none,
//                             ),
//                           ),
//                         ),
//                         SizedBox(height: 10),
//                         CustomTextForm(
//                           validator: (val) {
//                             if (val == "") return "*The Phone is required";
//                             if (!RegExp(r'^[0-9]+$').hasMatch(val!))
//                               return "Phone number must contain digits only";
//                           },
//                           labeltext: "Phone Number",
//                           mycontroller: phone,
//                         ),
//                         SizedBox(height: 10),
//                         TextFormField(
//                           controller: birthDateController,
//                           readOnly: true,
//                           decoration: InputDecoration(
//                             labelText: "Birth Date",
//                             filled: true,
//                             fillColor: Color(0xFFE1F3DF),
//                             border: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(10),
//                               borderSide: BorderSide.none,
//                             ),
//                             suffixIcon: Icon(Icons.calendar_today),
//                           ),
//                           validator: (val) {
//                             if (val == null || val.isEmpty)
//                               return "Please select your birth date";
//                             return null;
//                           },
//                           onTap: () async {
//                             DateTime? pickedDate = await showDatePicker(
//                               context: context,
//                               initialDate: DateTime(2000),
//                               firstDate: DateTime(1900),
//                               lastDate: DateTime.now(),
//                             );

//                             if (pickedDate != null) {
//                               setState(() {
//                                 selectedBirthDate = pickedDate;
//                                 birthDateController.text =
//                                     "${pickedDate.day}/${pickedDate.month}/${pickedDate.year}";
//                               });
//                             }
//                           },
//                         ),
//                         SizedBox(height: 10),
//                         DropdownButtonFormField<String>(
//                           decoration: InputDecoration(
//                             labelText: "Select User Type",
//                             border: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(10),
//                             ),
//                           ),
//                           items:
//                               userType
//                                   .map(
//                                     (type) => DropdownMenuItem(
//                                       value: type,
//                                       child: Text(type),
//                                     ),
//                                   )
//                                   .toList(),
//                           value: selectedType,
//                           onChanged: (val) {
//                             setState(() {
//                               selectedType = val;
//                             });
//                           },
//                           validator:
//                               (value) =>
//                                   value == null
//                                       ? "Please select your Type"
//                                       : null,
//                         ),
//                         if (selectedType == "caregiver")
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: TextFormField(
//                               validator: (val) {
//                                 if (val == "")
//                                   return "*The Patient's email is required";
//                                 bool emailValid = RegExp(
//                                   r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
//                                 ).hasMatch(val!);
//                                 if (!emailValid)
//                                   return "Please enter a valid email address";
//                               },
//                               controller: emailPatient,
//                               keyboardType: TextInputType.emailAddress,
//                               autofillHints: [AutofillHints.email],
//                               decoration: InputDecoration(
//                                 labelText: "Patient's email",
//                                 filled: true,
//                                 fillColor: Color(0xFFE1F3DF),
//                                 border: OutlineInputBorder(
//                                   borderRadius: BorderRadius.circular(10),
//                                   borderSide: BorderSide.none,
//                                 ),
//                               ),
//                             ),
//                           ),
//                         SizedBox(height: 20),
//                         SizedBox(
//                           width: double.infinity,
//                           child: CustomButton(
//                             title: "Sign Up",
//                             onPressed: () async {
//                               signup();
//                             },
//                           ),
//                         ),
//                         MaterialButton(
//                           onPressed: () {
//                             Navigator.of(context).pushReplacement(
//                               MaterialPageRoute(builder: (context) => Login()),
//                             );
//                           },
//                           child: Row(
//                             children: [
//                               Text(
//                                 "Have An Account ?",
//                                 style: TextStyle(
//                                   color: Colors.black,
//                                   fontSize: 15,
//                                   fontWeight: FontWeight.bold,
//                                 ),
//                               ),
//                               SizedBox(width: 10),
//                               Text(
//                                 "LogIn",
//                                 style: TextStyle(
//                                   color: Color(0xFF1C621B),
//                                   fontSize: 15,
//                                   fontWeight: FontWeight.bold,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }










































// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:first_app/component/buttonauth.dart';
// import 'package:first_app/component/iconauth.dart';
// import 'package:first_app/component/textformfield.dart';
// import 'package:first_app/auth/login_page.dart';
// import 'package:flutter/material.dart';

// class SingUp extends StatefulWidget {
//   const SingUp({super.key});

//   @override
//   State<SingUp> createState() => _SingUpState();
// }

// class _SingUpState extends State<SingUp> {
//   String? selectedType;
//   bool obsecur = true;

//   final TextEditingController username = TextEditingController();
//   final TextEditingController email = TextEditingController();
//   final TextEditingController emailPatient = TextEditingController();
//   final TextEditingController password = TextEditingController();
//   final TextEditingController conform = TextEditingController();
//   final TextEditingController phone = TextEditingController();
//   DateTime? selectedBirthDate;
//   final TextEditingController birthDateController = TextEditingController();

//   final GlobalKey<FormState> formState = GlobalKey<FormState>();
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;

//   final List<String> userType = ['patient', 'doctor', 'caregiver'];
//   Future<void> signup() async {
//   if (!formState.currentState!.validate()) return;

//   try {
//     String? patientUid;

//     // 🔹 التحقق من المريض إذا كان Caregiver
//     if (selectedType == 'caregiver') {
//       final query = await _firestore
//           .collection('users')
//           .where('email', isEqualTo: emailPatient.text.trim())
//           .where('userType', isEqualTo: 'patient')
//           .limit(1)
//           .get();

//       if (query.docs.isEmpty) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text(
//               "This patient email is not registered. Please ask the patient to sign up first.",
//             ),
//             backgroundColor: Colors.red,
//           ),
//         );
//         return; // ⛔ إيقاف التسجيل
//       }

//       patientUid = query.docs.first.id;
//     }

//     // 🔹 إنشاء الحساب
//     final credential =
//         await FirebaseAuth.instance.createUserWithEmailAndPassword(
//       email: email.text.trim(),
//       password: password.text,
//     );

//     await credential.user!.sendEmailVerification();
//     String uid = credential.user!.uid;

//     // 🔹 حفظ المستخدم
//     await _firestore.collection('users').doc(uid).set({
//       'name': username.text.trim(),
//       'phone': phone.text.trim(),
//       'email': email.text.trim(),
//       'userType': selectedType,
//       'birthDate': selectedBirthDate?.toIso8601String(),
//       'status': 1,
//       'patientAccessApproved': selectedType == 'caregiver' ? false : true,
//       'stage': 0,
//       'stage_caregiver': 0,
//       'stage_doctor': 0,
//       'stage_system': 0,
//       'createdAt': FieldValue.serverTimestamp(),
//     });

//     // 🔹 طلب ربط كيرجيفر بالمريض
//     if (selectedType == 'caregiver') {
//       await _firestore.collection('caregiver_requests').add({
//         'caregiverUid': uid,
//         'patientUid': patientUid,
//         'caregiver_name': username.text.trim(),
//         'approved': false,
//         'createdAt': FieldValue.serverTimestamp(),
//       });
//     }

//     Navigator.pushReplacement(
//       context,
//       MaterialPageRoute(builder: (_) => Login()),
//     );
//   } catch (e) {
//     print(e);
//   }
// }


//   // Future<void> signup() async {
//   //   if (!formState.currentState!.validate()) return;

//   //   try {
//   //     String? patientUid;

//   //     // 🔹 تحقق من المريض إذا كان Caregiver
//   //     if (selectedType == 'caregiver') {
//   //       final query = await _firestore
//   //           .collection('users')
//   //           .where('email', isEqualTo: emailPatient.text.trim())
//   //           .where('userType', isEqualTo: 'patient')
//   //           .limit(1)
//   //           .get();

//   //       if (query.docs.isEmpty) {
//   //         ScaffoldMessenger.of(context).showSnackBar(
//   //           SnackBar(
//   //             content: Text(
//   //               "This patient email is not registered. Please ask the patient to sign up first.",
//   //             ),
//   //             backgroundColor: Colors.red,
//   //           ),
//   //         );
//   //         return; // إيقاف التسجيل
//   //       }

//   //       patientUid = query.docs.first.id;
//   //     }

//   //     // 🔹 إنشاء الحساب
//   //     final credential =
//   //         await FirebaseAuth.instance.createUserWithEmailAndPassword(
//   //       email: email.text.trim(),
//   //       password: password.text,
//   //     );

//   //     await credential.user!.sendEmailVerification();
//   //     String uid = credential.user!.uid;

//   //     // 🔹 حفظ المستخدم
//   //     await _firestore.collection('users').doc(uid).set({
//   //       'name': username.text.trim(),
//   //       'phone': phone.text.trim(),
//   //       'email': email.text.trim(),
//   //       'userType': selectedType,
//   //       'birthDate': selectedBirthDate?.toIso8601String(),
//   //       'status': 1,
//   //       'patientAccessApproved': selectedType == 'caregiver' ? false : true,
//   //       'stage': 0,
//   //       'stage_caregiver': 0,
//   //       'stage_doctor': 0,
//   //       'stage_system': 0,
//   //       'createdAt': FieldValue.serverTimestamp(),
//   //     });

//   //     // 🔹 طلب ربط caregiver بالمريض
//   //     if (selectedType == 'caregiver') {
//   //       await _firestore.collection('caregiver_requests').add({
//   //         'caregiverUid': uid,
//   //         'patientUid': patientUid,
//   //         'caregiver_name': username.text.trim(),
//   //         'approved': false,
//   //         'createdAt': FieldValue.serverTimestamp(),
//   //       });
//   //     }

//   //     // ScaffoldMessenger.of(context).showSnackBar(
//   //     //   SnackBar(
//   //     //     content: Text(
//   //     //       "Account created successfully! Please verify your email.",
//   //     //     ),
//   //     //     backgroundColor: Colors.green,
//   //     //   ),
//   //     // );

//   //     // 🔹 الانتقال إلى صفحة Login
//   //     Navigator.pushReplacement(
//   //       context,
//   //       MaterialPageRoute(builder: (_) => Login()),
//   //     );

      
//   //   } on FirebaseAuthException catch (e) {
//   //     String message = '';
//   //     if (e.code == 'weak-password') {
//   //       message = "The password provided is too weak.";
//   //     } else if (e.code == 'email-already-in-use') {
//   //       message = "The account already exists for that email.";
//   //     } else {
//   //       message = "Error: ${e.message}";
//   //     }

//   //     // ScaffoldMessenger.of(context).showSnackBar(
//   //     //   SnackBar(
//   //     //     content: Text(message),
//   //     //     backgroundColor: Colors.red,
//   //     //   ),
//   //     // );
//   //   } catch (e) {
//   //     // ScaffoldMessenger.of(context).showSnackBar(
//   //     //   SnackBar(
//   //     //     content: Text("Unexpected error: $e"),
//   //     //     backgroundColor: Colors.red,
//   //     //   ),
//   //     // );
//   //   }
//   // }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: SafeArea(
//         child: Center(
//           child: SingleChildScrollView(
//             child: Container(
//               padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
//               width: MediaQuery.of(context).size.width * 0.9,
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.center,
//                 children: [
//                   IconAuth(),
//                   Form(
//                     key: formState,
//                     child: Column(
//                       children: [
//                         // Name
//                         CustomTextForm(
//                           labeltext: "Name",
//                           mycontroller: username,
//                           validator: (val) {
//                             if (val == "") return "*The Name is required";
//                           },
//                         ),
//                         SizedBox(height: 10),
//                         // Email
//                         TextFormField(
//                           controller: email,
//                           keyboardType: TextInputType.emailAddress,
//                           autofillHints: [AutofillHints.email],
//                           decoration: InputDecoration(
//                             labelText: "Email",
//                             filled: true,
//                             fillColor: Color(0xFFE1F3DF),
//                             border: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(10),
//                               borderSide: BorderSide.none,
//                             ),
//                           ),
//                           validator: (val) {
//                             if (val == "") return "*The email is required";
//                             bool emailValid = RegExp(
//                               r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
//                             ).hasMatch(val!);
//                             if (!emailValid) return "Please enter a valid email";
//                           },
//                         ),
//                         SizedBox(height: 10),
//                         // Password
//                         TextFormField(
//                           controller: password,
//                           obscureText: obsecur,
//                           decoration: InputDecoration(
//                             labelText: "Password",
//                             filled: true,
//                             fillColor: Color(0xFFE1F3DF),
//                             border: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(10),
//                               borderSide: BorderSide.none,
//                             ),
//                             suffixIcon: IconButton(
//                               icon: Icon(
//                                   obsecur ? Icons.visibility_off : Icons.visibility),
//                               onPressed: () {
//                                 setState(() {
//                                   obsecur = !obsecur;
//                                 });
//                               },
//                             ),
//                           ),
//                           validator: (val) {
//                             if (val == "") return "*The Password is required";
//                             if (val!.length < 8)
//                               return "Password too weak, min 8 chars";
//                             if (!RegExp(r'\d').hasMatch(val))
//                               return "Password must contain a number";
//                             if (!RegExp(r'[A-Z]').hasMatch(val))
//                               return "Password must contain an uppercase letter";
//                           },
//                         ),
//                         SizedBox(height: 10),
//                         // Confirm password
//                         TextFormField(
//                           controller: conform,
//                           obscureText: obsecur,
//                           decoration: InputDecoration(
//                             labelText: "Confirm Password",
//                             filled: true,
//                             fillColor: Color(0xFFE1F3DF),
//                             border: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(10),
//                               borderSide: BorderSide.none,
//                             ),
//                             suffixIcon: IconButton(
//                               icon: Icon(
//                                   obsecur ? Icons.visibility_off : Icons.visibility),
//                               onPressed: () {
//                                 setState(() {
//                                   obsecur = !obsecur;
//                                 });
//                               },
//                             ),
//                           ),
//                           validator: (val) {
//                             if (val != password.text)
//                               return "Passwords do not match";
//                           },
//                         ),
//                         SizedBox(height: 10),
//                         // Phone
//                         CustomTextForm(
//                           labeltext: "Phone Number",
//                           mycontroller: phone,
//                           validator: (val) {
//                             if (val == "") return "*The Phone is required";
//                             if (!RegExp(r'^[0-9]+$').hasMatch(val!))
//                               return "Phone must contain digits only";
//                           },
//                         ),
//                         SizedBox(height: 10),
//                         // Birth date
//                         TextFormField(
//                           controller: birthDateController,
//                           readOnly: true,
//                           decoration: InputDecoration(
//                             labelText: "Birth Date",
//                             filled: true,
//                             fillColor: Color(0xFFE1F3DF),
//                             border: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(10),
//                               borderSide: BorderSide.none,
//                             ),
//                             suffixIcon: Icon(Icons.calendar_today),
//                           ),
//                           validator: (val) {
//                             if (val == null || val.isEmpty)
//                               return "Please select your birth date";
//                           },
//                           onTap: () async {
//                             DateTime? pickedDate = await showDatePicker(
//                               context: context,
//                               initialDate: DateTime(2000),
//                               firstDate: DateTime(1900),
//                               lastDate: DateTime.now(),
//                             );

//                             if (pickedDate != null) {
//                               setState(() {
//                                 selectedBirthDate = pickedDate;
//                                 birthDateController.text =
//                                     "${pickedDate.day}/${pickedDate.month}/${pickedDate.year}";
//                               });
//                             }
//                           },
//                         ),
//                         SizedBox(height: 10),
//                         // User type
//                         DropdownButtonFormField<String>(
//                           decoration: InputDecoration(
//                             labelText: "Select User Type",
//                             border: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(10),
//                             ),
//                           ),
//                           items: userType
//                               .map((type) =>
//                                   DropdownMenuItem(value: type, child: Text(type)))
//                               .toList(),
//                           value: selectedType,
//                           onChanged: (val) {
//                             setState(() {
//                               selectedType = val;
//                             });
//                           },
//                           validator: (val) =>
//                               val == null ? "Please select your type" : null,
//                         ),
//                         SizedBox(height: 10),
//                         if (selectedType == "caregiver")
//                           TextFormField(
//                             controller: emailPatient,
//                             keyboardType: TextInputType.emailAddress,
//                             autofillHints: [AutofillHints.email],
//                             decoration: InputDecoration(
//                               labelText: "Patient's email",
//                               filled: true,
//                               fillColor: Color(0xFFE1F3DF),
//                               border: OutlineInputBorder(
//                                 borderRadius: BorderRadius.circular(10),
//                                 borderSide: BorderSide.none,
//                               ),
//                             ),
//                             validator: (val) {
//                               if (val == "") return "*The Patient's email is required";
//                               bool emailValid = RegExp(
//                                 r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
//                               ).hasMatch(val!);
//                               if (!emailValid)
//                                 return "Please enter a valid email address";
//                             },
//                           ),
//                         SizedBox(height: 20),
//                         SizedBox(
//                           width: double.infinity,
//                           child: CustomButton(
//                             title: "Sign Up",
//                             onPressed: signup,
//                           ),
//                         ),
//                         MaterialButton(
//                           onPressed: () {
//                             Navigator.of(context).pushReplacement(
//                               MaterialPageRoute(builder: (_) => Login()),
//                             );
//                           },
//                           child: Row(
//                             mainAxisAlignment: MainAxisAlignment.center,
//                             children: [
//                               Text(
//                                 "Have An Account?",
//                                 style: TextStyle(
//                                     color: Colors.black, fontWeight: FontWeight.bold),
//                               ),
//                               SizedBox(width: 10),
//                               Text(
//                                 "LogIn",
//                                 style: TextStyle(
//                                     color: Color(0xFF1C621B),
//                                     fontWeight: FontWeight.bold),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }










// // import 'package:cloud_firestore/cloud_firestore.dart';
// // import 'package:firebase_auth/firebase_auth.dart';
// // import 'package:first_app/component/buttonauth.dart';
// // import 'package:first_app/component/iconauth.dart';
// // import 'package:first_app/component/textformfield.dart';
// // import 'package:first_app/auth/login_page.dart';
// // import 'package:flutter/material.dart';

// // class SingUp extends StatefulWidget {
// //   const SingUp({super.key});

// //   @override
// //   State<SingUp> createState() => _SingUp();
// // }

// // class _SingUp extends State<SingUp> {
// //   String? selectedType;
// //   bool obsecur = true;

// //   TextEditingController username = TextEditingController();
// //   TextEditingController email = TextEditingController();
// //   TextEditingController emailPatient = TextEditingController();
// //   TextEditingController password = TextEditingController();
// //   TextEditingController conform = TextEditingController();
// //   TextEditingController phone = TextEditingController();
// //   DateTime? selectedBirthDate;
// //   TextEditingController birthDateController = TextEditingController();

// //   final GlobalKey<FormState> formState = GlobalKey<FormState>();

// //   String? errorMessage;
// //   final FirebaseFirestore _firestore = FirebaseFirestore.instance;

// //   final List<String> userType = ['patient', 'doctor', 'caregiver'];

// //   //================signup function======================
// //   Future<void> signup() async {
// //   if (!formState.currentState!.validate()) return;

// //   try {
// //     String? patientUid;

// //     // 🔹 التحقق من المريض إذا كان Caregiver
// //     if (selectedType == 'caregiver') {
// //       final query = await _firestore
// //           .collection('users')
// //           .where('email', isEqualTo: emailPatient.text.trim())
// //           .where('userType', isEqualTo: 'patient')
// //           .limit(1)
// //           .get();

// //       if (query.docs.isNotEmpty) {
// // //        scaffoldMessengerKey.currentState!.showSnackBar(
// // //   SnackBar(
// // //     content: Text(
// // //       "This patient email is not registered. Please ask the patient to sign up first.",
// // //     ),
// // //     backgroundColor: Colors.red,
// // //   ),
// // // );

// //         return; 
// //         // ⛔ إيقاف التسجيل
// //       }

// //       patientUid = query.docs.first.id;
// //     }

// //     // 🔹 إنشاء الحساب
// //     final credential =
// //         await FirebaseAuth.instance.createUserWithEmailAndPassword(
// //       email: email.text.trim(),
// //       password: password.text,
// //     );

// //     await credential.user!.sendEmailVerification();
// //     String uid = credential.user!.uid;

// //     // 🔹 حفظ المستخدم
// //     await _firestore.collection('users').doc(uid).set({
// //       'name': username.text.trim(),
// //       'phone': phone.text.trim(),
// //       'email': email.text.trim(),
// //       'userType': selectedType,
// //       'birthDate': selectedBirthDate?.toIso8601String(),
// //       'status': 1,
// //       'patientAccessApproved': selectedType == 'caregiver' ? false : true,
// //       'stage': 0,
// //       'stage_caregiver': 0,
// //       'stage_doctor': 0,
// //       'stage_system': 0,
// //       'createdAt': FieldValue.serverTimestamp(),
// //     });

// //     // 🔹 طلب ربط كيرجيفر بالمريض
// //     if (selectedType == 'caregiver') {
// //       await _firestore.collection('caregiver_requests').add({
// //         'caregiverUid': uid,
// //         'patientUid': patientUid,
// //         'caregiver_name': username.text.trim(),
// //         'approved': false,
// //         'createdAt': FieldValue.serverTimestamp(),
// //       });
// //     }

// //     Navigator.pushReplacement(
// //       context,
// //       MaterialPageRoute(builder: (_) => Login()),
// //     );
// //   } catch (e) {
// //     print(e);
// //   }
// // }

// //   // Future<void> signup() async {
// //   //   if (formState.currentState!.validate()) {
// //   //     try {
// //   //       String? patientUid;

// //   //       if (selectedType == 'caregiver') {
// //   //         final query =
// //   //             await _firestore
// //   //                 .collection('users')
// //   //                 .where('email', isEqualTo: emailPatient.text.trim())
// //   //                 .where('userType', isEqualTo: 'patient')
// //   //                 .limit(1)
// //   //                 .get();

// //   //          if (query.docs.isEmpty) {
          
// //   //   ScaffoldMessenger.of(context).showSnackBar(
// //   //     SnackBar(
// //   //       content: Text(
// //   //         "This patient email is not registered. Please ask the patient to sign up first.",
// //   //       ),
// //   //       backgroundColor: Colors.red,
// //   //     ),
// //   //   );
// //   //   return; // ⛔ أوقفي التسجيل
// //   // }}

// //   //       final credential = await FirebaseAuth.instance
// //   //           .createUserWithEmailAndPassword(
// //   //             email: email.text.trim(),
// //   //             password: password.text,
// //   //           );

// //   //       await credential.user!.sendEmailVerification();

// //   //       String uid = credential.user!.uid;

// //   //       await _firestore.collection('users').doc(uid).set({
// //   //         'name': username.text.trim(),
// //   //         'phone': phone.text.trim(),
// //   //         'email': email.text.trim(),
// //   //         'userType': selectedType,
// //   //         'birthDate': selectedBirthDate?.toIso8601String(),
// //   //         'status': 1,
// //   //         'patientAccessApproved': selectedType == 'caregiver' ? false : true,
// //   //         'stage': 0,
// //   //         'stage_caregiver': 0,
// //   //         'stage_doctor': 0,
// //   //         'stage_system': 0,
// //   //         'createdAt': FieldValue.serverTimestamp(),
// //   //       });

// //   //       // if (selectedType == 'caregiver') {
// //   //       //   final query =
// //   //       //       await _firestore
// //   //       //           .collection('users')
// //   //       //           .where('email', isEqualTo: emailPatient.text.trim())
// //   //       //           .where('userType', isEqualTo: 'patient')
// //   //       //           .get();

// //   //       //   if (query.docs.isEmpty) {
// //   //       //     setState(() {
// //   //       //       errorMessage =
// //   //       //           "This patient email is not registered. Please ask the patient to sign up first.";
// //   //       //     });
// //   //       //   } else {
// //   //       //     String patientUid = query.docs.first.id;

// //   //       //     await _firestore.collection('caregiver_requests').add({
// //   //       //       'caregiverUid': uid,
// //   //       //       'patientUid': patientUid,
// //   //       //       'caregiver_name': username.text.trim(),
// //   //       //       'approved': false,
// //   //       //       'createdAt': FieldValue.serverTimestamp(),
// //   //       //     });
// //   //       //   }
// //   //       // }
// //   //       if (selectedType == 'caregiver') {
// //   //         await _firestore.collection('caregiver_requests').add({
// //   //           'caregiverUid': uid,
// //   //           'patientUid': patientUid,
// //   //           'caregiver_name': username.text.trim(),
// //   //           'approved': false,
// //   //           'createdAt': FieldValue.serverTimestamp(),
// //   //         });
// //   //       }

// //   //       ///////////////Login
// //   //       Navigator.of(
// //   //         context,
// //   //       ).pushReplacement(MaterialPageRoute(builder: (context) => Login()));

// //   //       print("=============================User signed up successfully!");
// //   //     } on FirebaseAuthException catch (e) {
// //   //       if (e.code == 'weak-password') {
// //   //         setState(() {
// //   //           errorMessage = "The password provided is too weak.";
// //   //         });
// //   //       } else if (e.code == 'email-already-in-use') {
// //   //         setState(() {
// //   //           errorMessage = "The account already exists for that email.";
// //   //         });
// //   //       }
// //   //     } catch (e) {
// //   //       print(e);
// //   //     }
// //   //   }
// //   // }
  


// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       backgroundColor: Colors.white,
// //       body: SafeArea(
// //         child: Center(
// //           child: SingleChildScrollView(
// //             child: Container(
// //               padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
// //               width: MediaQuery.of(context).size.width * 0.9,
// //               child: Column(
// //                 crossAxisAlignment: CrossAxisAlignment.center,
// //                 children: [
// //                   IconAuth(),
// //                   Form(
// //                     key: formState,
// //                     child: Column(
// //                       children: [
// //                         if (errorMessage != null)
// //                           Padding(
// //                             padding: EdgeInsets.only(top: 5),
// //                             child: Text(
// //                               errorMessage!,
// //                               style: TextStyle(fontSize: 16, color: Colors.red),
// //                             ),
// //                           ),
// //                         SizedBox(height: 20),
// //                         CustomTextForm(
// //                           validator: (val) {
// //                             if (val == "") return "*The Name is required";
// //                           },
// //                           labeltext: "Name",
// //                           mycontroller: username,
// //                         ),
// //                         SizedBox(height: 10),
// //                         TextFormField(
// //                           validator: (val) {
// //                             if (val == "") return "*The email is required";
// //                             bool emailValid = RegExp(
// //                               r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
// //                             ).hasMatch(val!);
// //                             if (!emailValid)
// //                               return "Please enter a valid email";
// //                           },
// //                           controller: email,
// //                           keyboardType: TextInputType.emailAddress,
// //                           autofillHints: [AutofillHints.email],
// //                           decoration: InputDecoration(
// //                             labelText: "Email",
// //                             filled: true,
// //                             fillColor: Color(0xFFE1F3DF),
// //                             border: OutlineInputBorder(
// //                               borderRadius: BorderRadius.circular(10),
// //                               borderSide: BorderSide.none,
// //                             ),
// //                           ),
// //                         ),
// //                         SizedBox(height: 10),
// //                         TextFormField(
// //                           validator: (val) {
// //                             if (val == "") return "*The Password is required";
// //                             if (val!.length < 8)
// //                               return "Password is too weak. Use at least 8 characters";
// //                             if (!RegExp(r'\d').hasMatch(val))
// //                               return "Password is too weak. Use at least one number";
// //                             if (!RegExp(r'[A-Z]').hasMatch(val))
// //                               return "Password is too weak. Use at least one uppercase letter";
// //                           },
// //                           controller: password,
// //                           obscureText: obsecur,
// //                           decoration: InputDecoration(
// //                             suffixIcon: IconButton(
// //                               icon: Icon(
// //                                 obsecur
// //                                     ? Icons.visibility_off
// //                                     : Icons.visibility,
// //                               ),
// //                               onPressed: () {
// //                                 setState(() {
// //                                   obsecur = !obsecur;
// //                                 });
// //                               },
// //                             ),
// //                             labelText: "Password",
// //                             filled: true,
// //                             fillColor: Color(0xFFE1F3DF),
// //                             border: OutlineInputBorder(
// //                               borderRadius: BorderRadius.circular(10),
// //                               borderSide: BorderSide.none,
// //                             ),
// //                           ),
// //                         ),
// //                         SizedBox(height: 10),
// //                         TextFormField(
// //                           validator: (val) {
// //                             if (password.text != val)
// //                               return "The Conform Password is not matching";
// //                           },
// //                           controller: conform,
// //                           obscureText: obsecur,
// //                           decoration: InputDecoration(
// //                             suffixIcon: IconButton(
// //                               icon: Icon(
// //                                 obsecur
// //                                     ? Icons.visibility_off
// //                                     : Icons.visibility,
// //                               ),
// //                               onPressed: () {
// //                                 setState(() {
// //                                   obsecur = !obsecur;
// //                                 });
// //                               },
// //                             ),
// //                             labelText: "Confirm Password",
// //                             filled: true,
// //                             fillColor: Color(0xFFE1F3DF),
// //                             border: OutlineInputBorder(
// //                               borderRadius: BorderRadius.circular(10),
// //                               borderSide: BorderSide.none,
// //                             ),
// //                           ),
// //                         ),
// //                         SizedBox(height: 10),
// //                         CustomTextForm(
// //                           validator: (val) {
// //                             if (val == "") return "*The Phone is required";
// //                             if (!RegExp(r'^[0-9]+$').hasMatch(val!))
// //                               return "Phone number must contain digits only";
// //                           },
// //                           labeltext: "Phone Number",
// //                           mycontroller: phone,
// //                         ),
// //                         SizedBox(height: 10),
// //                         TextFormField(
// //                           controller: birthDateController,
// //                           readOnly: true,
// //                           decoration: InputDecoration(
// //                             labelText: "Birth Date",
// //                             filled: true,
// //                             fillColor: Color(0xFFE1F3DF),
// //                             border: OutlineInputBorder(
// //                               borderRadius: BorderRadius.circular(10),
// //                               borderSide: BorderSide.none,
// //                             ),
// //                             suffixIcon: Icon(Icons.calendar_today),
// //                           ),
// //                           validator: (val) {
// //                             if (val == null || val.isEmpty)
// //                               return "Please select your birth date";
// //                             return null;
// //                           },
// //                           onTap: () async {
// //                             DateTime? pickedDate = await showDatePicker(
// //                               context: context,
// //                               initialDate: DateTime(2000),
// //                               firstDate: DateTime(1900),
// //                               lastDate: DateTime.now(),
// //                             );

// //                             if (pickedDate != null) {
// //                               setState(() {
// //                                 selectedBirthDate = pickedDate;
// //                                 birthDateController.text =
// //                                     "${pickedDate.day}/${pickedDate.month}/${pickedDate.year}";
// //                               });
// //                             }
// //                           },
// //                         ),
// //                         SizedBox(height: 10),
// //                         DropdownButtonFormField<String>(
// //                           decoration: InputDecoration(
// //                             labelText: "Select User Type",
// //                             border: OutlineInputBorder(
// //                               borderRadius: BorderRadius.circular(10),
// //                             ),
// //                           ),
// //                           items:
// //                               userType
// //                                   .map(
// //                                     (type) => DropdownMenuItem(
// //                                       value: type,
// //                                       child: Text(type),
// //                                     ),
// //                                   )
// //                                   .toList(),
// //                           value: selectedType,
// //                           onChanged: (val) {
// //                             setState(() {
// //                               selectedType = val;
// //                             });
// //                           },
// //                           validator:
// //                               (value) =>
// //                                   value == null
// //                                       ? "Please select your Type"
// //                                       : null,
// //                         ),
// //                         if (selectedType == "caregiver")
// //                           Padding(
// //                             padding: const EdgeInsets.all(8.0),
// //                             child: TextFormField(
// //                               validator: (val) {
// //                                 if (val == "")
// //                                   return "*The Patient's email is required";
// //                                 bool emailValid = RegExp(
// //                                   r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
// //                                 ).hasMatch(val!);
// //                                 if (!emailValid)
// //                                   return "Please enter a valid email address";
// //                                 return null;
                               
// //                               },
// //                               controller: emailPatient,
// //                               keyboardType: TextInputType.emailAddress,
// //                               autofillHints: [AutofillHints.email],
// //                               decoration: InputDecoration(
// //                                 labelText: "Patient's email",
// //                                 filled: true,
// //                                 fillColor: Color(0xFFE1F3DF),
// //                                 border: OutlineInputBorder(
// //                                   borderRadius: BorderRadius.circular(10),
// //                                   borderSide: BorderSide.none,
// //                                 ),
// //                               ),
// //                             ),
// //                           ),
// //                         SizedBox(height: 20),
// //                         SizedBox(
// //                           width: double.infinity,
// //                           child: CustomButton(
// //                             title: "Sign Up",
// //                             onPressed: () async {
// //                               signup();
// //                             },
// //                           ),
// //                         ),
// //                         MaterialButton(
// //                           onPressed: () {
// //                             Navigator.of(context).pushReplacement(
// //                               MaterialPageRoute(builder: (context) => Login()),
// //                             );
// //                           },
// //                           child: Row(
// //                             children: [
// //                               Text(
// //                                 "Have An Account ?",
// //                                 style: TextStyle(
// //                                   color: Colors.black,
// //                                   fontSize: 15,
// //                                   fontWeight: FontWeight.bold,
// //                                 ),
// //                               ),
// //                               SizedBox(width: 10),
// //                               Text(
// //                                 "LogIn",
// //                                 style: TextStyle(
// //                                   color: Color(0xFF1C621B),
// //                                   fontSize: 15,
// //                                   fontWeight: FontWeight.bold,
// //                                 ),
// //                               ),
// //                             ],
// //                           ),
// //                         ),
// //                       ],
// //                     ),
// //                   ),
// //                 ],
// //               ),
// //             ),
// //           ),
// //         ),
// //       ),
// //     );
// //   }
// // }




















// // // import 'package:cloud_firestore/cloud_firestore.dart';
// // // import 'package:firebase_auth/firebase_auth.dart';
// // // import 'package:first_app/component/buttonauth.dart';
// // // import 'package:first_app/component/iconauth.dart';
// // // import 'package:first_app/component/textformfield.dart';
// // // import 'package:first_app/auth/login_page.dart';
// // // import 'package:flutter/material.dart';

// // // class SingUp extends StatefulWidget {
// // //   const SingUp({super.key});

// // //   @override
// // //   State<SingUp> createState() => _SingUp();
// // // }

// // // class _SingUp extends State<SingUp> {
// // //   String? typeUser;
// // //   String? selectedType;
// // //   bool obsecur = true;
// // //   TextEditingController username = TextEditingController();
// // //   TextEditingController email = TextEditingController();
// // //   TextEditingController emailPatient = TextEditingController();
// // //   TextEditingController password = TextEditingController();
// // //   TextEditingController conform = TextEditingController();
// // //   TextEditingController phone = TextEditingController();
// // //   TextEditingController typeuser = TextEditingController();
// // //   GlobalKey<FormState> formState = GlobalKey<FormState>();
// // //   DateTime? selectedBirthDate;
// // //   TextEditingController birthDateController = TextEditingController();
// // //   String? errorMessage;
// // //   final FirebaseFirestore _firestore = FirebaseFirestore.instance;

// // //   final List<String> userType = ['patient', 'doctor', 'caregiver'];
// // //   //================signup function======================
// // //   Future<void> signup() async {
// // //     if (formState.currentState!.validate()) {
// // //       try {
// // //         final credential = await FirebaseAuth.instance
// // //             .createUserWithEmailAndPassword(
// // //               email: email.text,
// // //               password: password.text,
// // //             );
// // //         FirebaseAuth.instance.currentUser!.sendEmailVerification();

// // //         String? patientUid;

      

// // //         await FirebaseAuth.instance.currentUser!.reload();

// // //         String uid = credential.user!.uid;

// // //         //creat collection "users"

// // //         await _firestore.collection('users').doc(uid).set({
// // //           'name': username.text,
// // //           'phone': phone.text,
// // //           'email': email.text,
// // //           'userType': selectedType,
// // //           'birthDate': selectedBirthDate?.toIso8601String(),
// // //           'status': 1,
// // //           'patientAccessApproved': selectedType == 'caregiver' ? false : true,

// // //           //evaluation the patient
// // //           'stage': 0,
// // //           'stage_caregiver': 0,
// // //           'stage_doctor': 0,
// // //           'stage_system': 0,

// // //           'createdAt': FieldValue.serverTimestamp(),
// // //         });

// // //   if (selectedType == 'caregiver') {
// // //           final query =
// // //               await _firestore
// // //                   .collection('users')
// // //                   .where('email', isEqualTo: emailPatient.text.trim())
// // //                   .where('userType', isEqualTo: 'patient')
// // //                   .get();

// // //           if (query.docs.isEmpty) {
// // //             setState(() {
// // //               errorMessage = "Patient not found. Please check the email.";
// // //             });
// // //             await credential.user!.delete();
// // //             return; // ❗ يوقف التسجيل
// // //           }

// // //           patientUid = query.docs.first.id;
          

// // //           await _firestore.collection('caregiver_requests').add({
// // //     'caregiverUid': FirebaseAuth.instance.currentUser,      // الكيرجيفر
// // //     'patientUid': patientUid, // المريض
// // //     'approved': false,
// // //     'createdAt': FieldValue.serverTimestamp(),
// // //   });
// // //         }
        
// // //         // //ربط المريض بالكيرجيفر
// // //         // if (selectedType == 'caregiver') {
// // //         //   await _firestore.collection('users').doc(patientUid).update({
// // //         //     'caregivers': FieldValue.arrayUnion([uid]),
// // //         //   });
// // //         // }

// // //         Navigator.of(
// // //           context,
// // //         ).pushReplacement(MaterialPageRoute(builder: (context) => Login()));

// // //         print("=============================User signed up and data saved!");
// // //       } on FirebaseAuthException catch (e) {
// // //         if (e.code == 'weak-password') {
// // //           setState(() {
// // //             errorMessage = "The password provided is too weak.";
// // //           });
// // //         } else if (e.code == 'email-already-in-use') {
// // //           setState(() {
// // //             errorMessage = "The account already exists for that email.";
// // //           });
// // //         }
// // //       } catch (e) {
// // //         print(e);
// // //       }
// // //     }
// // //   }

// // //   @override
// // //   Widget build(BuildContext context) {
// // //     return Scaffold(
// // //       backgroundColor: Color.fromARGB(255, 255, 255, 255),
// // //       body: SafeArea(
// // //         child: Center(
// // //           child: SingleChildScrollView(
// // //             child: Container(
// // //               padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
// // //               width: MediaQuery.of(context).size.width * 0.9,
// // //               decoration: BoxDecoration(
// // //                 color: Color.fromARGB(255, 255, 255, 255),
// // //               ),

// // //               child: Column(
// // //                 crossAxisAlignment: CrossAxisAlignment.center,

// // //                 children: [
// // //                   IconAuth(),

// // //                   Form(
// // //                     key: formState,
// // //                     child: Column(
// // //                       children: [
// // //                         if (errorMessage != null)
// // //                           Padding(
// // //                             padding: EdgeInsets.only(top: 5),
// // //                             child: Text(
// // //                               errorMessage!,
// // //                               style: TextStyle(fontSize: 16, color: Colors.red),
// // //                             ),
// // //                           ),
// // //                         SizedBox(height: 20),
// // //                         //----------------Name Field--------------------------------------
// // //                         CustomTextForm(
// // //                           validator: (val) {
// // //                             if (val == "") {
// // //                               return "*The Name is required";
// // //                             }
// // //                           },
// // //                           labeltext: "Name",
// // //                           mycontroller: username,
// // //                         ),

// // //                         SizedBox(height: 10),

// // //                         //------------------------email Field-------------------------------
// // //                         TextFormField(
// // //                           validator: (val) {
// // //                             if (val == "") {
// // //                               return "*The email is required";
// // //                             }
// // //                             bool emailValid = RegExp(
// // //                               r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
// // //                             ).hasMatch(val!);

// // //                             if (!emailValid) {
// // //                               return "Please enter a valid email address";
// // //                             }
// // //                           },
// // //                           controller: email,
// // //                           keyboardType: TextInputType.emailAddress,
// // //                           autofillHints: [AutofillHints.email],
// // //                           decoration: InputDecoration(
// // //                             labelText: "ُEmail",
// // //                             filled: true,
// // //                             fillColor: Color(0xFFE1F3DF),
// // //                             border: OutlineInputBorder(
// // //                               borderRadius: BorderRadius.circular(10),
// // //                               borderSide: BorderSide.none,
// // //                             ),
// // //                           ),
// // //                         ),

// // //                         SizedBox(height: 10),
// // //                         //-------------password Field-------------------------------------
// // //                         TextFormField(
// // //                           validator: (val) {
// // //                             if (val == "") {
// // //                               return "*The Password is required";
// // //                             }
// // //                             if (val!.length < 8) {
// // //                               return "Password is too weak.Use at least 8 characters";
// // //                             }
// // //                             if (!RegExp(r'\d').hasMatch(val)) {
// // //                               return "Password is too weak.Use at least one number";
// // //                             }
// // //                             if (!RegExp(r'[A-Z]').hasMatch(val)) {
// // //                               return "Password is too weak.Use at least one uppercase letter";
// // //                             }
// // //                           },
// // //                           controller: password,
// // //                           obscureText: obsecur,

// // //                           decoration: InputDecoration(
// // //                             suffixIcon: IconButton(
// // //                               icon: Icon(
// // //                                 obsecur
// // //                                     ? Icons.visibility_off
// // //                                     : Icons.visibility,
// // //                               ),
// // //                               onPressed: () {
// // //                                 setState(() {
// // //                                   obsecur = !obsecur;
// // //                                 });
// // //                               },
// // //                             ),
// // //                             labelText: "Password",
// // //                             filled: true,
// // //                             fillColor: Color(0xFFE1F3DF),
// // //                             border: OutlineInputBorder(
// // //                               borderRadius: BorderRadius.circular(10),
// // //                               borderSide: BorderSide.none,
// // //                             ),
// // //                           ),
// // //                         ),

// // //                         SizedBox(height: 10),
// // //                         //--------------------Conform Password Field-----------------------
// // //                         TextFormField(
// // //                           validator: (val) {
// // //                             if (password.text != val) {
// // //                               return "The Conform Password is not maching";
// // //                             }
// // //                           },
// // //                           controller: conform,
// // //                           obscureText: obsecur,

// // //                           decoration: InputDecoration(
// // //                             suffixIcon: IconButton(
// // //                               icon: Icon(
// // //                                 obsecur
// // //                                     ? Icons.visibility_off
// // //                                     : Icons.visibility,
// // //                               ),
// // //                               onPressed: () {
// // //                                 setState(() {
// // //                                   obsecur = !obsecur;
// // //                                 });
// // //                               },
// // //                             ),
// // //                             labelText: "Conform Password",
// // //                             filled: true,
// // //                             fillColor: Color(0xFFE1F3DF),
// // //                             border: OutlineInputBorder(
// // //                               borderRadius: BorderRadius.circular(10),
// // //                               borderSide: BorderSide.none,
// // //                             ),
// // //                           ),
// // //                         ),

// // //                         SizedBox(height: 10),
// // //                         //-------------------Phone field--------------------------------
// // //                         CustomTextForm(
// // //                           validator: (val) {
// // //                             if (val == "") {
// // //                               return "*The Phone is required";
// // //                             }
// // //                             if (!RegExp(r'^[0-9]+$').hasMatch(val!)) {
// // //                               return "Phone number must contain digits only";
// // //                             }
// // //                           },
// // //                           labeltext: "Phone Number",
// // //                           mycontroller: phone,
// // //                         ),
// // //                         SizedBox(height: 10),

// // //                         //================== Birth Date Field ==================
// // //                         TextFormField(
// // //                           controller: birthDateController,
// // //                           readOnly: true,
// // //                           decoration: InputDecoration(
// // //                             labelText: "Birth Date",
// // //                             filled: true,
// // //                             fillColor: Color(0xFFE1F3DF),
// // //                             border: OutlineInputBorder(
// // //                               borderRadius: BorderRadius.circular(10),
// // //                               borderSide: BorderSide.none,
// // //                             ),
// // //                             suffixIcon: Icon(Icons.calendar_today),
// // //                           ),
// // //                           validator: (val) {
// // //                             if (val == null || val.isEmpty) {
// // //                               return "Please select your birth date";
// // //                             }
// // //                             return null;
// // //                           },
// // //                           onTap: () async {
// // //                             DateTime? pickedDate = await showDatePicker(
// // //                               context: context,
// // //                               initialDate: DateTime(2000),
// // //                               firstDate: DateTime(1900),
// // //                               lastDate: DateTime.now(),
// // //                             );

// // //                             if (pickedDate != null) {
// // //                               setState(() {
// // //                                 selectedBirthDate = pickedDate;
// // //                                 birthDateController.text =
// // //                                     "${pickedDate.day}/${pickedDate.month}/${pickedDate.year}";
// // //                               });
// // //                             }
// // //                           },
// // //                         ),
// // //                         SizedBox(height: 10),

// // //                         //-------------------user Types--------------------------------
// // //                         DropdownButtonFormField<String>(
// // //                           decoration: InputDecoration(
// // //                             labelText: "Select User Type",
// // //                             border: OutlineInputBorder(
// // //                               borderRadius: BorderRadius.circular(10),
// // //                             ),
// // //                           ),
// // //                           items:
// // //                               userType
// // //                                   .map(
// // //                                     (type) => DropdownMenuItem(
// // //                                       value: type,
// // //                                       child: Text(type),
// // //                                     ),
// // //                                   )
// // //                                   .toList(),
// // //                           value: selectedType,
// // //                           onChanged: (val) {
// // //                             setState(() {
// // //                               selectedType = val;
// // //                             });
// // //                           },
// // //                           validator:
// // //                               (value) =>
// // //                                   value == null
// // //                                       ? "Please select your Type"
// // //                                       : null,
// // //                         ),
// // //                         if (selectedType == "caregiver")
// // //                         //   //------------------------patient email Field-------------------------------
// // //                           Padding(
// // //                             padding: const EdgeInsets.all(8.0),
// // //                             child: TextFormField(
// // //                               validator: (val) {
// // //                                 if (val == "") {
// // //                                   return "*The Patient's email is required";
// // //                                 }
// // //                                 bool emailValid = RegExp(
// // //                                   r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
// // //                                 ).hasMatch(val!);

// // //                                 if (!emailValid) {
// // //                                   return "Please enter a valid email address";
// // //                                 }
// // //                               },
// // //                               controller: emailPatient,
// // //                               keyboardType: TextInputType.emailAddress,
// // //                               autofillHints: [AutofillHints.email],
// // //                               decoration: InputDecoration(
// // //                                 labelText: "ُPatient's email",
// // //                                 filled: true,
// // //                                 fillColor: Color(0xFFE1F3DF),
// // //                                 border: OutlineInputBorder(
// // //                                   borderRadius: BorderRadius.circular(10),
// // //                                   borderSide: BorderSide.none,
// // //                                 ),
// // //                               ),
// // //                             ),
// // //                           ),

// // //                         SizedBox(height: 20),
// // //                         //========sign up button========================================
// // //                         SizedBox(
// // //                           width: double.infinity,
// // //                           child: CustomButton(
// // //                             title: "Sing Up",
// // //                             onPressed: () async {
// // //                               signup();
// // //                             },
// // //                           ),
// // //                         ),
// // //                         //-----------------to login page--------------------------------------
// // //                         MaterialButton(
// // //                           onPressed: () {
// // //                             Navigator.of(context).pushReplacement(
// // //                               MaterialPageRoute(builder: (context) => Login()),
// // //                             );
// // //                           },
// // //                           child: Row(
// // //                             children: [
// // //                               Text(
// // //                                 "Have An Account ?",

// // //                                 style: TextStyle(
// // //                                   color: Color.fromARGB(255, 0, 0, 0),
// // //                                   fontSize: 15,
// // //                                   fontWeight: FontWeight.bold,
// // //                                 ),
// // //                               ),
// // //                               SizedBox(width: 10),
// // //                               Text(
// // //                                 "LogIn",

// // //                                 style: TextStyle(
// // //                                   color: Color(0xFF1C621B),
// // //                                   fontSize: 15,
// // //                                   fontWeight: FontWeight.bold,
// // //                                 ),
// // //                               ),
// // //                             ],
// // //                           ),
// // //                         ),
// // //                       ],
// // //                     ),
// // //                   ),
// // //                 ],
// // //               ),
// // //             ),
// // //           ),
// // //         ),
// // //       ),
// // //     );
// // //   }
// // // }

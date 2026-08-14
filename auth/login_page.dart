import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:first_app/component/buttonauth.dart';
import 'package:first_app/component/iconauth.dart';
import 'package:first_app/component/textformfield.dart';
import 'package:flutter/material.dart';
import 'package:first_app/navbar/navigator_page.dart';
import 'package:first_app/auth/sing_up_page.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _Login();
}

class _Login extends State<Login> {
  TextEditingController emaill = TextEditingController();
  bool obsecur = true;
  TextEditingController passwordd = TextEditingController();
  GlobalKey<FormState> formState = GlobalKey<FormState>();
  String? errorMessage;
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 255, 255, 255),
      body:
          isLoading
              ? Center(child: CircularProgressIndicator())
              : SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 10,
                      ),
                      width: MediaQuery.of(context).size.width * 0.9,
                      decoration: BoxDecoration(
                        color: Color.fromARGB(255, 255, 255, 255),
                      ),

                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,

                        children: [
                          //Ad Care System-------------------------
                         IconAuth(),
                          SizedBox(height: 50),
                          Form(
                            key: formState,
                            child: Column(
                              children: [
                                Text(
                                  "Enter your email to sign in for this app",
                                  style: TextStyle(
                                    color: Colors.black54,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(height: 20),
                                //----------------Text Email-------------------------------------------------------------
                                CustomTextForm(
                                  labeltext: "Email",
                                  mycontroller: emaill,

                                  validator: (val) {
                                    if (val == "") {
                                      return "*The Email is required";
                                    }
                                  },
                                ),

                                SizedBox(height: 10),
                                //---------------------------------Text Password------------------------------------------------
                                TextFormField(
                                  validator: (val) {
                                    if (val == "") {
                                      return "*The Password is required";
                                    }
                                  },
                                  controller: passwordd,
                                  obscureText: obsecur,

                                  decoration: InputDecoration(
                                    //---------------------Eyes Icon-----------------------------------------------
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

                                if (errorMessage != null)
                                  Padding(
                                    padding: EdgeInsets.only(top: 5),
                                    child: Text(
                                      errorMessage!,
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.red,
                                      ),
                                    ),
                                  ),
                                //-------------forget password Button---------------------------------------------
                                SizedBox(height: 7),
                                InkWell(
                                  onTap: () async {
                                    if (emaill.text == "") {
                                      AwesomeDialog(
                                        context: context,
                                        dialogType: DialogType.warning,
                                        animType: AnimType.rightSlide,
                                        title: "Enter your Email",
                                        desc:
                                            "Please enter your email address and then click on Forget Password.",
                                      ).show();
                                      return;
                                    }
                                    //==================forget password function=======================================================================
                                    try {
                                      await FirebaseAuth.instance
                                          .sendPasswordResetEmail(
                                            email: emaill.text,
                                          );
                                      AwesomeDialog(
                                        context: context,
                                        dialogType: DialogType.success,
                                        animType: AnimType.rightSlide,
                                        title: "Reset your password",
                                        desc:
                                            "A link has been sent to your email, Please go to your email and reset your password.",
                                      ).show();
                                    } catch (e) {
                                      print(e);
                                      setState(() {
                                        errorMessage =
                                            "Please make sure your email address is correct and then try again.";
                                      });
                                    }
                                  },
                                  //-----------------------forget Pssword------------------------------------------------------
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: Text(
                                      "Forget the password?",
                                      style: TextStyle(
                                        color: Color(0xFF1C621B),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(height: 20),
                                //=============================Login button==================================
                                SizedBox(
                                  width: double.infinity,
                                  child: CustomButton(
                                    
                                    title: "Login",
                                    onPressed: () async {
                                      if (formState.currentState!.validate()) {
                                        try {
                                          // isLoading=true;
                                          // setState(() {

                                          // });
                                          final credential = await FirebaseAuth
                                              .instance
                                              .signInWithEmailAndPassword(
                                                email: emaill.text.trim(),
                                                password: passwordd.text.trim(),
                                              );
                                          setState(() {
                                            errorMessage = null;
                                          });
                                          // isLoading=false;
                                          // setState(() {

                                          // });

                                          if (credential.user!.emailVerified) {
                                            Navigator.of(
                                              context,
                                            ).pushReplacement(
                                              MaterialPageRoute(
                                                builder:
                                                    (context) =>
                                                        NavigatorPage(),
                                              ),
                                            );
                                          } else {
                                            FirebaseAuth.instance.currentUser!
                                                .sendEmailVerification();

                                            setState(() {
                                              errorMessage =
                                                  "pleas Verified email";
                                            });
                                          }
                                        } on FirebaseAuthException catch (e) {
                                          // isLoading=false;
                                          // setState(() {

                                          // });
                                          if (e.code == 'user-not-found') {
                                            setState(() {
                                              errorMessage =
                                                  "No user found for that email.";
                                            });
                                          } else if (e.code ==
                                              'invalid-credential') {
                                            setState(() {
                                              errorMessage =
                                                  "Invalid email or password.";
                                            });
                                          } else {
                                            setState(() {
                                              errorMessage =
                                                  "Invalid email or password.";
                                            });
                                          }
                                        } catch (e) {
                                          setState(() {
                                            errorMessage =
                                                "Something went worng. Try again later.";
                                          });
                                        }
                                      }
                                    },
                                  ),
                                ),
                                SizedBox(height: 8),
                                //----------------Login with google-----------------------------------------------
                                // SizedBox(
                                //   width: double.infinity,

                                //   child: MaterialButton(
                                //     onPressed: () async {
                                //       // await signInWithGoogle();
                                //     },

                                //     color: Color(0xFF1C621B),
                                //     padding: EdgeInsets.symmetric(vertical: 10),
                                //     shape: RoundedRectangleBorder(
                                //       borderRadius: BorderRadius.circular(10),
                                //     ),
                                //     child: Row(
                                //       mainAxisAlignment: MainAxisAlignment.center,
                                //       children: [
                                //         Text(
                                //           "Login with Google",
                                //           style: TextStyle(
                                //             fontWeight: FontWeight.bold,
                                //             color: Colors.white,
                                //             fontSize: 18,
                                //           ),
                                //         ),
                                //         Align(
                                //           child: Image.asset(
                                //             "images/googleIcon.PNG",
                                //             width: 30,
                                //             height: 30,
                                //           ),
                                //         ),
                                //       ],
                                //     ),
                                //   ),
                                // ),
                                SizedBox(height: 15),
                                //------------------------to Register----------------------------------------
                                MaterialButton(
                                  onPressed: () {
                                    Navigator.of(context).pushReplacement(
                                      MaterialPageRoute(
                                        builder: (context) => SingUp(),
                                      ),
                                    );
                                  },
                                  child: Row(
                                    children: [
                                      Text(
                                        "Don't Have An Account ?",

                                        style: TextStyle(
                                          color: Color.fromARGB(255, 0, 0, 0),
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(width: 10),
                                      Text(
                                        "Register",

                                        style: TextStyle(
                                          color: Color(0xFF1C621B),
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                SizedBox(height: 30),
                                //-----------------------------Privacy Policy------------------------------------------
                                Text(
                                  "By clicking continue, you agree to our Terms of Service and Privacy Policy",
                                  style: TextStyle(
                                    color: Color(0xFF1C621B),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
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

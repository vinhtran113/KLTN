import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitness_workout_app/common/colo_extension.dart';
import 'package:fitness_workout_app/common_widget/round_button.dart';
import 'package:fitness_workout_app/common_widget/round_textfield.dart';
import 'package:fitness_workout_app/view/login/complete_profile_view.dart';
import 'package:fitness_workout_app/view/login/login_view.dart';
import 'package:fitness_workout_app/view/login/welcome_view.dart';
import 'package:fitness_workout_app/view/login/what_your_goal_view.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:fitness_workout_app/services/auth.dart';
import '../setting/PrivacyPolicy_and_TermOfUse_View.dart';
import 'package:fitness_workout_app/model/user_model.dart';

class SignUpView extends StatefulWidget {
  const SignUpView({super.key});

  @override
  State<SignUpView> createState() => _SignUpViewState();
}

class _SignUpViewState extends State<SignUpView> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController fnameController = TextEditingController();
  final TextEditingController lnameController = TextEditingController();
  bool isCheck = false;
  bool obscureText = true;
  bool isLoading = false;

  @override
  void dispose() {
    super.dispose();
    emailController.dispose();
    passwordController.dispose();
    fnameController.dispose();
    lnameController.dispose();
  }

  void handleSignup() async {
    try {
      setState(() {
        isLoading = true;
      });
      String res = await AuthService().signupUser(
        email: emailController.text,
        password: passwordController.text,
        fname: fnameController.text,
        lname: lnameController.text,
      );

      if (res == "success") {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => const CompleteProfileView(),
          ),
              (route) => false,
        );
        setState(() {
          isLoading = false;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $res')),
        );
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi xảy ra: $e')),
      );
      setState(() {
        isLoading = false;
      });
    }
  }

  void handleSignupWithGG() async {
    setState(() {
      isLoading = true;
    });

    try {
      String res = await AuthService().signInWithGoogle();

      switch (res) {
        case "success":
          UserModel? user = await AuthService().getUserInfo(FirebaseAuth.instance.currentUser!.uid);
          if (user != null) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const WelcomeView()),
                  (route) => false,
            );
          } else {
            throw Exception("Không thể lấy thông tin người dùng sau khi đăng nhập.");
          }
          break;

        case "not-profile":
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const CompleteProfileView()),
                (route) => false,
          );
          break;

        case "not-level":
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const WhatYourGoalView()),
                (route) => false,
          );
          break;

        case "not-activate":
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text("Tài khoản bị khóa"),
              content: const Text("Tài khoản của bạn chưa được kích hoạt."),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("OK"),
                )
              ],
            ),
          );
          break;

        default:
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Đăng nhập thất bại: $res')),
          );
      }
    } catch (e) {
      // Xử lý lỗi không mong muốn
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Đã xảy ra lỗi: ${e.toString()}")),
      );
    } finally {
      // Luôn đảm bảo tắt loading
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery
        .of(context)
        .size;
    return Scaffold(
      backgroundColor: TColor.white,
      body: Stack(
        children: [
          SingleChildScrollView(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      height: media.width * 0.1,
                    ),
                    Text(
                      "Hey there,",
                      style: TextStyle(color: TColor.gray, fontSize: 16),
                    ),
                    Text(
                      "Create an Account",
                      style: TextStyle(
                          color: TColor.black,
                          fontSize: 20,
                          fontWeight: FontWeight.w700),
                    ),
                    SizedBox(
                      height: media.width * 0.05,
                    ),
                    RoundTextField(
                      labelText: "First Name",
                      icon: "assets/img/user_text.png",
                      controller: fnameController,
                    ),
                    SizedBox(
                      height: media.width * 0.04,
                    ),
                    RoundTextField(
                      labelText: "Last Name",
                      icon: "assets/img/user_text.png",
                      controller: lnameController,
                    ),
                    SizedBox(
                      height: media.width * 0.04,
                    ),
                    RoundTextField(
                      labelText: "Email",
                      icon: "assets/img/email.png",
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    SizedBox(
                      height: media.width * 0.04,
                    ),
                    RoundTextField(
                      labelText: "Password",
                      icon: "assets/img/lock.png",
                      controller: passwordController,
                      obscureText: obscureText,
                      rigtIcon: TextButton(
                        onPressed: () {
                          setState(() {
                            obscureText = !obscureText;
                          });
                        },
                        child: Container(
                          alignment: Alignment.center,
                          width: 20,
                          height: 20,
                          child: Image.asset(
                            obscureText
                                ? "assets/img/hide_password.png"
                                : "assets/img/show_password.png",
                            // Cập nhật icon
                            width: 20,
                            height: 20,
                            fit: BoxFit.contain,
                            color: TColor.gray,
                          ),
                        ),
                      ),
                    ),

                    Row(
                      children: [
                        IconButton(
                          onPressed: () {
                            setState(() {
                              isCheck = !isCheck;
                            });
                          },
                          icon: Icon(
                            isCheck
                                ? Icons.check_box_outlined
                                : Icons.check_box_outline_blank_outlined,
                            color: TColor.gray,
                            size: 20,
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: "By continuing you accept our ",
                                    style: TextStyle(
                                      color: TColor.gray,
                                      fontSize: 11,
                                    ),
                                  ),
                                  TextSpan(
                                    text: "Privacy Policy and Term of Use",
                                    style: TextStyle(
                                      color: TColor.blue,
                                      fontSize: 11,
                                      decoration: TextDecoration.underline,
                                    ),
                                    recognizer: TapGestureRecognizer()
                                      ..onTap = () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  PrivacyPolicyandTermOfUseView()),
                                        );
                                      },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(
                      height: media.width * 0.4,
                    ),
                    RoundButton(
                      title: "Sign Up",
                      onPressed: () {
                        if (!isCheck) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Bạn cần chấp nhận các điều khoản trước khi đăng ký')),
                          );
                          return;
                        }
                        handleSignup();
                      },
                    ),
                    SizedBox(
                      height: media.width * 0.04,
                    ),
                    Row(
                      children: [
                        Expanded(
                            child: Container(
                              height: 1,
                              color: TColor.gray.withOpacity(0.5),
                            )),
                        Text(
                          "  Or  ",
                          style: TextStyle(color: TColor.black, fontSize: 12),
                        ),
                        Expanded(
                            child: Container(
                              height: 1,
                              color: TColor.gray.withOpacity(0.5),
                            )),
                      ],
                    ),
                    SizedBox(
                      height: media.width * 0.04,
                    ),
                    GestureDetector(
                      onTap: handleSignupWithGG,
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                          color: TColor.white,
                          border: Border.all(
                            width: 1,
                            color: TColor.gray.withOpacity(0.4),
                          ),
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              blurRadius: 10,
                              offset: Offset(0, 5),
                            )
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              "assets/img/google.png",
                              width: 24,
                              height: 24,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              "Sign Up with Google",
                              style: TextStyle(
                                color: Colors.black87,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                    SizedBox(
                      height: media.width * 0.04,
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const LoginView()));
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "Already have an account? ",
                            style: TextStyle(
                              color: TColor.black,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            "Sign In",
                            style: TextStyle(
                                color: TColor.black,
                                fontSize: 14,
                                fontWeight: FontWeight.w700),
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (isLoading)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.5),
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
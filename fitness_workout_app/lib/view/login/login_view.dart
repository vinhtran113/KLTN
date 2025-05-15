import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitness_workout_app/common/colo_extension.dart';
import 'package:fitness_workout_app/common_widget/round_button.dart';
import 'package:fitness_workout_app/common_widget/round_textfield.dart';
import 'package:fitness_workout_app/view/login/reset_password_view.dart';
import 'package:fitness_workout_app/view/login/signup_view.dart';
import 'package:fitness_workout_app/view/login/welcome_view.dart';
import 'package:fitness_workout_app/view/login/what_your_goal_view.dart';
import 'package:flutter/material.dart';
import 'package:fitness_workout_app/services/auth_services.dart';
import 'package:fitness_workout_app/model/user_model.dart';

import 'choose_activity_level_view.dart';
import 'complete_profile_view.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool obscureText = true;
  bool isLoading = false;

  @override
  void dispose() {
    super.dispose();
    emailController.dispose();
    passwordController.dispose();
  }

  void handleLogin() async {
    try {
      setState(() {
        isLoading = true;
      });
      String res = await AuthService().loginUser(
        email: emailController.text,
        password: passwordController.text,
      );

      if (res == "not-activate") {
        _showBlockDialog(context);
        await AuthService().logOut();
        setState(() {
          isLoading = false;
        });
        return;
      }

      if (res == "not-profile") {
        _showNeedCompleteProfileDialog(context);
        setState(() {
          isLoading = false;
        });
        return;
      }

      if (res == "not-level") {
        _showNeedCompleteGoalDialog(context);
        setState(() {
          isLoading = false;
        });
        return;
      }

      if (res == "not-ActivityLevel") {
        _showNeedCompleteActivityLevelDialog(context);
        setState(() {
          isLoading = false;
        });
        return;
      }

      if (res == "success") {
        // Lấy thông tin người dùng
        UserModel? user = await AuthService().getUserInfo(
            FirebaseAuth.instance.currentUser!.uid);

        if (user != null) {
          // Điều hướng đến HomeView với user
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => const WelcomeView(),
            ),
                (route) => false,
          );
        }
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

  void _showBlockDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Block Account"),
          content: const Text("Tài khoản của bạn đã bị chặn bởi admin?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Xác nhận"),
            ),
          ],
        );
      },
    );
  }

  void _showNeedCompleteProfileDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Complete your profile"),
          content: const Text("Bạn chưa hoàn thành việc thiết lập tài khoản?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (context) => const CompleteProfileView(),
                  ),
                      (route) => false,
                );
              },
              child: const Text("Xác nhận"),
            ),
          ],
        );
      },
    );
  }

  void _showNeedCompleteGoalDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Complete your goal"),
          content: const Text("Bạn chưa hoàn thành việc thiết lập tài khoản?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (context) => const WhatYourGoalView(),
                  ),
                      (route) => false,
                );
              },
              child: const Text("Xác nhận"),
            ),
          ],
        );
      },
    );
  }

  void _showNeedCompleteActivityLevelDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Complete your activity level"),
          content: const Text("Bạn chưa hoàn thành việc thiết lập tài khoản?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (context) => const ChooseActivityLevelView(),
                  ),
                      (route) => false,
                );
              },
              child: const Text("Xác nhận"),
            ),
          ],
        );
      },
    );
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

        case "not-ActivityLevel":
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const ChooseActivityLevelView()),
              (route) => false,
        );

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
              child: Container(
                height: media.height * 0.9,
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
                      "Welcome Back",
                      style: TextStyle(
                          color: TColor.black,
                          fontSize: 20,
                          fontWeight: FontWeight.w700),
                    ),
                    SizedBox(
                      height: media.width * 0.05,
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
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (
                                    context) => const ResetPasswordView()));
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "Forgot password? ",
                            style: TextStyle(
                              color: TColor.black,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            "Reset Now",
                            style: TextStyle(
                                color: TColor.black,
                                fontSize: 14,
                                fontWeight: FontWeight.w700),
                          )
                        ],
                      ),
                    ),
                    const Spacer(),
                    RoundButton(
                        title: "Sign In",
                        onPressed: handleLogin
                    ),
                    SizedBox(
                      height: media.width * 0.04,
                    ),
                    Row(
                      // crossAxisAlignment: CrossAxisAlignment.,
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
                              "Sign In with Google",
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
                                builder: (context) => const SignUpView()));
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "Don’t have an account yet? ",
                            style: TextStyle(
                              color: TColor.black,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            "Register",
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


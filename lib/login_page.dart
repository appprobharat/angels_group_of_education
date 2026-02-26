import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:angels/api_service.dart';
import 'package:angels/dashboard/dashboard_screen.dart';
import 'package:angels/teacher/teacher_dashboard_screen.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class LoginPage extends StatefulWidget {
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController idController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _obscureText = true;
  bool _isLoading = false;
  String _errorMessage = '';
  String selectedRole = 'Student';

  @override
  void dispose() {
    idController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (idController.text.trim().isEmpty ||
        passwordController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = "Please enter ID and password";
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final response = await ApiService.postPublic(
      "/login",
      body: {
        'username': idController.text.trim(),
        'password': passwordController.text,
        'type': selectedRole,
      },
    );

    if (response == null) {
      setState(() {
        _errorMessage = "Server not responding";
        _isLoading = false;
      });
      return;
    }

    final data = jsonDecode(response.body);
    debugPrint("🟢 LOGIN RESPONSE: $data");
    if (data['status'] == true) {
      await ApiService.saveSession(data);

      // ✅ ADD THIS
      await sendFcmTokenToLaravel();

      if (!mounted) return;

      if (selectedRole == 'Teacher') {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const TeacherDashboardScreen()),
          (_) => false,
        );
      } else {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
          (_) => false,
        );
      }
    } else {
      setState(() {
        _errorMessage = data['message'] ?? "Invalid credentials";
      });
    }

    setState(() => _isLoading = false);
  }

  Future<void> sendFcmTokenToLaravel() async {
    final fcmToken = await FirebaseMessaging.instance.getToken();
    debugPrint("FCM TOKEN: $fcmToken");

    if (fcmToken == null || fcmToken.isEmpty) {
      debugPrint('❌ FCM token not found');
      return;
    }

    try {
      final response = await ApiService.post(
        context,
        "/save_token",
        body: {'fcm_token': fcmToken},
      );

      if (response != null) {
        debugPrint("✅ FCM token sent successfully");
      }
    } catch (e) {
      debugPrint("❌ FCM Error: $e");
    }
  }

  void _launchURL() async {
    final Uri url = Uri.parse(AppAssets.companyWebsite);

    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw 'Could not launch $url';
    }
  }

  Widget roleToggleSwitch() {
    return Row(
      children: [
        /// ===== STUDENT CARD =====
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => selectedRole = "Student"),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.symmetric(vertical: 18),
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: selectedRole == "Student"
                      ? AppColors.primary
                      : Colors.grey.shade300,
                  width: 1.6,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade200,
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.school_rounded,
                    size: 46,
                    color: selectedRole == "Student"
                        ? AppColors.primary
                        : Colors.grey,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Student",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: selectedRole == "Student"
                          ? AppColors.primary
                          : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        /// ===== TEACHER CARD =====
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => selectedRole = "Teacher"),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.symmetric(vertical: 18),
              margin: const EdgeInsets.only(left: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: selectedRole == "Teacher"
                      ? AppColors.primary
                      : Colors.grey.shade300,
                  width: 1.6,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade200,
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.people,
                    size: 46,
                    color: selectedRole == "Teacher"
                        ? AppColors.primary
                        : Colors.grey,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Teacher",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: selectedRole == "Teacher"
                          ? AppColors.primary
                          : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isStudent = selectedRole == 'Student';

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [Colors.white, Colors.white]),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: Column(
                children: [
                  Image.asset(AppAssets.logo, height: 80),
                  SizedBox(height: 10),
                  Text(
                    AppAssets.schoolName,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  SizedBox(height: 10),
                  // Text(
                  //   AppAssets.schoolDescription,
                  //   textAlign: TextAlign.center,
                  //   style: TextStyle(fontSize: 14),
                  // ),
                  SizedBox(height: 20),
                  roleToggleSwitch(),
                  SizedBox(height: 30),

                  Text(
                    "$selectedRole Login",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  SizedBox(height: 20),

                  TextField(
                    controller: idController,
                    decoration: InputDecoration(
                      labelText: isStudent ? "Student ID" : "Teacher ID",
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                  SizedBox(height: 15),

                  TextField(
                    controller: passwordController,
                    obscureText: _obscureText,
                    decoration: InputDecoration(
                      labelText: "Password",
                      prefixIcon: Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureText
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () =>
                            setState(() => _obscureText = !_obscureText),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),

                  if (_errorMessage.isNotEmpty)
                    Container(
                      margin: EdgeInsets.only(top: 16),
                      padding: EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.danger,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: Colors.white,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              _errorMessage,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  SizedBox(height: 40),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _isLoading ? null : _login,
                      child: _isLoading
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : Text(
                              "Login",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),

                  SizedBox(height: 20),

                  Wrap(
                    alignment: WrapAlignment.center,
                    children: [
                      Text("Powered by ", style: TextStyle(fontSize: 12)),
                      Text(
                        "TechInnovation App Pvt. Ltd.®",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.designerColor,
                          fontSize: 12,
                        ),
                      ),
                      SizedBox(width: 5),
                      Text(
                        "Visit our website ",
                        style: TextStyle(fontSize: 12),
                      ),
                      GestureDetector(
                        onTap: _launchURL,
                        child: Text(
                          AppAssets.websiteName,
                          style: TextStyle(color: AppColors.info, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 18),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      /// ✅ WHATSAPP
                      PremiumSocialIcon(
                        icon: FontAwesomeIcons.whatsapp,
                        iconColor: const Color(0xff25D366),
                        url: "https://wa.me/919999999999", // 👉 change number
                      ),

                      const SizedBox(width: 14),

                      /// ✅ FACEBOOK
                      PremiumSocialIcon(
                        icon: FontAwesomeIcons.facebookF,
                        iconColor: const Color(0xff1877F2),
                        url: "https://facebook.com",
                      ),

                      const SizedBox(width: 14),

                      /// ✅ INSTAGRAM
                      PremiumSocialIcon(
                        icon: FontAwesomeIcons.instagram,
                        iconColor: const Color(0xffE4405F),
                        url: "https://instagram.com",
                      ),

                      const SizedBox(width: 10),

                      /// ✅ LINKEDIN
                      PremiumSocialIcon(
                        icon: FontAwesomeIcons.linkedinIn,
                        iconColor: const Color(0xff0A66C2),
                        url: "https://linkedin.com",
                      ),
                      const SizedBox(width: 10),

                      /// ✅ Youtube
                      PremiumSocialIcon(
                        icon: FontAwesomeIcons.youtube,
                        iconColor: const Color.fromARGB(255, 171, 12, 41),
                        url: "https://youtube.com",
                      ),
                    ],
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

class PremiumSocialIcon extends StatefulWidget {
  final IconData icon;
  final Color iconColor;
  final String url;

  const PremiumSocialIcon({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.url,
  });

  @override
  State<PremiumSocialIcon> createState() => _PremiumSocialIconState();
}

class _PremiumSocialIconState extends State<PremiumSocialIcon> {
  bool pressed = false;

  Future<void> openLink() async {
    final uri = Uri.parse(widget.url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      debugPrint("Could not launch ${widget.url}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => pressed = true),
      onTapUp: (_) {
        setState(() => pressed = false);
        openLink();
      },
      onTapCancel: () => setState(() => pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        height: 54,
        width: 54,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Color(0xfff1f1f1)],
          ),
          boxShadow: pressed
              ? [
                  /// pressed look (inner)
                  BoxShadow(
                    color: Colors.grey.shade400,
                    offset: const Offset(2, 2),
                    blurRadius: 4,
                  ),
                ]
              : [
                  /// floating look
                  BoxShadow(
                    color: Colors.grey.shade400,
                    offset: const Offset(4, 4),
                    blurRadius: 10,
                  ),
                  const BoxShadow(
                    color: Colors.white,
                    offset: Offset(-4, -4),
                    blurRadius: 10,
                  ),
                ],
        ),
        child: Icon(widget.icon, color: widget.iconColor, size: 26),
      ),
    );
  }
}

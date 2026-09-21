import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'verify_mobile_otp_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController phoneController = TextEditingController(
    text: '8881870016',
  );

  static const Color backgroundColor = Color(0xFFF5FBEF);
  static const Color primaryGreen = Color(0xFF079C3B);
  static const Color darkText = Color(0xFF151515);
  static const Color secondaryText = Color(0xFF777777);

  @override
  void dispose() {
    phoneController.dispose();
    super.dispose();
  }

  void _sendOtp() {
    FocusScope.of(context).unfocus();

    Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 350),
        reverseTransitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (_, animation, __) {
          return const VerifyMobileOtpScreen();
        },
        transitionsBuilder: (_, animation, __, child) {
          final slideAnimation =
              Tween<Offset>(
                begin: const Offset(0.08, 0),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              );

          return FadeTransition(
            opacity: animation,
            child: SlideTransition(position: slideAnimation, child: child),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: backgroundColor,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: backgroundColor,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: backgroundColor,
        body: SafeArea(
          bottom: false,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(),

                        const SizedBox(height: 52),

                        _buildWelcomeSection(),

                        const SizedBox(height: 38),

                        _buildPhoneSection(),

                        const SizedBox(height: 28),

                        _buildSendOtpButton(),

                        const SizedBox(height: 20),

                        Center(
                          child: Text(
                            'Your number is safe with us',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        _buildBackButton(),

        Expanded(
          child: Center(
            child: Image.asset(
              'assets/images/evuddy_logo.png',
              width: 158,
              height: 58,
              fit: BoxFit.contain,
            ),
          ),
        ),

        const SizedBox(width: 48),
      ],
    );
  }

  Widget _buildBackButton() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFE8EDE5), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        splashRadius: 22,
        icon: const Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 19,
          color: Color(0xFF171717),
        ),
        onPressed: () {
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          }
        },
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Confirm your\nmobile number',
          style: TextStyle(
            fontSize: 31,
            height: 1.12,
            fontWeight: FontWeight.w750,
            letterSpacing: -0.7,
            color: darkText,
          ),
        ),

        const SizedBox(height: 17),

        Text(
          'Already registered riders must verify OTP before '
          'choosing Normal booking or Rent to Own. New riders '
          'can register directly.',
          style: TextStyle(
            fontSize: 15,
            height: 1.55,
            fontWeight: FontWeight.w400,
            color: secondaryText,
          ),
        ),
      ],
    );
  }

  Widget _buildPhoneSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'MOBILE NUMBER',
          style: TextStyle(
            fontSize: 12,
            letterSpacing: 1.15,
            fontWeight: FontWeight.w700,
            color: Color(0xFF383838),
          ),
        ),

        const SizedBox(height: 11),

        Container(
          height: 62,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: const Color(0xFFE5EAE2), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.035),
                blurRadius: 18,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: Row(
            children: [
              const SizedBox(width: 18),

              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F7ED),
                  borderRadius: BorderRadius.circular(11),
                ),
                alignment: Alignment.center,
                child: const Text('🇮🇳', style: TextStyle(fontSize: 19)),
              ),

              const SizedBox(width: 11),

              const Text(
                '+91',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF343434),
                ),
              ),

              const SizedBox(width: 12),

              Container(width: 1, height: 28, color: const Color(0xFFE3E6E0)),

              const SizedBox(width: 12),

              Expanded(
                child: TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    counterText: '',
                    hintText: 'Enter mobile number',
                    hintStyle: TextStyle(
                      color: Color(0xFFAAAAAA),
                      fontSize: 15,
                    ),
                  ),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF202020),
                    letterSpacing: 0.3,
                  ),
                ),
              ),

              const SizedBox(width: 15),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSendOtpButton() {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: _sendOtp,
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 22),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Text(
              'Send OTP',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.1,
              ),
            ),
            SizedBox(width: 11),
            Icon(Icons.arrow_forward_rounded, size: 21),
          ],
        ),
      ),
    );
  }
}

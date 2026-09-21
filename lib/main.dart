import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'login_screen.dart';
import 'theme/evuddy.dart';
import 'widgets/chrome.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Evuddy.black,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const EvuddyApp());
}

class EvuddyApp extends StatelessWidget {
  const EvuddyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'EVUDDY',
      theme: Evuddy.theme(),
      home: const EvuddySplashScreen(),
    );
  }
}

class EvuddySplashScreen extends StatefulWidget {
  const EvuddySplashScreen({super.key});

  @override
  State<EvuddySplashScreen> createState() => _EvuddySplashScreenState();
}

class _EvuddySplashScreenState extends State<EvuddySplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(milliseconds: 2400), () {
      if (!mounted) return;
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          systemNavigationBarColor: Evuddy.paper,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
      );
      Navigator.of(context).pushReplacement(evuddyRoute(const LoginScreen()));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Evuddy.black,
      body: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Container(width: 5, color: Evuddy.green),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(32, 24, 32, 36),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'EVUDDY',
                    style: GoogleFonts.manrope(
                      fontSize: 13,
                      letterSpacing: 4,
                      fontWeight: FontWeight.w700,
                      color: Evuddy.green,
                    ),
                  ),
                  const Spacer(),
                  Image.asset(
                    'assets/images/evuddy_logo.png',
                    height: 72,
                    color: Colors.white,
                    colorBlendMode: BlendMode.srcATop,
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'Move\nelectric.',
                    style: GoogleFonts.manrope(
                      fontSize: 52,
                      height: 0.95,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -2,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Hub pickup · live GPS · Rent to Own',
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      color: const Color(0xFF9A9A9A),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Expanded(
                        child: Container(height: 2, color: const Color(0xFF2A2A2A)),
                      ),
                      Container(width: 72, height: 2, color: Evuddy.green),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'LUCKNOW   KANPUR',
                    style: GoogleFonts.manrope(
                      fontSize: 11,
                      letterSpacing: 3,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF6A6A6A),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

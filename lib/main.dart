import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'login_screen.dart';
import 'theme/evuddy.dart';
import 'widgets/chrome.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Evuddy.cream,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Evuddy.cream,
      systemNavigationBarIconBrightness: Brightness.dark,
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
    Timer(const Duration(milliseconds: 2200), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(evuddyRoute(const LoginScreen()));
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Evuddy.cream,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              Spacer(),
              Image(
                image: AssetImage('assets/images/evuddy_logo.png'),
                height: 120,
                fit: BoxFit.contain,
              ),
              SizedBox(height: 28),
              WelcomeRule(),
              SizedBox(height: 18),
              Text(
                'Electric mobility for India',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.2,
                  color: Evuddy.ink,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Yard pickup · KYC · Rent to Own',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  letterSpacing: 0.4,
                  color: Evuddy.muted,
                ),
              ),
              Spacer(),
              Text(
                'LUCKNOW  ·  KANPUR',
                style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 2.4,
                  fontWeight: FontWeight.w700,
                  color: Evuddy.gold,
                ),
              ),
              SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }
}

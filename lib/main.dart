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
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
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

class _EvuddySplashScreenState extends State<EvuddySplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fade = CurvedAnimation(parent: _c, curve: Curves.easeOut);
    _c.forward();
    Timer(const Duration(milliseconds: 2200), _go);
  }

  void _go() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(evuddyRoute(const LoginScreen()));
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: FadeTransition(
          opacity: _fade,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(32, 24, 32, 36),
              child: Column(
                children: [
                  const Spacer(flex: 3),
                  const SizedBox(
                    height: 68,
                    width: double.infinity,
                    child: FittedBox(
                      fit: BoxFit.contain,
                      child: EvuddyLogo(height: 80),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Smart electric mobility',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Evuddy.muted,
                    ),
                  ),
                  const Spacer(flex: 4),
                  Text(
                    'Lucknow  ·  Kanpur',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Evuddy.muted,
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

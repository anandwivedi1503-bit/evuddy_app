import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'login_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Color(0xFFF4FBEF),
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Colors.black,
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
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF4FBEF),
      ),
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

    Timer(const Duration(seconds: 3), () {
      if (!mounted) return;

      Navigator.of(context).pushReplacement(
  MaterialPageRoute(
    builder: (context) => const LoginScreen(),
  ),
);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4FBEF),

      body: SafeArea(
        child: Center(
          child: Image.asset(
            'assets/images/evuddy_logo.png',
            width: 270,
            height: 150,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}

class EvuddyHomePage extends StatelessWidget {
  const EvuddyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4FBEF),

      appBar: AppBar(
        title: const Text(
          'EVUDDY',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),

      body: const Center(
        child: Text(
          'EVUDDY Home',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

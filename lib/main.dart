import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'api/evuddy_api.dart';
import 'api/firebase_phone.dart';
import 'shell.dart';
import 'state/registration_draft.dart';
import 'theme/evuddy.dart';
import 'widgets/chrome.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EvuddyFirebase.ensure();
  await registrationDraft.restore();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Evuddy.rapidoYellow,
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

/// Two-colour open like a ride-hailing app: yellow field, then wash to white.
class EvuddySplashScreen extends StatefulWidget {
  const EvuddySplashScreen({super.key});

  @override
  State<EvuddySplashScreen> createState() => _EvuddySplashScreenState();
}

class _EvuddySplashScreenState extends State<EvuddySplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _in;
  late final AnimationController _wash;
  late final AnimationController _out;
  late final Animation<double> _fade;
  late final Animation<double> _scale;
  late final Animation<double> _exit;
  late final Animation<Color?> _bg;

  @override
  void initState() {
    super.initState();
    _in = AnimationController(vsync: this, duration: const Duration(milliseconds: 480));
    _wash = AnimationController(vsync: this, duration: const Duration(milliseconds: 420));
    _out = AnimationController(vsync: this, duration: const Duration(milliseconds: 260));
    _fade = CurvedAnimation(parent: _in, curve: Curves.easeOut);
    _scale = Tween<double>(begin: 0.86, end: 1).animate(
      CurvedAnimation(parent: _in, curve: Curves.easeOutCubic),
    );
    _exit = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(parent: _out, curve: Curves.easeIn),
    );
    _bg = ColorTween(begin: Evuddy.rapidoYellow, end: Colors.white).animate(
      CurvedAnimation(parent: _wash, curve: Curves.easeInOut),
    );
    _in.forward();
    EvuddyApi.health();
    registrationDraft.restore().then((_) {
      if (registrationDraft.phoneVerified) {
        registrationDraft.refreshFromServer();
      }
    });
    Future<void>.delayed(const Duration(milliseconds: 1100), _toWhite);
  }

  Future<void> _toWhite() async {
    if (!mounted) return;
    await _wash.forward();
    if (!mounted) return;
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 380));
    await _go();
  }

  Future<void> _go() async {
    if (!mounted) return;
    await _out.forward();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(evuddyRoute(const RiderShell()));
  }

  @override
  void dispose() {
    _in.dispose();
    _wash.dispose();
    _out.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_bg, _exit, _fade, _scale]),
      builder: (context, _) {
        final color = _bg.value ?? Evuddy.rapidoYellow;
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
            systemNavigationBarColor: color,
            systemNavigationBarIconBrightness: Brightness.dark,
          ),
          child: Scaffold(
            backgroundColor: color,
            body: FadeTransition(
              opacity: _exit,
              child: FadeTransition(
                opacity: _fade,
                child: ScaleTransition(
                  scale: _scale,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 36),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const EvuddySplashMark(),
                          const SizedBox(height: 36),
                          SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: Evuddy.ink.withValues(alpha: 0.55),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

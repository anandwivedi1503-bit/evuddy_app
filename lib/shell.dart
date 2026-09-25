import 'package:flutter/material.dart';

import 'account_screen.dart';
import 'book_ev_screen.dart';
import 'confirm_mobile_screen.dart';
import 'home_screen.dart';
import 'state/registration_draft.dart';
import 'theme/evuddy.dart';

class RiderShell extends StatefulWidget {
  const RiderShell({super.key, this.startIndex = 0});
  final int startIndex;

  @override
  State<RiderShell> createState() => _RiderShellState();
}

class _RiderShellState extends State<RiderShell> with WidgetsBindingObserver {
  late int index;

  @override
  void initState() {
    super.initState();
    index = widget.startIndex;
    if (index < 0 || index > 2) index = 0;
    riderSessionTick.addListener(_onSession);
    WidgetsBinding.instance.addObserver(this);
    if (registrationDraft.phoneVerified) {
      registrationDraft.refreshFromServer();
    }
  }

  void _onSession() {
    if (!mounted) return;
    final jump = registrationDraft.takeTabJump();
    setState(() {
      if (jump != null) index = jump;
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && registrationDraft.phoneVerified) {
      registrationDraft.refreshFromServer();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    riderSessionTick.removeListener(_onSession);
    super.dispose();
  }

  void _select(int i) {
    setState(() => index = i);
    registrationDraft.shellTab = i;
    if (i == 1 && registrationDraft.phoneVerified) {
      registrationDraft.refreshFromServer();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: IndexedStack(
        index: index,
        children: [
          const HomeScreen(),
          registrationDraft.phoneVerified
              ? const BookEvScreen(showBack: false)
              : const ConfirmMobileScreen(),
          AccountScreen(onLoggedOut: () => setState(() => index = 0)),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: _select,
        backgroundColor: Colors.white,
        elevation: 8,
        shadowColor: const Color(0x14000000),
        surfaceTintColor: Colors.white,
        indicatorColor: Evuddy.greenSoft,
        height: 72,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded, color: Evuddy.greenDeep),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.electric_moped_outlined),
            selectedIcon: Icon(Icons.electric_moped_rounded, color: Evuddy.greenDeep),
            label: 'Book EV',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded, color: Evuddy.greenDeep),
            label: 'Account',
          ),
        ],
      ),
    );
  }
}

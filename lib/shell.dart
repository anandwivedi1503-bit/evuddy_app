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

class _RiderShellState extends State<RiderShell> {
  late int index;

  @override
  void initState() {
    super.initState();
    index = widget.startIndex;
    riderSessionTick.addListener(_onSession);
  }

  void _onSession() {
    if (!mounted) return;
    setState(() => index = registrationDraft.shellTab);
  }

  @override
  void dispose() {
    riderSessionTick.removeListener(_onSession);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: IndexedStack(
        index: index,
        children: [
          HomeScreen(key: ValueKey(Evuddy.buildStamp)),
          registrationDraft.phoneVerified
              ? const BookEvScreen(showBack: false)
              : const ConfirmMobileScreen(),
          AccountScreen(onLoggedOut: () => setState(() => index = 0)),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) => setState(() => index = i),
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

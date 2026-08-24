import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:lets_talk/Screens/Test_screens/Test_Main_screen.dart';
import 'package:lets_talk/Screens/account_screen.dart';
import 'package:lets_talk/Screens/Hindi_allscreens/Hini_Home_screen.dart';
import 'package:lets_talk/Screens/home_screen.dart';
import 'package:line_icons/line_icons.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  static final List<Widget> _screens = <Widget>[
    const LearnScreen(),
    const HindiMainScreen(),
    const TestScreen(),
    const AccountScreen(),
  ];

  // --- BRAND COLORS ---
  final Color deepOceanBlue = const Color(0xff065381);
  final Color tealMist = const Color(0xff508F97);
  final Color goldenYellow = const Color(0xffF2C94C);
  final Color darkCanvas = const Color(0xff0A0A0E);
  final Color navBarDark = const Color(0xff14141E);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkCanvas,
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: navBarDark,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          border: Border.all(color: tealMist.withOpacity(0.25)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.45),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12),
          child: GNav(
            backgroundColor: Colors.transparent,
            color: Colors.white60,
            activeColor: goldenYellow,
            tabBackgroundColor: deepOceanBlue.withOpacity(0.85),
            gap: 6,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            tabs: [
              GButton(
                icon: LineIcons.book,
                text: 'English',
                textStyle: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 12.5,
                  color: goldenYellow,
                ),
              ),
              GButton(
                icon: LineIcons.language,
                text: 'Hindi',
                textStyle: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 12.5,
                  color: goldenYellow,
                ),
              ),
              GButton(
                icon: LineIcons.fileContract,
                text: 'Test',
                textStyle: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 12.5,
                  color: goldenYellow,
                ),
              ),
              GButton(
                icon: LineIcons.user,
                text: 'Account',
                textStyle: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 12.5,
                  color: goldenYellow,
                ),
              ),
            ],
            selectedIndex: _selectedIndex,
            onTabChange: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
          ),
        ),
      ),
    );
  }
}

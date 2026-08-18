import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:lets_talk/Screens/Test_screens/Test_Main_screen.dart';
import 'package:lets_talk/Screens/account_screen.dart';
import 'package:lets_talk/Screens/Hindi_allscreens/Hini_Home_screen.dart';
import 'package:lets_talk/Screens/home_screen.dart'; // Assuming LearnScreen lives here or is imported appropriately
import 'package:line_icons/line_icons.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  // Updated screens list: replaced ShortsScreen with HindiMainScreen
  static final List<Widget> _screens = <Widget>[
    const LearnScreen(), // 1. Learn Screen
    const HindiMainScreen(), // 2. Hindi Mode Screen
    const TestScreen(), // 3. Test Screen
    const AccountScreen(), // 4. Account Screen
  ];

  @override
  Widget build(BuildContext context) {
    // Premium dark mode UX color palette matching your design language
    final Color backgroundColor = const Color(0xff0D0D12);
    final Color navBarColor = const Color(0xff181824);
    final Color accentPurple = const Color(0xff7F56D9);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: navBarColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14),
          child: GNav(
            backgroundColor: Colors.transparent,
            color: Colors.white70, // Inactive icon color
            activeColor: Colors.white, // Active icon/text color
            tabBackgroundColor:
                accentPurple, // Sleek purple background for active tab
            gap: 8, // Gap between icon and text
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            tabs: [
              GButton(
                icon: LineIcons.book,
                text: 'English',
                textStyle: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: Colors.white,
                ),
              ),
              GButton(
                icon: LineIcons
                    .language, // Professional icon representing Hindi language mode
                text: 'Hindi',
                textStyle: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: Colors.white,
                ),
              ),
              GButton(
                icon: LineIcons.fileContract,
                text: 'Test',
                textStyle: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: Colors.white,
                ),
              ),
              GButton(
                icon: LineIcons.user,
                text: 'Account',
                textStyle: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: Colors.white,
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

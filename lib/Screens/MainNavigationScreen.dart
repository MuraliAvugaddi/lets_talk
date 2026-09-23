import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:line_icons/line_icons.dart';

import 'package:lets_talk/Screens/Test_screens/Test_Main_screen.dart';
import 'package:lets_talk/Screens/account_screen.dart';
import 'package:lets_talk/Screens/Hindi_allscreens/Hini_Home_screen.dart';
import 'package:lets_talk/Screens/home_screen.dart';
import 'package:lets_talk/Screens/app_colors.dart';

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final bool isDark = theme.brightness == Brightness.dark;

    // ============================================================
    // EXACT NAVIGATION COLORS
    // ============================================================

    // LIGHT MODE
    const Color lightNavBackground = Color(0xFFF7FBFD);

    const Color lightSelectedBackground = Color(0xFF155A88);

    const Color lightSelectedText = Colors.white;

    const Color lightInactive = Color(0xFF678196);

    const Color lightBorder = Color(0xFFD5E5EE);

    // DARK MODE
    const Color darkNavBackground = Color(0xFF102B3A);

    const Color darkSelectedBackground = Color(0xFF267B9A);

    const Color darkSelectedText = Color(0xFF7DE3D8);

    const Color darkInactive = Color(0xFFA7BBC7);

    const Color darkBorder = Color(0xFF285267);

    // ============================================================
    // SELECT COLORS BASED ON CURRENT THEME
    // ============================================================

    final Color navBackground = isDark ? darkNavBackground : lightNavBackground;

    final Color selectedBackground = isDark
        ? darkSelectedBackground
        : lightSelectedBackground;

    final Color selectedText = isDark ? darkSelectedText : lightSelectedText;

    final Color inactiveColor = isDark ? darkInactive : lightInactive;

    final Color borderColor = isDark ? darkBorder : lightBorder;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,

      // ============================================================
      // MAIN SCREENS
      // ============================================================
      body: IndexedStack(index: _selectedIndex, children: _screens),

      // ============================================================
      // BOTTOM NAVIGATION
      // ============================================================
      bottomNavigationBar: Container(
        // IMPORTANT:
        // This makes the COMPLETE bottom area opaque.
        // Nothing behind the navigation will be visible.
        color: navBackground,

        padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),

        child: SafeArea(
          top: false,

          child: Container(
            height: 64,

            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),

            decoration: BoxDecoration(
              color: navBackground,

              borderRadius: BorderRadius.circular(20),

              border: Border.all(color: borderColor, width: 1),

              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.28 : 0.08),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),

            child: GNav(
              selectedIndex: _selectedIndex,

              onTabChange: (index) {
                if (_selectedIndex == index) {
                  return;
                }

                setState(() {
                  _selectedIndex = index;
                });
              },

              // ====================================================
              // NAVIGATION STYLE
              // ====================================================
              backgroundColor: Colors.transparent,

              gap: 5,

              tabBorderRadius: 15,

              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),

              duration: const Duration(milliseconds: 220),

              curve: Curves.easeOutCubic,

              // ====================================================
              // NAVIGATION COLORS
              // ====================================================
              color: inactiveColor,

              activeColor: selectedText,

              tabBackgroundColor: selectedBackground,

              // ====================================================
              // ENGLISH
              // ====================================================
              tabs: [
                GButton(
                  icon: LineIcons.book,
                  text: 'English',
                  textStyle: GoogleFonts.poppins(
                    color: selectedText,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                // ==================================================
                // HINDI
                // ==================================================
                GButton(
                  icon: LineIcons.language,
                  text: 'Hindi',
                  textStyle: GoogleFonts.poppins(
                    color: selectedText,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                // ==================================================
                // TEST
                // ==================================================
                GButton(
                  icon: LineIcons.fileContract,
                  text: 'Test',
                  textStyle: GoogleFonts.poppins(
                    color: selectedText,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                // ==================================================
                // ACCOUNT
                // ==================================================
                GButton(
                  icon: LineIcons.user,
                  text: 'Account',
                  textStyle: GoogleFonts.poppins(
                    color: selectedText,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

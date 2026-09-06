import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'home/home_screen.dart';
import 'study/study_screen.dart';
import 'bookmarks/bookmarks_screen.dart';
import 'notes/notes_screen.dart';
import 'settings/settings_screen.dart';
import '../theme/app_theme.dart';
import '../l10n/app_localizations.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    StudyScreen(),
    BookmarksScreen(),
    NotesScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: AppTheme.dividerColor(context), width: 1),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          selectedItemColor: AppTheme.neonGold,
          unselectedItemColor: const Color(0xFFAAAAAA),
          selectedLabelStyle: GoogleFonts.cinzel(fontSize: 10, fontWeight: FontWeight.w600),
          unselectedLabelStyle: GoogleFonts.cinzel(fontSize: 10),
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.wb_sunny_outlined),
              activeIcon: const Icon(Icons.wb_sunny),
              label: l.navToday,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.menu_book_outlined),
              activeIcon: const Icon(Icons.menu_book),
              label: l.navStudy,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.bookmark_outline),
              activeIcon: const Icon(Icons.bookmark),
              label: l.navBookmarks,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.edit_note_outlined),
              activeIcon: const Icon(Icons.edit_note),
              label: l.navNotes,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.settings_outlined),
              activeIcon: const Icon(Icons.settings),
              label: l.navSettings,
            ),
          ],
        ),
      ),
    );
  }
}

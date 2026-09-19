import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';
import 'family_list_screen.dart';
import 'group_session_screen.dart';
import 'map_screen.dart';
import 'settings_screen.dart';

class NavHubScreen extends StatefulWidget {
  const NavHubScreen({super.key});

  @override
  State<NavHubScreen> createState() => _NavHubScreenState();
}

class _NavHubScreenState extends State<NavHubScreen> {
  int _currentIndex = 0;

  static const List<Widget> _screens = [
    HomeScreen(),
    FamilyListScreen(),
    GroupSessionScreen(),
    MapScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final isHc = appState.isHighContrast;

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        backgroundColor: isHc ? Colors.black : Colors.white,
        indicatorColor: isHc
            ? Colors.yellow.withValues(alpha: 0.2)
            : AppTheme.unicefBlueSolid.withValues(alpha: 0.12),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined, size: 22.sp),
            selectedIcon: Icon(Icons.dashboard, size: 22.sp,
                color: isHc ? Colors.yellow : AppTheme.unicefBlueSolid),
            label: 'Accueil',
          ),
          NavigationDestination(
            icon: Icon(Icons.family_restroom_outlined, size: 22.sp),
            selectedIcon: Icon(Icons.family_restroom, size: 22.sp,
                color: isHc ? Colors.yellow : AppTheme.unicefBlueSolid),
            label: 'Familles',
          ),
          NavigationDestination(
            icon: Icon(Icons.groups_outlined, size: 22.sp),
            selectedIcon: Icon(Icons.groups, size: 22.sp,
                color: isHc ? Colors.yellow : AppTheme.unicefBlueSolid),
            label: 'GSP',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined, size: 22.sp),
            selectedIcon: Icon(Icons.map, size: 22.sp,
                color: isHc ? Colors.yellow : AppTheme.unicefBlueSolid),
            label: 'Carte',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined, size: 22.sp),
            selectedIcon: Icon(Icons.settings, size: 22.sp,
                color: isHc ? Colors.yellow : AppTheme.unicefBlueSolid),
            label: 'Paramètres',
          ),
        ],
      ),
    );
  }
}

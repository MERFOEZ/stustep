import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:animate_do/animate_do.dart';
import '../../core/theme/app_theme.dart';
import '../../features/home/home_screen.dart';
import '../../features/ai/ai_chat_screen.dart';
import '../../features/courses/courses_screen.dart';
import '../../features/chat/chat_groups_screen.dart';
import '../../features/downloads/downloads_screen.dart';
import '../../features/settings/settings_screen.dart';

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 2;

  final List<Widget> _pages = [
    const AIChatScreen(),
    const ChatGroupsScreen(),
    const HomeScreen(),
    const CoursesScreen(),
    const DownloadsScreen(),
  ];

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient(context),
          ),
        ),
        title: Text(
          _getPageTitle(_currentIndex),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: const [],
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      drawer: Drawer(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              currentAccountPicture: ShakeY(
                infinite: true,
                duration: const Duration(seconds: 10),
                child: const CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, size: 40, color: Color(0xFF6200EE)),
                ),
              ),
              accountName: Text('profile'.tr()),
              accountEmail: const Text('student@stustep.com'),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient(context),
              ),
            ),
            _buildDrawerItem(Icons.settings, 'settings'.tr(), () {
              Navigator.pop(context); // Close drawer
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            }),
            _buildDrawerItem(Icons.calculate, 'academic_tools'.tr(), () {}),
            _buildDrawerItem(Icons.help_outline, 'support'.tr(), () {}),
            const Spacer(),
            const Divider(),
            _buildDrawerItem(
              Icons.logout,
              'logout'.tr(),
              () {},
              isDestructive: true,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: BottomAppBar(
        color: Theme.of(context).cardColor,
        child: Row(
          children: [
            Expanded(
              child: _buildNavItem(0, Icons.smart_toy_rounded, 'ai_chat'.tr()),
            ),
            Expanded(
              child: _buildNavItem(1, Icons.chat_bubble_rounded, 'groups'.tr()),
            ),
            Expanded(child: _buildNavItem(2, Icons.home_rounded, 'home'.tr())),
            Expanded(
              child: _buildNavItem(
                3,
                Icons.play_circle_rounded,
                'courses'.tr(),
              ),
            ),
            Expanded(
              child: _buildNavItem(4, Icons.download_rounded, 'downloads'.tr()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    bool isSelected = _currentIndex == index;
    return InkWell(
      onTap: () => _onTabTapped(index),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: isSelected ? Theme.of(context).primaryColor : Colors.grey,
            size: isSelected ? 26 : 22,
          ),
          Text(
            label,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            style: TextStyle(
              color: isSelected ? Theme.of(context).primaryColor : Colors.grey,
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    IconData icon,
    String title,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? Colors.red : Theme.of(context).primaryColor,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive ? Colors.red : null,
          fontWeight: FontWeight.bold,
        ),
      ),
      onTap: onTap,
    );
  }

  String _getPageTitle(int index) {
    switch (index) {
      case 0:
        return 'ai_chat'.tr();
      case 1:
        return 'groups'.tr();
      case 2:
        return 'home'.tr();
      case 3:
        return 'courses'.tr();
      case 4:
        return 'downloads'.tr();
      default:
        return 'app_name'.tr();
    }
  }
}

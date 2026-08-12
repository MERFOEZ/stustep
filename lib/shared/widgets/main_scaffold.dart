import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:animate_do/animate_do.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/gamification_event_bus.dart';
import '../../features/auth/login_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/ai/ai_chat_screen.dart';
import '../../features/courses/colleges_screen.dart';
import '../../features/chat/chat_groups_screen.dart';
import '../../features/downloads/downloads_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/points/providers/points_provider.dart';
import '../../features/points/screens/points_hub_screen.dart';
import '../../features/leaderboard/screens/leaderboard_screen.dart';
import '../../features/referral/screens/referral_screen.dart';

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 2;
  final AuthService _authService = AuthService();
  String _userName = '';
  String _userEmail = '';

  final List<Widget> _pages = [
    const AIChatScreen(),
    const ChatGroupsScreen(),
    const HomeScreen(),
    const CollegesScreen(),
    const DownloadsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _userName = 'loading'.tr();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final currentUser = _authService.currentUser;
    // Record daily login & check streak
    GamificationEventBus.record(
      GamificationAction.dailyLogin,
      referenceId: currentUser?.uid,
    );

    if (currentUser != null) {
      setState(() {
        _userEmail = currentUser.email ?? '';
        _userName = currentUser.displayName ?? 'Student';
      });

      final firestoreData = await _authService.getUserData(currentUser.uid);
      if (firestoreData != null && firestoreData['name'] != null) {
        if (mounted) {
          setState(() {
            _userName = firestoreData['name'] as String;
          });
        }
      }
    }
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pointsProvider = context.watch<PointsProvider>();

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
        actions: [
          // Points Counter Badge in AppBar
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PointsHubScreen()),
              );
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.20),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.monetization_on_rounded,
                    color: Color(0xFFFFD700),
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${pointsProvider.totalPoints}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.leaderboard_rounded),
            tooltip: 'leaderboard.title'.tr(),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LeaderboardScreen()),
              );
            },
          ),
        ],
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
              accountName: Text(_userName),
              accountEmail: Text(_userEmail),
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
            _buildDrawerItem(Icons.card_giftcard_rounded, 'referral.title'.tr(), () {
              Navigator.pop(context); // Close drawer
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ReferralScreen()),
              );
            }),
            _buildDrawerItem(Icons.calculate, 'academic_tools'.tr(), () {}),
            _buildDrawerItem(Icons.help_outline, 'support'.tr(), () {}),
            const Spacer(),
            const Divider(),
            _buildDrawerItem(
              Icons.logout,
              'logout'.tr(),
              () async {
                final navigator = Navigator.of(context);
                await _authService.signOut();
                navigator.pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              },
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
                Icons.account_balance_rounded,
                'colleges'.tr(),
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
        return 'colleges'.tr();
      case 4:
        return 'downloads'.tr();
      default:
        return 'app_name'.tr();
    }
  }
}

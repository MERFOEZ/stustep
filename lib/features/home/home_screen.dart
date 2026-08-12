import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:animate_do/animate_do.dart';
import '../admission/admission_hub_screen.dart';
import '../quests/screens/quests_screen.dart';
import '../leaderboard/screens/leaderboard_screen.dart';
import 'service_detail_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).scaffoldBackgroundColor,
              Theme.of(context).cardColor.withValues(alpha: 0.8),
            ],
          ),
        ),
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FadeInLeft(
                      duration: const Duration(milliseconds: 600),
                      child: const Text(
                        'StuStep',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    FadeInUp(
                      duration: const Duration(milliseconds: 800),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFE91E63), Color(0xFFFF5252)],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFFE91E63,
                              ).withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Pulse(
                              infinite: true,
                              duration: const Duration(seconds: 2),
                              child: const Icon(
                                Icons.auto_awesome,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'welcome_back'.tr(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 20,
                  childAspectRatio: 0.85,
                ),
                delegate: SliverChildListDelegate([
                  _buildServiceCard(
                    context,
                    'quests.title'.tr(),
                    Icons.task_alt_rounded,
                    const LinearGradient(
                      colors: [Color(0xFF6200EE), Color(0xFF7C4DFF)],
                    ),
                    0,
                    'quests.subtitle',
                    destinationBuilder: (_) => const QuestsScreen(),
                  ),
                  _buildServiceCard(
                    context,
                    'leaderboard.title'.tr(),
                    Icons.leaderboard_rounded,
                    const LinearGradient(
                      colors: [Color(0xFFFF9100), Color(0xFFFFD700)],
                    ),
                    50,
                    'leaderboard.group_label',
                    destinationBuilder: (_) => const LeaderboardScreen(),
                  ),
                  _buildServiceCard(
                    context,
                    'major_matcher'.tr(),
                    Icons.psychology,
                    const LinearGradient(
                      colors: [Color(0xFF6200EE), Color(0xFF9C27B0)],
                    ),
                    100,
                    'major_matcher_desc',
                  ),
                  _buildServiceCard(
                    context,
                    'university_portal'.tr(),
                    Icons.school,
                    const LinearGradient(
                      colors: [Color(0xFF00C853), Color(0xFF00E676)],
                    ),
                    150,
                    'university_portal_desc',
                    destinationBuilder: (_) => const AdmissionHubScreen(),
                  ),
                  _buildServiceCard(
                    context,
                    'gpa_predictor'.tr(),
                    Icons.calculate,
                    const LinearGradient(
                      colors: [Color(0xFFFFAB00), Color(0xFFFFD54F)],
                    ),
                    200,
                    'gpa_predictor_desc',
                  ),
                  _buildServiceCard(
                    context,
                    'marketplace'.tr(),
                    Icons.shopping_bag,
                    const LinearGradient(
                      colors: [Color(0xFFD500F9), Color(0xFFE040FB)],
                    ),
                    250,
                    'marketplace_desc',
                  ),
                  _buildServiceCard(
                    context,
                    'scholarship_radar'.tr(),
                    Icons.radar,
                    const LinearGradient(
                      colors: [Color(0xFFFF1744), Color(0xFFFF5252)],
                    ),
                    300,
                    'scholarship_radar_desc',
                  ),
                ]),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceCard(
    BuildContext context,
    String title,
    IconData icon,
    Gradient gradient,
    int delay,
    String descriptionKey, {
    WidgetBuilder? destinationBuilder,
  }) {
    return ElasticIn(
      delay: Duration(milliseconds: delay),
      duration: const Duration(milliseconds: 1200),
      child: Container(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: (gradient as LinearGradient).colors.first.withValues(
                alpha: 0.4,
              ),
              blurRadius: 20,
              offset: const Offset(0, 10),
              spreadRadius: 2,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(28),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      destinationBuilder ??
                      ((context) => ServiceDetailScreen(
                        title: title,
                        descriptionKey: descriptionKey,
                        icon: icon,
                        gradient: gradient,
                      )),
                ),
              );
            },
            child: Stack(
              children: [
                PositionedDirectional(
                  end: -30,
                  top: -30,
                  child: Opacity(
                    opacity: 0.15,
                    child: Icon(icon, size: 150, color: Colors.white),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withValues(alpha: 0.2),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.3),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Icon(icon, color: Colors.white, size: 36),
                      ),
                      const Spacer(),
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              color: Colors.black26,
                              offset: Offset(1, 1),
                              blurRadius: 3,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 50,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withValues(alpha: 0.5),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    ],
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

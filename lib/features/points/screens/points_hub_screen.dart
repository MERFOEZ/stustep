import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../providers/points_provider.dart';
import '../widgets/points_summary_card.dart';
import '../widgets/streak_banner.dart';
import '../widgets/quest_card.dart';
import 'points_history_screen.dart';
import '../../leaderboard/screens/leaderboard_screen.dart';

class PointsHubScreen extends StatefulWidget {
  const PointsHubScreen({super.key});

  @override
  State<PointsHubScreen> createState() => _PointsHubScreenState();
}

class _PointsHubScreenState extends State<PointsHubScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    return '$hours:$minutes';
  }

  @override
  Widget build(BuildContext context) {
    final pointsProvider = context.watch<PointsProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final dailyTimeLeft = pointsProvider.getRemainingDailyTime();
    final weeklyTimeLeft = pointsProvider.getRemainingWeeklyTime();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'points.title'.tr(),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
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
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: 'points.history'.tr(),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PointsHistoryScreen()),
              );
            },
          ),
        ],
      ),
      body: pointsProvider.isLoading
          ? Center(
              child: SpinKitFadingCircle(
                color: Theme.of(context).primaryColor,
                size: 40,
              ),
            )
          : RefreshIndicator(
              onRefresh: () async {
                // Refresh handled by real-time streams
                await Future.delayed(const Duration(milliseconds: 500));
              },
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FadeInDown(
                            duration: const Duration(milliseconds: 600),
                            child: PointsSummaryCard(
                              totalPoints: pointsProvider.totalPoints,
                              weeklyPoints: pointsProvider.weeklyPoints,
                              tierLevel: pointsProvider.tierLevel,
                              onHistoryTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const PointsHistoryScreen(),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 14),
                          FadeInDown(
                            delay: const Duration(milliseconds: 150),
                            duration: const Duration(milliseconds: 600),
                            child: StreakBanner(
                              streakDays: pointsProvider.currentStreak,
                            ),
                          ),
                          const SizedBox(height: 18),
                          // Tab Bar
                          Container(
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: TabBar(
                              controller: _tabController,
                              indicatorSize: TabBarIndicatorSize.tab,
                              dividerColor: Colors.transparent,
                              indicator: BoxDecoration(
                                color: Theme.of(context).primaryColor,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              labelColor: Colors.white,
                              unselectedLabelColor: isDark ? Colors.white60 : Colors.black54,
                              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                              tabs: [
                                Tab(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.today_rounded, size: 16),
                                      const SizedBox(width: 6),
                                      Text('quests.daily'.tr()),
                                    ],
                                  ),
                                ),
                                Tab(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.date_range_rounded, size: 16),
                                      const SizedBox(width: 6),
                                      Text('quests.weekly'.tr()),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                      ),
                    ),
                  ),
                  SliverFillRemaining(
                    hasScrollBody: true,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        // Daily Quests Tab
                        _buildQuestsList(
                          quests: pointsProvider.dailyQuests,
                          progressMap: pointsProvider.dailyProgress,
                          countdownText: '${'quests.daily_reset_in'.tr()}: ${_formatDuration(dailyTimeLeft)}',
                          countdownIcon: Icons.timer_outlined,
                        ),
                        // Weekly Quests Tab
                        _buildQuestsList(
                          quests: pointsProvider.weeklyQuests,
                          progressMap: pointsProvider.weeklyProgress,
                          countdownText: '${'quests.weekly_reset_in'.tr()}: ${weeklyTimeLeft.inDays} ${'points.days'.tr()}',
                          countdownIcon: Icons.event_repeat_rounded,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildQuestsList({
    required List<dynamic> quests,
    required Map<String, dynamic> progressMap,
    required String countdownText,
    required IconData countdownIcon,
  }) {
    if (quests.isEmpty) {
      return Center(
        child: Text(
          'quests.in_progress'.tr(),
          style: const TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      children: [
        Row(
          children: [
            Icon(countdownIcon, size: 15, color: Colors.grey),
            const SizedBox(width: 6),
            Text(
              countdownText,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...quests.map((q) {
          final progress = progressMap[q.id];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: QuestCard(
              quest: q,
              progress: progress,
            ),
          );
        }),
        const SizedBox(height: 30),
      ],
    );
  }
}

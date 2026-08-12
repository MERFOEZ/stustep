import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../providers/leaderboard_provider.dart';
import '../../points/providers/points_provider.dart';
import '../widgets/tier_badge.dart';
import '../widgets/leaderboard_podium.dart';
import '../widgets/leaderboard_entry_tile.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lbProvider = context.watch<LeaderboardProvider>();
    final pointsProvider = context.watch<PointsProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final weeklyTimeLeft = pointsProvider.getRemainingWeeklyTime();
    final members = lbProvider.members;
    final top3 = members.take(3).toList();
    final remainingMembers = members.length > 3 ? members.sublist(3) : [];
    final currentUser = lbProvider.currentUserEntry;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'leaderboard.title'.tr(),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: lbProvider.isLoading && members.isEmpty
          ? Center(
              child: SpinKitFadingCircle(
                color: Theme.of(context).primaryColor,
                size: 40,
              ),
            )
          : RefreshIndicator(
              onRefresh: () => lbProvider.fetchLeaderboard(),
              child: Stack(
                children: [
                  CustomScrollView(
                    slivers: [
                      // Header Card with Tier & Countdown
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    TierBadge(
                                      tierLevel: lbProvider.tierLevel,
                                      size: 32,
                                    ),
                                    const SizedBox(width: 10),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'leaderboard.weekly_league'.tr(),
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          'leaderboard.group_label'.tr(),
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: isDark ? Colors.white54 : Colors.black45,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.timer_outlined, size: 14, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${weeklyTimeLeft.inDays} ${'points.days'.tr()}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey,
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

                      // Top 3 Podium
                      if (top3.isNotEmpty)
                        SliverToBoxAdapter(
                          child: LeaderboardPodium(top3: top3),
                        ),

                      // Zone Legend
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildZoneIndicator(
                                const Color(0xFF00E676),
                                'leaderboard.promotion_zone'.tr(),
                              ),
                              _buildZoneIndicator(
                                const Color(0xFFFF5252),
                                'leaderboard.demotion_zone'.tr(),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Remaining members list (4th to last)
                      if (remainingMembers.isNotEmpty)
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final entry = remainingMembers[index];
                                final isPromotion = entry.rank <= 7;
                                final isDemotion = entry.rank > (members.length - 5);

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: LeaderboardEntryTile(
                                    entry: entry,
                                    isPromotion: isPromotion,
                                    isDemotion: isDemotion,
                                  ),
                                );
                              },
                              childCount: remainingMembers.length,
                            ),
                          ),
                        )
                      else if (members.isEmpty)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.all(40),
                            child: Center(
                              child: Text(
                                'leaderboard.no_members'.tr(),
                                style: const TextStyle(color: Colors.grey),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),

                  // Floating Bottom Card for Current User
                  if (currentUser != null)
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isDark
                                ? [const Color(0xFF311B92), const Color(0xFF4A148C)]
                                : [const Color(0xFF6200EE), const Color(0xFF7C4DFF)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF6200EE).withValues(alpha: 0.4),
                              blurRadius: 18,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    '#${currentUser.rank}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'leaderboard.your_rank'.tr(),
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 11,
                                      ),
                                    ),
                                    Text(
                                      lbProvider.isPromotionZone
                                          ? 'leaderboard.promoted_next_week'.tr()
                                          : (lbProvider.isDemotionZone
                                              ? 'leaderboard.demoted_next_week'.tr()
                                              : '${lbProvider.pointsToPromotion} ${'leaderboard.pts_to_promotion'.tr()}'),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Text(
                              '${currentUser.weeklyPoints} ${'leaderboard.points_short'.tr()}',
                              style: const TextStyle(
                                color: Color(0xFFFFD54F),
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildZoneIndicator(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

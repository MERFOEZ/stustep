import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:animate_do/animate_do.dart';
import '../models/leaderboard_entry_model.dart';

class LeaderboardPodium extends StatelessWidget {
  final List<LeaderboardEntryModel> top3;

  const LeaderboardPodium({
    super.key,
    required this.top3,
  });

  @override
  Widget build(BuildContext context) {
    if (top3.isEmpty) return const SizedBox.shrink();

    final first = top3.isNotEmpty ? top3[0] : null;
    final second = top3.length > 1 ? top3[1] : null;
    final third = top3.length > 2 ? top3[2] : null;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 2nd Place
          if (second != null)
            Expanded(
              child: FadeInLeft(
                duration: const Duration(milliseconds: 600),
                child: _buildPodiumColumn(
                  context,
                  entry: second,
                  rank: 2,
                  podiumHeight: 90,
                  badgeColor: const Color(0xFFC0C0C0),
                  crownColor: const Color(0xFFE0E0E0),
                ),
              ),
            )
          else
            const Expanded(child: SizedBox()),

          // 1st Place (Center, Tallest)
          if (first != null)
            Expanded(
              child: FadeInDown(
                duration: const Duration(milliseconds: 700),
                child: _buildPodiumColumn(
                  context,
                  entry: first,
                  rank: 1,
                  podiumHeight: 120,
                  badgeColor: const Color(0xFFFFD700),
                  crownColor: const Color(0xFFFFC107),
                  isFirst: true,
                ),
              ),
            )
          else
            const Expanded(child: SizedBox()),

          // 3rd Place
          if (third != null)
            Expanded(
              child: FadeInRight(
                duration: const Duration(milliseconds: 600),
                child: _buildPodiumColumn(
                  context,
                  entry: third,
                  rank: 3,
                  podiumHeight: 70,
                  badgeColor: const Color(0xFFCD7F32),
                  crownColor: const Color(0xFFD7CCC8),
                ),
              ),
            )
          else
            const Expanded(child: SizedBox()),
        ],
      ),
    );
  }

  Widget _buildPodiumColumn(
    BuildContext context, {
    required LeaderboardEntryModel entry,
    required int rank,
    required double podiumHeight,
    required Color badgeColor,
    required Color crownColor,
    bool isFirst = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Crown icon
        Icon(
          Icons.emoji_events_rounded,
          color: crownColor,
          size: isFirst ? 26 : 20,
        ),
        const SizedBox(height: 6),
        // Avatar with ranking border
        Container(
          width: isFirst ? 68 : 54,
          height: isFirst ? 68 : 54,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: badgeColor, width: isFirst ? 3 : 2.5),
            boxShadow: [
              BoxShadow(
                color: badgeColor.withValues(alpha: 0.35),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: CircleAvatar(
            backgroundColor: isDark ? const Color(0xFF2C2C2C) : Colors.grey.shade200,
            backgroundImage: entry.photoUrl != null && entry.photoUrl!.isNotEmpty
                ? NetworkImage(entry.photoUrl!)
                : null,
            child: entry.photoUrl == null || entry.photoUrl!.isEmpty
                ? Text(
                    entry.name.isNotEmpty ? entry.name[0].toUpperCase() : '?',
                    style: TextStyle(
                      fontSize: isFirst ? 24 : 18,
                      fontWeight: FontWeight.bold,
                      color: badgeColor,
                    ),
                  )
                : null,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          entry.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: isFirst ? 14 : 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '${entry.weeklyPoints} ${'leaderboard.points_short'.tr()}',
          style: TextStyle(
            fontSize: 11,
            color: isDark ? Colors.white60 : Colors.black54,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        // Podium block
        Container(
          height: podiumHeight,
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                badgeColor.withValues(alpha: isDark ? 0.35 : 0.25),
                badgeColor.withValues(alpha: isDark ? 0.15 : 0.10),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            border: Border.all(color: badgeColor.withValues(alpha: 0.4)),
          ),
          child: Center(
            child: Text(
              '$rank',
              style: TextStyle(
                fontSize: isFirst ? 32 : 24,
                fontWeight: FontWeight.w900,
                color: badgeColor,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

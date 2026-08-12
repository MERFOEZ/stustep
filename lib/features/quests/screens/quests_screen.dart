import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:animate_do/animate_do.dart';
import '../providers/quests_provider.dart';
import '../widgets/quest_card.dart';
import '../widgets/quest_progress_header.dart';

class QuestsScreen extends StatefulWidget {
  const QuestsScreen({super.key});

  static const String routeName = '/quests';

  @override
  State<QuestsScreen> createState() => _QuestsScreenState();
}

class _QuestsScreenState extends State<QuestsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        context.read<QuestsProvider>().switchTab(_tabController.index);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final questsProvider = context.watch<QuestsProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'quests.title'.tr(),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(54),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? Colors.white10 : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(16),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: Colors.white,
              unselectedLabelColor: isDark ? Colors.white60 : Colors.black54,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              tabs: [
                Tab(text: 'quests.daily'.tr()),
                Tab(text: 'quests.weekly'.tr()),
              ],
            ),
          ),
        ),
      ),
      body: questsProvider.isLoading && questsProvider.dailyQuests.isEmpty
          ? Center(
              child: SpinKitFadingCircle(
                color: Theme.of(context).primaryColor,
                size: 40,
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                // 1. Daily Quests Tab
                _buildQuestsList(
                  context,
                  isDaily: true,
                  quests: questsProvider.dailyQuests,
                  progressMap: questsProvider.dailyProgress,
                  completedCount: questsProvider.completedDailyCount,
                  onRefresh: questsProvider.refreshQuests,
                ),
                // 2. Weekly Quests Tab
                _buildQuestsList(
                  context,
                  isDaily: false,
                  quests: questsProvider.weeklyQuests,
                  progressMap: questsProvider.weeklyProgress,
                  completedCount: questsProvider.completedWeeklyCount,
                  onRefresh: questsProvider.refreshQuests,
                ),
              ],
            ),
    );
  }

  Widget _buildQuestsList(
    BuildContext context, {
    required bool isDaily,
    required List quests,
    required Map progressMap,
    required int completedCount,
    required Future<void> Function() onRefresh,
  }) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        children: [
          // Progress Header
          FadeInDown(
            duration: const Duration(milliseconds: 500),
            child: QuestProgressHeader(
              isDaily: isDaily,
              completedCount: completedCount,
              totalCount: quests.length,
            ),
          ),
          const SizedBox(height: 18),
          // Section Title
          Text(
            isDaily ? 'quests.daily'.tr() : 'quests.weekly'.tr(),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          // Quests Cards
          if (quests.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              alignment: Alignment.center,
              child: Text(
                'quests.empty'.tr(),
                style: const TextStyle(color: Colors.grey),
              ),
            )
          else
            ...quests.asMap().entries.map((entry) {
              final index = entry.key;
              final quest = entry.value;
              final progress = progressMap[quest.id];

              return FadeInUp(
                delay: Duration(milliseconds: index * 60),
                duration: const Duration(milliseconds: 400),
                child: QuestCard(
                  quest: quest,
                  progress: progress,
                ),
              );
            }),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:animate_do/animate_do.dart';
import 'group_chat_screen.dart';

class ChatGroupsScreen extends StatelessWidget {
  const ChatGroupsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final Map<String, List<Map<String, dynamic>>> organizedGroups = {
      'category_medical': [
        {
          'id': 'med1',
          'name': 'group_med_students',
          'members': '1.2k',
          'lastMessage': 'group_med_msg',
          'gradient': const LinearGradient(
            colors: [Color(0xFFE91E63), Color(0xFFFF5252)],
          ),
        },
        {
          'id': 'med2',
          'name': 'group_anatomy_titans',
          'members': '850',
          'lastMessage': 'group_med_msg',
          'gradient': const LinearGradient(
            colors: [Color(0xFFFF4081), Color(0xFFF50057)],
          ),
        },
        {
          'id': 'med3',
          'name': 'group_pharma_pro',
          'members': '2.1k',
          'lastMessage': 'group_med_msg',
          'gradient': const LinearGradient(
            colors: [Color(0xFFC2185B), Color(0xFFAD1457)],
          ),
        },
      ],
      'category_engineering': [
        {
          'id': 'eng1',
          'name': 'group_eng_logic',
          'members': '850',
          'lastMessage': 'group_eng_msg',
          'gradient': const LinearGradient(
            colors: [Color(0xFF6200EE), Color(0xFF9C27B0)],
          ),
        },
        {
          'id': 'eng2',
          'name': 'group_civil_stars',
          'members': '1.5k',
          'lastMessage': 'group_eng_msg',
          'gradient': const LinearGradient(
            colors: [Color(0xFF3F51B5), Color(0xFF2196F3)],
          ),
        },
        {
          'id': 'eng3',
          'name': 'group_electric_vibes',
          'members': '920',
          'lastMessage': 'group_eng_msg',
          'gradient': const LinearGradient(
            colors: [Color(0xFF00BCD4), Color(0xFF009688)],
          ),
        },
      ],
      'category_it': [
        {
          'id': 'it1',
          'name': 'group_cs_daily',
          'members': '3.4k',
          'lastMessage': 'group_cs_msg',
          'gradient': const LinearGradient(
            colors: [Color(0xFFFFAB00), Color(0xFFFFD54F)],
          ),
        },
        {
          'id': 'it2',
          'name': 'group_mobile_dev_hub',
          'members': '2.8k',
          'lastMessage': 'group_cs_msg',
          'gradient': const LinearGradient(
            colors: [Color(0xFF00C853), Color(0xFF00E676)],
          ),
        },
        {
          'id': 'it3',
          'name': 'group_cyber_guardians',
          'members': '1.1k',
          'lastMessage': 'group_cs_msg',
          'gradient': const LinearGradient(
            colors: [Color(0xFF2962FF), Color(0xFF448AFF)],
          ),
        },
      ],
    };

    return DefaultTabController(
      length: organizedGroups.length,
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 0, // Hide main toolbar
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            indicatorSize: TabBarIndicatorSize.label,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold),
            tabs: organizedGroups.keys
                .map((cat) => Tab(text: cat.tr()))
                .toList(),
          ),
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Theme.of(context).scaffoldBackgroundColor,
                const Color(0xFF6200EE).withValues(alpha: 0.03),
              ],
            ),
          ),
          child: TabBarView(
            children: organizedGroups.values.map((groupList) {
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: groupList.length,
                itemBuilder: (context, index) {
                  final group = groupList[index];
                  return BounceInLeft(
                    delay: Duration(milliseconds: index * 100),
                    duration: const Duration(milliseconds: 800),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        gradient: group['gradient'] as LinearGradient,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: (group['gradient'] as LinearGradient)
                                .colors
                                .first
                                .withValues(alpha: 0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 6),
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => GroupChatScreen(
                                  groupName: group['name'],
                                  gradient: group['gradient'],
                                ),
                              ),
                            );
                          },
                          child: Stack(
                            children: [
                              PositionedDirectional(
                                end: -20,
                                top: -20,
                                child: Opacity(
                                  opacity: 0.1,
                                  child: Icon(
                                    Icons.group,
                                    size: 100,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Hero(
                                      tag: group['name'],
                                      child: Container(
                                        width: 60,
                                        height: 60,
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(
                                            alpha: 0.3,
                                          ),
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(
                                                alpha: 0.1,
                                              ),
                                              blurRadius: 8,
                                              spreadRadius: 1,
                                            ),
                                          ],
                                        ),
                                        child: Center(
                                          child: Text(
                                            (group['name'] as String).tr()[0],
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 24,
                                              shadows: [
                                                Shadow(
                                                  color: Colors.black26,
                                                  offset: Offset(1, 1),
                                                  blurRadius: 2,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            (group['name'] as String).tr(),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
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
                                          const SizedBox(height: 4),
                                          Text(
                                            (group['lastMessage'] as String)
                                                .tr(),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.white.withValues(
                                                alpha: 0.9,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(
                                          alpha: 0.3,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.people,
                                            size: 16,
                                            color: Colors.white,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            group['members']!,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
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
                },
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

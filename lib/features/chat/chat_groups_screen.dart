import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';

class ChatGroupsScreen extends StatelessWidget {
  const ChatGroupsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> groups = [
      {
        'name': 'Medical Students Hub',
        'members': '1.2k',
        'lastMessage': 'The anatomy exam is postponed.',
        'gradient': const LinearGradient(
          colors: [Color(0xFFE91E63), Color(0xFFFF5252)],
        ),
      },
      {
        'name': 'Engineering Logic',
        'members': '850',
        'lastMessage': 'Does anyone have the link for the CAD lecture?',
        'gradient': const LinearGradient(
          colors: [Color(0xFF6200EE), Color(0xFF9C27B0)],
        ),
      },
      {
        'name': 'Business & Finance',
        'members': '2.1k',
        'lastMessage': 'New scholarship opportunity posted in the radar!',
        'gradient': const LinearGradient(
          colors: [Color(0xFF00C853), Color(0xFF00E676)],
        ),
      },
      {
        'name': 'Computer Science Daily',
        'members': '3.4k',
        'lastMessage': 'Rust vs C++ thread is getting heated...',
        'gradient': const LinearGradient(
          colors: [Color(0xFFFFAB00), Color(0xFFFFD54F)],
        ),
      },
      {
        'name': 'Art & Design',
        'members': '680',
        'lastMessage': 'Check out the new portfolio showcase!',
        'gradient': const LinearGradient(
          colors: [Color(0xFFD500F9), Color(0xFFE040FB)],
        ),
      },
    ];

    return Scaffold(
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
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: groups.length,
          itemBuilder: (context, index) {
            final group = groups[index];
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
                      color: (group['gradient'] as LinearGradient).colors.first
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
                    onTap: () {},
                    child: Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
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
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.3),
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
                                    group['name']![0],
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
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      group['name']!,
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
                                      group['lastMessage']!,
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
                              Column(
                                children: [
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
        ),
      ),
    );
  }
}

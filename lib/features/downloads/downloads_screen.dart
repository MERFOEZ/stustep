import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:animate_do/animate_do.dart';

class DownloadsScreen extends StatelessWidget {
  const DownloadsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> downloads = [
      {
        'title': 'Introduction to Calculus',
        'type': 'video',
        'size': '245 MB',
        'status': 'Completed',
        'progress': 1.0,
        'gradient': const LinearGradient(
          colors: [Color(0xFF6200EE), Color(0xFF9C27B0)],
        ),
      },
      {
        'title': 'Physics Ch5 - Thermodynamics',
        'type': 'pdf',
        'size': '12 MB',
        'status': 'Completed',
        'progress': 1.0,
        'gradient': const LinearGradient(
          colors: [Color(0xFF00C853), Color(0xFF00E676)],
        ),
      },
      {
        'title': 'Data Structures Lecture 12',
        'type': 'video',
        'size': '189 MB',
        'status': 'Downloading... 67%',
        'progress': 0.67,
        'gradient': const LinearGradient(
          colors: [Color(0xFFFFAB00), Color(0xFFFFD54F)],
        ),
      },
      {
        'title': 'Chemistry Lab Manual',
        'type': 'pdf',
        'size': '8.5 MB',
        'status': 'Completed',
        'progress': 1.0,
        'gradient': const LinearGradient(
          colors: [Color(0xFFE91E63), Color(0xFFFF5252)],
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
        child: downloads.isEmpty
            ? Center(
                child: FadeIn(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.download_outlined,
                        size: 80,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'no_downloads'.tr(),
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: downloads.length,
                itemBuilder: (context, index) {
                  final item = downloads[index];
                  return SlideInUp(
                    delay: Duration(milliseconds: index * 100),
                    duration: const Duration(milliseconds: 600),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        gradient: item['gradient'] as LinearGradient,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: (item['gradient'] as LinearGradient)
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
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(
                                          alpha: 0.3,
                                        ),
                                        borderRadius: BorderRadius.circular(16),
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
                                      child: Icon(
                                        item['type'] == 'video'
                                            ? Icons.play_circle
                                            : Icons.description,
                                        color: Colors.white,
                                        size: 32,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item['title'],
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
                                          const SizedBox(height: 6),
                                          Text(
                                            '${item['size']} • ${item['status']}',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.white.withValues(
                                                alpha: 0.9,
                                              ),
                                            ),
                                          ),
                                          if (item['progress'] < 1.0) ...[
                                            const SizedBox(height: 8),
                                            ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              child: LinearProgressIndicator(
                                                value: item['progress'],
                                                backgroundColor: Colors.white
                                                    .withValues(alpha: 0.3),
                                                valueColor:
                                                    const AlwaysStoppedAnimation<
                                                      Color
                                                    >(Colors.white),
                                                minHeight: 6,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(
                                          alpha: 0.3,
                                        ),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.more_vert,
                                        color: Colors.white,
                                        size: 20,
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
              ),
      ),
    );
  }
}

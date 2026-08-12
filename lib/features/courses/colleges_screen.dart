import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:animate_do/animate_do.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'departments_screen.dart';

class CollegesScreen extends StatefulWidget {
  const CollegesScreen({super.key});

  @override
  State<CollegesScreen> createState() => _CollegesScreenState();
}

class _CollegesScreenState extends State<CollegesScreen> {
  // Curated gradients for college cards
  static const List<LinearGradient> _gradients = [
    LinearGradient(colors: [Color(0xFF6200EE), Color(0xFF9C27B0)]),
    LinearGradient(colors: [Color(0xFF00C853), Color(0xFF00E676)]),
    LinearGradient(colors: [Color(0xFFD500F9), Color(0xFFE040FB)]),
    LinearGradient(colors: [Color(0xFFFF1744), Color(0xFFFF5252)]),
    LinearGradient(colors: [Color(0xFFFFAB00), Color(0xFFFFD54F)]),
    LinearGradient(colors: [Color(0xFF00BCD4), Color(0xFF00E5FF)]),
    LinearGradient(colors: [Color(0xFF304FFE), Color(0xFF448AFF)]),
    LinearGradient(colors: [Color(0xFFFF6D00), Color(0xFFFF9100)]),
  ];

  // Icon mapping for common college types
  static IconData _getCollegeIcon(String? iconName) {
    switch (iconName) {
      case 'engineering':
        return Icons.engineering;
      case 'science':
        return Icons.science;
      case 'medical':
      case 'medicine':
        return Icons.local_hospital;
      case 'business':
        return Icons.business_center;
      case 'law':
        return Icons.gavel;
      case 'arts':
        return Icons.palette;
      case 'education':
        return Icons.school;
      case 'computer':
      case 'it':
        return Icons.computer;
      case 'pharmacy':
        return Icons.medication;
      case 'agriculture':
        return Icons.eco;
      default:
        return Icons.account_balance;
    }
  }

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
              Theme.of(context).primaryColor.withValues(alpha: 0.05),
            ],
          ),
        ),
        child: StreamBuilder<QuerySnapshot>(
          stream:
              FirebaseFirestore.instance.collection('colleges').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              debugPrint('=== APP_STATE: Loading... ===');
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 48,
                      height: 48,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'جاري التحميل...',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              );
            }

            if (snapshot.hasError) {
              debugPrint('=== APP_ERROR: ${snapshot.error} ===');
              return Center(
                child: FadeIn(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline_rounded,
                        size: 48,
                        color: Colors.red.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'حدث خطأ في تحميل الكليات',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${snapshot.error}',
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              debugPrint('=== APP_STATE: No Data or Empty ===');
              return Center(
                child: FadeIn(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.account_balance_outlined,
                        size: 80,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'no_colleges'.tr(),
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            final docs = snapshot.data!.docs;
            debugPrint('=== APP_SUCCESS: Found ${docs.length} colleges ===');

            return CustomScrollView(
              slivers: [
                // Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                    child: FadeInDown(
                      duration: const Duration(milliseconds: 800),
                      child: ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [Color(0xFF6200EE), Color(0xFFE91E63)],
                        ).createShader(bounds),
                        child: Text(
                          'colleges'.tr(),
                          style: Theme.of(context)
                              .textTheme
                              .displaySmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                        ),
                      ),
                    ),
                  ),
                ),
                // Grid of colleges
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.9,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final doc = docs[index];
                        String name = '';
                        String? iconName;
                        try {
                          final data = doc.data() as Map<String, dynamic>? ?? {};
                          debugPrint('--- Mapping doc ${doc.id}: $data ---');
                          name = data['name'] as String? ?? '';
                          iconName = data['icon'] as String?;
                        } catch (e) {
                          debugPrint('=== APP_MAPPING_ERROR: Failed to map doc ${doc.id}: $e ===');
                        }
                        final gradient =
                            _gradients[index % _gradients.length];
                        final icon = _getCollegeIcon(iconName);

                        return _buildCollegeCard(
                          context,
                          name: name,
                          icon: icon,
                          gradient: gradient,
                          delay: index * 100,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => DepartmentsScreen(
                                  collegeId: doc.id,
                                  collegeName: name,
                                ),
                              ),
                            );
                          },
                        );
                      },
                      childCount: docs.length,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildCollegeCard(
    BuildContext context, {
    required String name,
    required IconData icon,
    required LinearGradient gradient,
    required int delay,
    required VoidCallback onTap,
  }) {
    return ElasticIn(
      delay: Duration(milliseconds: delay),
      duration: const Duration(milliseconds: 1200),
      child: Container(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: gradient.colors.first.withValues(alpha: 0.4),
              blurRadius: 18,
              offset: const Offset(0, 8),
              spreadRadius: 2,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: onTap,
            child: Stack(
              children: [
                // Background icon watermark
                PositionedDirectional(
                  end: -25,
                  top: -25,
                  child: Opacity(
                    opacity: 0.15,
                    child: Icon(icon, size: 140, color: Colors.white),
                  ),
                ),
                // Glassmorphism overlay
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
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
                // Content
                Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.25),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 10,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Icon(icon, color: Colors.white, size: 32),
                      ),
                      const Spacer(),
                      Text(
                        name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
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
                      const SizedBox(height: 6),
                      // Decorative accent line
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withValues(alpha: 0.5),
                              blurRadius: 6,
                              spreadRadius: 1,
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

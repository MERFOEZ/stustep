import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:animate_do/animate_do.dart';

class CoursesScreen extends StatelessWidget {
  const CoursesScreen({super.key});

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
              const Color(0xFF6200EE).withValues(alpha: 0.05),
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FadeInDown(
                duration: const Duration(milliseconds: 800),
                child: ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Color(0xFF6200EE), Color(0xFFE91E63)],
                  ).createShader(bounds),
                  child: Text(
                    'courses'.tr(),
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _buildCourseSection(context, 'Mathematics', [
                _Course(
                  title: 'Algebra 101',
                  instructor: 'Dr. Smith',
                  thumbnail: Icons.functions,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6200EE), Color(0xFF9C27B0)],
                  ),
                ),
                _Course(
                  title: 'Calculus Advanced',
                  instructor: 'Prof. Miller',
                  thumbnail: Icons.calculate,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFD500F9), Color(0xFFE040FB)],
                  ),
                ),
              ]),
              const SizedBox(height: 24),
              _buildCourseSection(context, 'Computer Science', [
                _Course(
                  title: 'Data Structures',
                  instructor: 'Grace Hopper',
                  thumbnail: Icons.code,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00C853), Color(0xFF00E676)],
                  ),
                ),
                _Course(
                  title: 'AI Fundamentals',
                  instructor: 'Alan Turing',
                  thumbnail: Icons.memory,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF1744), Color(0xFFFF5252)],
                  ),
                ),
                _Course(
                  title: 'Mobile Development',
                  instructor: 'Steve Jobs',
                  thumbnail: Icons.phone_android,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFAB00), Color(0xFFFFD54F)],
                  ),
                ),
              ]),
              const SizedBox(height: 24),
              _buildCourseSection(context, 'Business & Finance', [
                _Course(
                  title: 'Marketing 101',
                  instructor: 'Seth Godin',
                  thumbnail: Icons.trending_up,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00BCD4), Color(0xFF00E5FF)],
                  ),
                ),
                _Course(
                  title: 'Financial Analysis',
                  instructor: 'Warren Buffett',
                  thumbnail: Icons.account_balance,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF43A047), Color(0xFF66BB6A)],
                  ),
                ),
              ]),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCourseSection(
    BuildContext context,
    String category,
    List<_Course> courses,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FadeInLeft(
          duration: const Duration(milliseconds: 600),
          child: Text(
            category,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 210,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: courses.length,
            itemBuilder: (context, index) {
              final course = courses[index];
              return BounceInRight(
                delay: Duration(milliseconds: index * 150),
                duration: const Duration(milliseconds: 800),
                child: Container(
                  width: 180,
                  margin: const EdgeInsets.only(right: 16, bottom: 8),
                  decoration: BoxDecoration(
                    gradient: course.gradient,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: (course.gradient as LinearGradient).colors.first
                            .withValues(alpha: 0.4),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                        spreadRadius: 2,
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
                          Positioned(
                            right: -20,
                            top: -20,
                            child: Opacity(
                              opacity: 0.2,
                              child: Icon(
                                course.thumbnail,
                                size: 120,
                                color: Colors.white,
                              ),
                            ),
                          ),
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
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.3),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    course.thumbnail,
                                    size: 32,
                                    color: Colors.white,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  course.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
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
                                  course.instructor,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.white.withValues(alpha: 0.9),
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
      ],
    );
  }
}

class _Course {
  final String title;
  final String instructor;
  final IconData thumbnail;
  final Gradient gradient;

  _Course({
    required this.title,
    required this.instructor,
    required this.thumbnail,
    required this.gradient,
  });
}

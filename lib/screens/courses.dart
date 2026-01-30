import 'package:flutter/material.dart';

class CoursesScreen extends StatefulWidget {
  const CoursesScreen({super.key});

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen>
    with TickerProviderStateMixin {
  late AnimationController _headerAnimationController;
  late AnimationController _cardsAnimationController;
  late Animation<double> _headerAnimation;
  late Animation<double> _fadeAnimation;

  int _selectedCategoryIndex = 0;
  final ScrollController _scrollController = ScrollController();

  final List<String> _categories = [
    'الكل',
    'البرمجة',
    'التصميم',
    'الأعمال',
    'اللغات',
    'العلوم',
  ];

  final List<CourseData> _allCourses = [
    CourseData(
      title: 'Flutter المتقدم',
      instructor: 'أحمد محمد',
      rating: 4.9,
      students: 12500,
      duration: '25 ساعة',
      price: 199,
      originalPrice: 499,
      thumbnail: 'flutter',
      category: 'البرمجة',
      gradient: const [Color(0xFF667eea), Color(0xFF764ba2)],
      progress: 0.65,
      isEnrolled: true,
      lessons: 48,
      level: 'متقدم',
    ),
    CourseData(
      title: 'UI/UX Design Pro',
      instructor: 'سارة أحمد',
      rating: 4.8,
      students: 8700,
      duration: '18 ساعة',
      price: 149,
      originalPrice: 349,
      thumbnail: 'design',
      category: 'التصميم',
      gradient: const [Color(0xFFf093fb), Color(0xFFf5576c)],
      progress: 0.0,
      isEnrolled: false,
      lessons: 32,
      level: 'متوسط',
    ),
    CourseData(
      title: 'Python للذكاء الاصطناعي',
      instructor: 'خالد العمري',
      rating: 4.7,
      students: 15200,
      duration: '35 ساعة',
      price: 249,
      originalPrice: 599,
      thumbnail: 'python',
      category: 'البرمجة',
      gradient: const [Color(0xFF4facfe), Color(0xFF00f2fe)],
      progress: 0.25,
      isEnrolled: true,
      lessons: 64,
      level: 'متقدم',
    ),
    CourseData(
      title: 'إدارة المشاريع الاحترافية',
      instructor: 'نورا السعيد',
      rating: 4.6,
      students: 6300,
      duration: '12 ساعة',
      price: 99,
      originalPrice: 249,
      thumbnail: 'business',
      category: 'الأعمال',
      gradient: const [Color(0xFFfa709a), Color(0xFFfee140)],
      progress: 0.0,
      isEnrolled: false,
      lessons: 24,
      level: 'مبتدئ',
    ),
    CourseData(
      title: 'اللغة الإنجليزية للمحترفين',
      instructor: 'ليلى حسن',
      rating: 4.9,
      students: 22000,
      duration: '40 ساعة',
      price: 179,
      originalPrice: 399,
      thumbnail: 'english',
      category: 'اللغات',
      gradient: const [Color(0xFF11998e), Color(0xFF38ef7d)],
      progress: 0.80,
      isEnrolled: true,
      lessons: 80,
      level: 'جميع المستويات',
    ),
    CourseData(
      title: 'React & Next.js',
      instructor: 'عمر فاروق',
      rating: 4.8,
      students: 9800,
      duration: '28 ساعة',
      price: 189,
      originalPrice: 449,
      thumbnail: 'react',
      category: 'البرمجة',
      gradient: const [Color(0xFF6a11cb), Color(0xFF2575fc)],
      progress: 0.0,
      isEnrolled: false,
      lessons: 52,
      level: 'متوسط',
    ),
    CourseData(
      title: 'الفيزياء الحديثة',
      instructor: 'د. محمد علي',
      rating: 4.5,
      students: 4200,
      duration: '20 ساعة',
      price: 129,
      originalPrice: 299,
      thumbnail: 'physics',
      category: 'العلوم',
      gradient: const [Color(0xFFff6a00), Color(0xFFee0979)],
      progress: 0.0,
      isEnrolled: false,
      lessons: 36,
      level: 'متقدم',
    ),
    CourseData(
      title: 'التسويق الرقمي',
      instructor: 'هند الشامي',
      rating: 4.7,
      students: 11500,
      duration: '15 ساعة',
      price: 119,
      originalPrice: 279,
      thumbnail: 'marketing',
      category: 'الأعمال',
      gradient: const [Color(0xFFf857a6), Color(0xFFff5858)],
      progress: 0.45,
      isEnrolled: true,
      lessons: 28,
      level: 'مبتدئ',
    ),
  ];

  List<CourseData> get _filteredCourses {
    if (_selectedCategoryIndex == 0) return _allCourses;
    return _allCourses
        .where((c) => c.category == _categories[_selectedCategoryIndex])
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _headerAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _cardsAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _headerAnimation = CurvedAnimation(
      parent: _headerAnimationController,
      curve: Curves.easeOutBack,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _cardsAnimationController,
      curve: Curves.easeOut,
    );

    _headerAnimationController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      _cardsAnimationController.forward();
    });
  }

  @override
  void dispose() {
    _headerAnimationController.dispose();
    _cardsAnimationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1a1a2e), Color(0xFF16213e), Color(0xFF0f3460)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAnimatedHeader(),
              _buildSearchBar(),
              _buildCategoryTabs(),
              _buildStatsRow(),
              Expanded(child: _buildCoursesList()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedHeader() {
    return AnimatedBuilder(
      animation: _headerAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, -50 * (1 - _headerAnimation.value)),
          child: Opacity(
            opacity: _headerAnimation.value,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFf093fb), Color(0xFFf5576c)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFf093fb).withValues(alpha: 0.4),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.school_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'مرحباً بك في',
                        style: TextStyle(color: Colors.white60, fontSize: 14),
                      ),
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [Color(0xFFf093fb), Color(0xFFf5576c)],
                        ).createShader(bounds),
                        child: const Text(
                          'أكاديمية الكورسات',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  _buildNotificationBadge(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNotificationBadge() {
    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: const Icon(
            Icons.notifications_rounded,
            color: Colors.white,
            size: 24,
          ),
        ),
        Positioned(
          right: 8,
          top: 8,
          child: Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              color: Color(0xFFff4757),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: TextField(
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'ابحث عن كورس...',
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
            prefixIcon: Icon(
              Icons.search_rounded,
              color: Colors.white.withValues(alpha: 0.5),
            ),
            suffixIcon: Container(
              margin: const EdgeInsets.all(8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.tune_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 16,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryTabs() {
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final isSelected = _selectedCategoryIndex == index;
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedCategoryIndex = index;
              });
              _cardsAnimationController.reset();
              _cardsAnimationController.forward();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              margin: const EdgeInsets.symmetric(horizontal: 6),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? const LinearGradient(
                        colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                      )
                    : null,
                color: isSelected ? null : Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: isSelected
                      ? Colors.transparent
                      : Colors.white.withValues(alpha: 0.1),
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: const Color(0xFF667eea).withValues(alpha: 0.4),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ]
                    : null,
              ),
              child: Text(
                _categories[index],
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white70,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 14,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatsRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
      child: Row(
        children: [
          _buildStatItem(
            icon: Icons.play_circle_rounded,
            value: '${_filteredCourses.length}',
            label: 'كورس متاح',
            color: const Color(0xFF4facfe),
          ),
          const SizedBox(width: 16),
          _buildStatItem(
            icon: Icons.people_rounded,
            value: '50K+',
            label: 'طالب مسجل',
            color: const Color(0xFFf093fb),
          ),
          const SizedBox(width: 16),
          _buildStatItem(
            icon: Icons.star_rounded,
            value: '4.8',
            label: 'تقييم عام',
            color: const Color(0xFFfee140),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoursesList() {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          itemCount: _filteredCourses.length,
          itemBuilder: (context, index) {
            final course = _filteredCourses[index];
            return TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: Duration(milliseconds: 400 + (index * 100)),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset(0, 50 * (1 - value)),
                  child: Opacity(opacity: value, child: child),
                );
              },
              child: _buildCourseCard(course),
            );
          },
        );
      },
    );
  }

  Widget _buildCourseCard(CourseData course) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          // Course Header with Gradient
          Container(
            height: 140,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: course.gradient),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: Stack(
              children: [
                // Background Pattern
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                    child: CustomPaint(
                      painter: PatternPainter(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                  ),
                ),
                // Course Icon
                Positioned(
                  right: 20,
                  bottom: 20,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      _getCourseIcon(course.thumbnail),
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                ),
                // Level Badge
                Positioned(
                  left: 16,
                  top: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      course.level,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                // Enrolled Badge
                if (course.isEnrolled)
                  Positioned(
                    right: 16,
                    top: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF38ef7d),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Colors.white,
                            size: 14,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'مسجل',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Course Details
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        course.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFfee140).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            color: Color(0xFFfee140),
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            course.rating.toString(),
                            style: const TextStyle(
                              color: Color(0xFFfee140),
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: course.gradient[0],
                      child: Text(
                        course.instructor[0],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      course.instructor,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Course Meta Info
                Row(
                  children: [
                    _buildMetaChip(
                      Icons.play_lesson_rounded,
                      '${course.lessons} درس',
                    ),
                    const SizedBox(width: 12),
                    _buildMetaChip(Icons.access_time_rounded, course.duration),
                    const SizedBox(width: 12),
                    _buildMetaChip(
                      Icons.people_outline_rounded,
                      _formatStudents(course.students),
                    ),
                  ],
                ),
                if (course.isEnrolled && course.progress > 0) ...[
                  const SizedBox(height: 16),
                  // Progress Bar
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'التقدم',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            '${(course.progress * 100).toInt()}%',
                            style: TextStyle(
                              color: course.gradient[0],
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Stack(
                        children: [
                          Container(
                            height: 6,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          FractionallySizedBox(
                            widthFactor: course.progress,
                            child: Container(
                              height: 6,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: course.gradient,
                                ),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                // Price and CTA
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!course.isEnrolled)
                          Text(
                            '\$${course.originalPrice}',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 14,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        Text(
                          course.isEnrolled ? 'مسجل' : '\$${course.price}',
                          style: TextStyle(
                            color: course.isEnrolled
                                ? const Color(0xFF38ef7d)
                                : Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: course.gradient),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: course.gradient[0].withValues(alpha: 0.4),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {},
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 14,
                            ),
                            child: Row(
                              children: [
                                Text(
                                  course.isEnrolled ? 'متابعة' : 'اشترك الآن',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  course.isEnrolled
                                      ? Icons.play_arrow_rounded
                                      : Icons.arrow_forward_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white.withValues(alpha: 0.7), size: 14),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  String _formatStudents(int count) {
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }

  IconData _getCourseIcon(String type) {
    switch (type) {
      case 'flutter':
        return Icons.flutter_dash;
      case 'design':
        return Icons.palette_rounded;
      case 'python':
        return Icons.code_rounded;
      case 'business':
        return Icons.business_center_rounded;
      case 'english':
        return Icons.language_rounded;
      case 'react':
        return Icons.web_rounded;
      case 'physics':
        return Icons.science_rounded;
      case 'marketing':
        return Icons.campaign_rounded;
      default:
        return Icons.school_rounded;
    }
  }
}

// Course Data Model
class CourseData {
  final String title;
  final String instructor;
  final double rating;
  final int students;
  final String duration;
  final int price;
  final int originalPrice;
  final String thumbnail;
  final String category;
  final List<Color> gradient;
  final double progress;
  final bool isEnrolled;
  final int lessons;
  final String level;

  CourseData({
    required this.title,
    required this.instructor,
    required this.rating,
    required this.students,
    required this.duration,
    required this.price,
    required this.originalPrice,
    required this.thumbnail,
    required this.category,
    required this.gradient,
    required this.progress,
    required this.isEnrolled,
    required this.lessons,
    required this.level,
  });
}

// Custom Pattern Painter for Background
class PatternPainter extends CustomPainter {
  final Color color;

  PatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    const spacing = 30.0;

    for (var i = 0.0; i < size.width + size.height; i += spacing) {
      canvas.drawLine(Offset(i, 0), Offset(0, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

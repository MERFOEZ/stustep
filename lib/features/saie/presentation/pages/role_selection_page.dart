library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stustep/features/saie/presentation/pages/career_job_assessments_page.dart';
import 'package:stustep/features/saie/presentation/pages/graduate_assessment_page.dart';
import 'package:stustep/features/saie/presentation/pages/riasec_assessment_page.dart';

// ─────────────────────────────────────────────────────────────────────────────
// UserRole
// ─────────────────────────────────────────────────────────────────────────────

enum UserRole {
  student(
    titleAr: 'للطلاب',
    subtitleAr: 'اختر تخصصك الجامعي بثقة بناءً على اهتماماتك الحقيقية،\nاكتشف التخصصات والجامعات التي تناسبك',
    ctaAr: 'ابدأ اكتشاف تخصصك',
    introAr:
        'مرحباً! 👋 أنا مستشارك الأكاديمي الذكي.\n\n'
        'سأساعدك في اكتشاف التخصص الجامعي الأنسب لك — بناءً على اهتماماتك الحقيقية وأسلوب تفكيرك، لا على الدرجات فقط.\n\n'
        'سأسألك أسئلة قصيرة عن أشياء تفعلها أو تحبها في حياتك اليومية. فقط أجبني بصراحة — لا توجد إجابات صح أو خطأ. 😊\n\n'
        '📝 لنبدأ:\nهل تستمتع بإصلاح الأجهزة أو الآلات أو تجميع الأشياء بيديك؟ هل جربت ذلك من قبل؟',
    icon: Icons.school_rounded,
    gradientStart: Color(0xFF1A4A7C),
    gradientEnd: Color(0xFF2471A3),
    storageKey: 'student',
  ),
  graduate(
    titleAr: 'للخريجين',
    subtitleAr: 'حوّل شهادتك الجامعية إلى فرصة عمل حقيقية،\nاكتشف الوظائف التي تطلبها سوق العمل',
    ctaAr: 'اكتشف الوظائف المناسبة',
    introAr:
        'أهلاً بك! أنا مستشارك المهني الذكي. سأساعدك في اكتشاف الوظائف التي تناسب مؤهلك وميولك الحقيقية في سوق العمل.',
    icon: Icons.workspace_premium_rounded,
    gradientStart: Color(0xFF0E5E38),
    gradientEnd: Color(0xFF1E8449),
    storageKey: 'graduate',
  ),
  careerChanger(
    titleAr: 'لمحوّلي المسار المهني',
    subtitleAr: 'اكتشف الفجوة المهارية بين وظيفتك الحالية والمستهدفة،\nوارسم خطة انتقال واضحة',
    ctaAr: 'خطّط لانتقالك المهني',
    introAr:
        'أهلاً بك! أنا مستشارك الذكي لتحويل المسار. سأساعدك في تحديد الفجوة بين وظيفتك الحالية والهدف الجديد، وبناء خطة واضحة للانتقال.',
    icon: Icons.swap_horiz_rounded,
    gradientStart: Color(0xFF4A1862),
    gradientEnd: Color(0xFF7D3C98),
    storageKey: 'career_changer',
  ),
  jobSeeker(
    titleAr: 'للباحثين عن عمل',
    subtitleAr: 'حدد المهارات المطلوبة في الوظائف التي تناسبك،\nواحصل على شهادات مهنية تعزز سيرتك الذاتية',
    ctaAr: 'طوّر مهاراتك الآن',
    introAr:
        'أهلاً بك! أنا مستشارك الذكي للتوظيف. سأساعدك في تحديد المهارات التي تحتاجها للوظائف التي تستهدفها وأفضل مسار لتطوير نفسك.',
    icon: Icons.work_rounded,
    gradientStart: Color(0xFF7D4114),
    gradientEnd: Color(0xFFBA4A00),
    storageKey: 'job_seeker',
  );

  const UserRole({
    required this.titleAr,
    required this.subtitleAr,
    required this.ctaAr,
    required this.introAr,
    required this.icon,
    required this.gradientStart,
    required this.gradientEnd,
    required this.storageKey,
  });

  final String titleAr;
  final String subtitleAr;
  final String ctaAr;
  final String introAr;
  final IconData icon;
  final Color gradientStart;
  final Color gradientEnd;
  final String storageKey;
}

// ─────────────────────────────────────────────────────────────────────────────
// RoleSelectionPage
// ─────────────────────────────────────────────────────────────────────────────

class RoleSelectionPage extends ConsumerWidget {
  const RoleSelectionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1620),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── Header ─────────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 36, 24, 0),
                child: Column(
                  children: [
                    // Logo glow
                    Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2196F3), Color(0xFF0D47A1)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF2196F3).withAlpha(90),
                            blurRadius: 24,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.psychology_rounded,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'StuStep',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'المستشار الأكاديمي والمهني الذكي',
                      style: TextStyle(
                        color: Color(0xFF7FA8C9),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 28),
                    // Divider
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 1,
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.transparent, Color(0xFF2A3F55)],
                              ),
                            ),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'ما الذي يصفك أكثر؟',
                            style: TextStyle(
                              color: Color(0xFF7FA8C9),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            height: 1,
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFF2A3F55), Colors.transparent],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // ── Role Cards ─────────────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _RoleCard(role: UserRole.graduate)),
                      const SizedBox(width: 12),
                      Expanded(child: _RoleCard(role: UserRole.student)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _RoleCard(role: UserRole.jobSeeker)),
                      const SizedBox(width: 12),
                      Expanded(child: _RoleCard(role: UserRole.careerChanger)),
                    ],
                  ),
                ]),
              ),
            ),

            // ── Footer ─────────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.lock_outline_rounded,
                      size: 13,
                      color: Colors.white.withAlpha(60),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'إجاباتك خاصة وتُستخدم فقط لتحسين توصياتك',
                      style: TextStyle(
                        color: Colors.white.withAlpha(60),
                        fontSize: 11.5,
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
}

// ─────────────────────────────────────────────────────────────────────────────
// _RoleCard
// ─────────────────────────────────────────────────────────────────────────────

class _RoleCard extends ConsumerStatefulWidget {
  const _RoleCard({required this.role});
  final UserRole role;

  @override
  ConsumerState<_RoleCard> createState() => _RoleCardState();
}

class _RoleCardState extends ConsumerState<_RoleCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 110),
      lowerBound: 0.0,
      upperBound: 1.0,
    );
    _scale = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _onTap() async {
    if (_loading) return;
    await _ctrl.forward();
    await _ctrl.reverse();
    if (!mounted) return;

    Widget destination;
    switch (widget.role) {
      case UserRole.student:
        destination = const RiasecAssessmentPage();
      case UserRole.graduate:
        destination = const GraduateAssessmentPage();
      case UserRole.careerChanger:
        destination = const CareerChangerAssessmentPage();
      case UserRole.jobSeeker:
        destination = const JobSeekerAssessmentPage();
    }

    Navigator.of(context).push(
      PageRouteBuilder<void>(
        pageBuilder: (_, anim, __) => destination,
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final role = widget.role;

    return ScaleTransition(
      scale: _scale,
      child: GestureDetector(
        onTap: _onTap,
        child: Container(
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [role.gradientStart, role.gradientEnd],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: role.gradientEnd.withAlpha(70),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Subtle background icon
              Positioned(
                left: -18,
                bottom: -14,
                child: Icon(
                  role.icon,
                  size: 110,
                  color: Colors.white.withAlpha(16),
                ),
              ),
              // Top-right accent circle
              Positioned(
                top: -30,
                right: -30,
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withAlpha(12),
                  ),
                ),
              ),

              // ── Card Content ──────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icon badge
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(28),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Icon(role.icon, color: Colors.white, size: 20),
                    ),

                    const SizedBox(height: 8),

                    // Title
                    Text(
                      role.titleAr,
                      textDirection: TextDirection.rtl,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 5),

                    // Subtitle
                    Text(
                      role.subtitleAr,
                      textDirection: TextDirection.rtl,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withAlpha(185),
                        fontSize: 10.5,
                        height: 1.45,
                      ),
                    ),

                    const SizedBox(height: 10),

                    // CTA
                    if (_loading)
                      Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white.withAlpha(200),
                            strokeWidth: 2,
                          ),
                        ),
                      )
                    else
                      Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(30),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withAlpha(55),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                role.ctaAr,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.arrow_back_ios_rounded,
                                color: Colors.white,
                                size: 10,
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

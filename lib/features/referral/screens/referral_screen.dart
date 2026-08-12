import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../providers/referral_provider.dart';
import '../widgets/referral_share_card.dart';
import '../widgets/referral_stats_card.dart';
import '../models/referral_model.dart';

class ReferralScreen extends StatefulWidget {
  const ReferralScreen({super.key});

  @override
  State<ReferralScreen> createState() => _ReferralScreenState();
}

class _ReferralScreenState extends State<ReferralScreen> {
  final TextEditingController _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _handleApplyCode() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) return;

    final refProvider = context.read<ReferralProvider>();
    final result = await refProvider.applyReferralCode(code);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? ''),
          backgroundColor: (result['success'] == true) ? const Color(0xFF00C853) : Colors.red,
        ),
      );
      if (result['success'] == true) {
        _codeController.clear();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final refProvider = context.watch<ReferralProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'referral.title'.tr(),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: refProvider.isLoading && refProvider.referralCode.isEmpty
          ? Center(
              child: SpinKitFadingCircle(
                color: Theme.of(context).primaryColor,
                size: 40,
              ),
            )
          : RefreshIndicator(
              onRefresh: () => refProvider.fetchStats(),
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                children: [
                  // Referral Share Card
                  const ReferralShareCard(),
                  const SizedBox(height: 16),

                  // Stats Counters
                  ReferralStatsCard(
                    totalInvited: refProvider.totalInvited,
                    activeReferrals: refProvider.activeReferrals,
                    totalPointsEarned: refProvider.totalPointsEarned,
                  ),
                  const SizedBox(height: 22),

                  // How it works steps
                  Text(
                    'referral.how_it_works'.tr(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildStepCard(
                    context,
                    stepNumber: '1',
                    title: 'referral.step_1_title'.tr(),
                    description: 'referral.step_1_desc'.tr(),
                    points: '+10',
                    color: const Color(0xFF00B0FF),
                  ),
                  const SizedBox(height: 10),
                  _buildStepCard(
                    context,
                    stepNumber: '2',
                    title: 'referral.step_2_title'.tr(),
                    description: 'referral.step_2_desc'.tr(),
                    points: '+30',
                    color: const Color(0xFF00E676),
                  ),
                  const SizedBox(height: 10),
                  _buildStepCard(
                    context,
                    stepNumber: '3',
                    title: 'referral.step_3_title'.tr(),
                    description: 'referral.step_3_desc'.tr(),
                    points: '+50',
                    color: const Color(0xFFFF9100),
                  ),
                  const SizedBox(height: 24),

                  // Enter a code section
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'referral.have_a_code'.tr(),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _codeController,
                                textCapitalization: TextCapitalization.characters,
                                decoration: InputDecoration(
                                  hintText: 'referral.code_placeholder'.tr(),
                                  filled: true,
                                  fillColor: isDark ? Colors.white10 : Colors.grey.shade100,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            ElevatedButton(
                              onPressed: refProvider.isApplying ? null : _handleApplyCode,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).primaryColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: refProvider.isApplying
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : Text('referral.apply'.tr()),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Invited friends list
                  Text(
                    'referral.invited_friends'.tr(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (refProvider.referrals.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(28),
                      alignment: Alignment.center,
                      child: Text(
                        'referral.no_referrals_yet'.tr(),
                        style: TextStyle(
                          color: isDark ? Colors.white60 : Colors.black45,
                          fontSize: 13,
                        ),
                      ),
                    )
                  else
                    ...refProvider.referrals.map((r) => _buildReferralTile(context, r, isDark)),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildStepCard(
    BuildContext context, {
    required String stepNumber,
    required String title,
    required String description,
    required String points,
    required Color color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              stepNumber,
              style: TextStyle(
                color: color,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$points ${'points.pts'.tr()}',
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReferralTile(BuildContext context, ReferralModel referral, bool isDark) {
    Color statusColor;
    String statusLabelKey;

    switch (referral.status) {
      case 'activated':
        statusColor = const Color(0xFF00B0FF);
        statusLabelKey = 'referral.status_activated';
        break;
      case 'rewarded':
        statusColor = const Color(0xFF00C853);
        statusLabelKey = 'referral.status_rewarded';
        break;
      case 'suspicious':
        statusColor = Colors.red;
        statusLabelKey = 'referral.status_suspicious';
        break;
      case 'expired':
        statusColor = Colors.grey;
        statusLabelKey = 'referral.status_expired';
        break;
      case 'pending':
      default:
        statusColor = const Color(0xFFFF9100);
        statusLabelKey = 'referral.status_pending';
        break;
    }

    final dateFormat = DateFormat('yyyy-MM-dd');

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: statusColor.withValues(alpha: 0.15),
                child: Icon(Icons.person_rounded, color: statusColor, size: 18),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${'referral.friend'.tr()} #${referral.referredId.substring(0, referral.referredId.length > 5 ? 5 : referral.referredId.length)}',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    dateFormat.format(referral.createdAt),
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
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              statusLabelKey.tr(),
              style: TextStyle(
                color: statusColor,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

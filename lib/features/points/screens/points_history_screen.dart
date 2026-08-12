import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../providers/points_provider.dart';
import '../models/points_transaction_model.dart';

class PointsHistoryScreen extends StatefulWidget {
  const PointsHistoryScreen({super.key});

  @override
  State<PointsHistoryScreen> createState() => _PointsHistoryScreenState();
}

class _PointsHistoryScreenState extends State<PointsHistoryScreen> {
  String _selectedFilter = 'all'; // 'all' | 'earn' | 'spend'

  @override
  Widget build(BuildContext context) {
    final pointsProvider = context.watch<PointsProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filteredTransactions = pointsProvider.transactions.where((tx) {
      if (_selectedFilter == 'all') return true;
      return tx.type == _selectedFilter;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'transactions.title'.tr(),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Filter Chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                _buildFilterChip('all', 'all'.tr().isNotEmpty ? 'الكل' : 'All'),
                const SizedBox(width: 8),
                _buildFilterChip('earn', 'transactions.type_earn'.tr()),
                const SizedBox(width: 8),
                _buildFilterChip('spend', 'transactions.type_spend'.tr()),
              ],
            ),
          ),
          const Divider(height: 1),
          // Transactions List
          Expanded(
            child: filteredTransactions.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long_rounded,
                          size: 48,
                          color: Colors.grey.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'transactions.no_transactions'.tr(),
                          style: TextStyle(
                            color: isDark ? Colors.white60 : Colors.black54,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    itemCount: filteredTransactions.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final tx = filteredTransactions[index];
                      return _buildTransactionCard(context, tx, isDark);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String filterKey, String label) {
    final isSelected = _selectedFilter == filterKey;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedFilter = filterKey;
          });
        }
      },
      selectedColor: Theme.of(context).primaryColor,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : null,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 13,
      ),
    );
  }

  Widget _buildTransactionCard(BuildContext context, PointsTransactionModel tx, bool isDark) {
    final isEarn = tx.type == 'earn';
    final dateFormat = DateFormat('yyyy-MM-dd  hh:mm a');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isEarn
                  ? const Color(0xFF00E676).withValues(alpha: 0.14)
                  : Colors.red.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isEarn ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
              color: isEarn ? const Color(0xFF00C853) : Colors.red,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getSourceLabel(tx.source),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  dateFormat.format(tx.timestamp),
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white54 : Colors.black45,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${isEarn ? '+' : '-'}${tx.amount} ${'points.pts'.tr()}',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: isEarn ? const Color(0xFF00C853) : Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  String _getSourceLabel(String source) {
    if (source.startsWith('activity_')) {
      return 'transactions.source_activity'.tr();
    } else if (source.contains('quest')) {
      return 'transactions.source_quest'.tr();
    } else if (source.contains('referral')) {
      return 'transactions.source_referral'.tr();
    }
    return source;
  }
}

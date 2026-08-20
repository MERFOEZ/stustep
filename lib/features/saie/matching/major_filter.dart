/// SAIE — MajorFilter
///
/// Determines which majors from the knowledge base are eligible to be
/// evaluated in a matching run. Supports hidden/visible, category, difficulty,
/// and university-specific filtering.
library;

import 'package:stustep/features/saie/core/enums.dart';
import 'package:stustep/features/saie/matching/matching_configuration.dart';
import 'package:stustep/features/saie/models/major.dart';
import 'package:equatable/equatable.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MajorFilterCriteria
// ─────────────────────────────────────────────────────────────────────────────

/// Optional narrowing criteria applied on top of the base configuration.
final class MajorFilterCriteria extends Equatable {
  /// If non-null, only include majors in these categories.
  final List<MajorCategory>? categories;

  /// If non-null, only include majors with at least one of these tags.
  final List<String>? requiredTags;

  /// If non-null, only include majors whose IDs are in this set.
  final Set<String>? allowedMajorIds;

  /// If non-null, exclude these major IDs entirely.
  final Set<String>? excludedMajorIds;

  /// If non-null, only include majors with marketDemand >= this value.
  final double? minimumMarketDemand;

  const MajorFilterCriteria({
    this.categories,
    this.requiredTags,
    this.allowedMajorIds,
    this.excludedMajorIds,
    this.minimumMarketDemand,
  });

  static const MajorFilterCriteria none = MajorFilterCriteria();

  MajorFilterCriteria copyWith({
    List<MajorCategory>? categories,
    List<String>? requiredTags,
    Set<String>? allowedMajorIds,
    Set<String>? excludedMajorIds,
    double? minimumMarketDemand,
  }) => MajorFilterCriteria(
    categories: categories ?? this.categories,
    requiredTags: requiredTags ?? this.requiredTags,
    allowedMajorIds: allowedMajorIds ?? this.allowedMajorIds,
    excludedMajorIds: excludedMajorIds ?? this.excludedMajorIds,
    minimumMarketDemand: minimumMarketDemand ?? this.minimumMarketDemand,
  );

  @override
  List<Object?> get props => [
    categories,
    requiredTags,
    allowedMajorIds,
    excludedMajorIds,
    minimumMarketDemand,
  ];
}

// ─────────────────────────────────────────────────────────────────────────────
// MajorFilter
// ─────────────────────────────────────────────────────────────────────────────

/// Stateless filter that narrows the set of majors before scoring.
final class MajorFilter {
  const MajorFilter();

  /// Returns the subset of [allMajors] eligible for matching.
  ///
  /// Uses [config] for hidden/visible settings and [criteria] for optional
  /// additional constraints.
  List<Major> apply({
    required List<Major> allMajors,
    required MatchingConfiguration config,
    MajorFilterCriteria criteria = MajorFilterCriteria.none,
  }) {
    final result = <Major>[];

    for (final major in allMajors) {
      // Hidden filter — skip hidden majors unless config allows them.
      if (!config.includeHidden && major.tags.contains('hidden')) continue;

      // Allowed-IDs allow list.
      if (criteria.allowedMajorIds != null &&
          !criteria.allowedMajorIds!.contains(major.id)) {
        continue;
      }

      // Excluded-IDs block list.
      if (criteria.excludedMajorIds != null &&
          criteria.excludedMajorIds!.contains(major.id)) {
        continue;
      }

      // Category filter.
      if (criteria.categories != null &&
          !criteria.categories!.contains(major.category)) {
        continue;
      }

      // Tag filter — at least one required tag must be present.
      if (criteria.requiredTags != null &&
          criteria.requiredTags!.isNotEmpty) {
        final hasTag = criteria.requiredTags!.any(
          (t) => major.tags.contains(t),
        );
        if (!hasTag) continue;
      }

      // Market demand filter.
      if (criteria.minimumMarketDemand != null &&
          major.marketDemand < criteria.minimumMarketDemand!) {
        continue;
      }

      result.add(major);
    }

    return result;
  }
}

/// Pure-Dart inference for the no-show model (P4-09, P4-10).
///
/// Loads `assets/models/no_show_model.json` (trained offline by
/// tools/ml/train_no_show.py), scales the feature vector with the exported
/// StandardScaler params, applies the logistic regression, and returns a
/// probability + risk band. A linear model gives per-feature contributions for
/// free — the explainability story.
library;

import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/services.dart' show rootBundle;

import '../../domain/enums.dart';

class FeatureContribution {
  const FeatureContribution({
    required this.name,
    required this.value,
    required this.contribution,
  });

  final String name;
  final double value;

  /// `coef * (value - mean) / scale` — signed effect on the log-odds.
  final double contribution;
}

class NoShowPrediction {
  const NoShowPrediction({
    required this.probability,
    required this.band,
    required this.contributions,
  });

  final double probability;
  final RiskBand band;

  /// Sorted by absolute effect, largest first.
  final List<FeatureContribution> contributions;
}

class NoShowModel {
  NoShowModel({
    required this.version,
    required this.featureNames,
    required this.coef,
    required this.intercept,
    required this.scalerMean,
    required this.scalerScale,
    required this.lowBand,
    required this.mediumBand,
  });

  factory NoShowModel.fromJson(Map<String, dynamic> json) {
    List<double> nums(Object? node) =>
        (node as List).map((e) => (e as num).toDouble()).toList();
    final bands = json['riskBands'] as Map<String, dynamic>;
    return NoShowModel(
      version: json['modelVersion'] as String,
      featureNames: (json['featureNames'] as List).cast<String>(),
      coef: nums(json['coef']),
      intercept: (json['intercept'] as num).toDouble(),
      scalerMean: nums(json['scalerMean']),
      scalerScale: nums(json['scalerScale']),
      lowBand: (bands['low'] as num).toDouble(),
      mediumBand: (bands['medium'] as num).toDouble(),
    );
  }

  final String version;
  final List<String> featureNames;
  final List<double> coef;
  final double intercept;
  final List<double> scalerMean;
  final List<double> scalerScale;
  final double lowBand;
  final double mediumBand;

  static const assetPath = 'assets/models/no_show_model.json';

  static Future<NoShowModel> load() async {
    final raw = await rootBundle.loadString(assetPath);
    return NoShowModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  NoShowPrediction predict(List<double> features) {
    assert(features.length == coef.length, 'feature/coef length mismatch');

    var z = intercept;
    final contributions = <FeatureContribution>[];
    for (var i = 0; i < features.length; i++) {
      final scaled = (features[i] - scalerMean[i]) / scalerScale[i];
      final c = coef[i] * scaled;
      z += c;
      contributions.add(
        FeatureContribution(
          name: featureNames[i],
          value: features[i],
          contribution: c,
        ),
      );
    }
    contributions.sort(
      (a, b) => b.contribution.abs().compareTo(a.contribution.abs()),
    );

    final p = 1.0 / (1.0 + math.exp(-z));
    return NoShowPrediction(
      probability: p,
      band: bandFor(p),
      contributions: contributions,
    );
  }

  RiskBand bandFor(double probability) {
    if (probability > mediumBand) return RiskBand.high;
    if (probability >= lowBand) return RiskBand.medium;
    return RiskBand.low;
  }
}

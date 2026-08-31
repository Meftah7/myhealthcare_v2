// Python ↔ Dart parity for the no-show model (P4-11).
//
// tools/ml/export_parity.py froze a set of (feature vector -> probability)
// cases from the trained model. The Dart predictor must reproduce each
// probability within 1e-6, or the exported weights are wrong.

import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:myhealthcare/services/ml/feature_extractor.dart';
import 'package:myhealthcare/services/ml/no_show_predictor.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late NoShowModel model;
  late Map<String, dynamic> parity;

  setUpAll(() async {
    final modelJson = File(
      'assets/models/no_show_model.json',
    ).readAsStringSync();
    model = NoShowModel.fromJson(jsonDecode(modelJson) as Map<String, dynamic>);
    parity =
        jsonDecode(File('test/support/parity_cases.json').readAsStringSync())
            as Map<String, dynamic>;
  });

  test('feature order matches the trained model', () {
    expect(model.featureNames, noShowFeatureNames);
    expect((parity['featureNames'] as List).cast<String>(), noShowFeatureNames);
    expect(parity['modelVersion'], model.version);
  });

  test('Dart inference matches Python within 1e-6 on every frozen case', () {
    final cases = parity['cases'] as List;
    for (final c in cases) {
      final m = c as Map<String, dynamic>;
      final features = (m['features'] as List)
          .map((e) => (e as num).toDouble())
          .toList();
      final expected = (m['probability'] as num).toDouble();

      final got = model.predict(features).probability;
      expect(got, closeTo(expected, 1e-6), reason: 'features $features');
    }
  });

  test('risk bands follow the exported thresholds', () {
    expect(model.bandFor(0.10).name, 'low');
    expect(model.bandFor(0.50).name, 'medium');
    expect(model.bandFor(0.90).name, 'high');
  });

  test('contributions sum (with intercept) to the logit', () {
    final features =
        ((parity['cases'] as List).first as Map<String, dynamic>)['features']
            as List;
    final vec = features.map((e) => (e as num).toDouble()).toList();
    final pred = model.predict(vec);
    final z =
        model.intercept +
        pred.contributions.fold<double>(0, (s, c) => s + c.contribution);
    final p = 1 / (1 + math.exp(-z));
    expect(p, closeTo(pred.probability, 1e-9));
  });
}

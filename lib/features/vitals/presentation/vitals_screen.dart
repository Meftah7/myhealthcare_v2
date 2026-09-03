/// Vitals — charts (P2-15), recent readings, and manual entry (P2-14).
library;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/theme.dart';
import '../../../core/di.dart';
import '../../../core/presentation/app_card.dart';
import '../../../core/presentation/states.dart';
import '../../../core/utils/format.dart';
import '../../../domain/entities/entities.dart';
import '../../auth/application/session.dart';
import '../../patient/application/patient_data_providers.dart';

class VitalsScreen extends ConsumerWidget {
  const VitalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vitals = ref.watch(patientVitalsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Vitals')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEntrySheet(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Add reading'),
      ),
      body: vitals.when(
        loading: () => const SkeletonList(),
        error: (e, _) => ErrorStateView(
          message: 'Could not load vitals.',
          onRetry: () => ref.invalidate(patientVitalsProvider),
        ),
        data: (list) {
          if (list.isEmpty) {
            return const EmptyState(
              icon: Icons.monitor_heart_outlined,
              message: 'No vitals recorded yet.\nTap "Add reading" to start.',
            );
          }
          final sorted = [...list]
            ..sort((a, b) => a.recordedAt.compareTo(b.recordedAt));
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: Space.maxContentWidth,
              ),
              child: ListView(
            padding: const EdgeInsets.fromLTRB(
              Space.md,
              Space.sm,
              Space.md,
              Space.xxl,
            ),
            children: [
              _VitalsChart(
                title: 'Blood pressure',
                unit: 'mmHg',
                series: [
                  _Series('Systolic', [
                    for (final v in sorted)
                      if (v.systolic != null)
                        _P(v.recordedAt, v.systolic!.toDouble()),
                  ]),
                  _Series('Diastolic', [
                    for (final v in sorted)
                      if (v.diastolic != null)
                        _P(v.recordedAt, v.diastolic!.toDouble()),
                  ]),
                ],
              ),
              _VitalsChart(
                title: 'Weight',
                unit: 'kg',
                series: [
                  _Series('Weight', [
                    for (final v in sorted)
                      if (v.weightKg != null) _P(v.recordedAt, v.weightKg!),
                  ]),
                ],
              ),
              _VitalsChart(
                title: 'Glucose',
                unit: 'mmol/L',
                series: [
                  _Series('Glucose', [
                    for (final v in sorted)
                      if (v.glucose != null) _P(v.recordedAt, v.glucose!),
                  ]),
                ],
              ),
              const SizedBox(height: Space.md),
              const SectionHeader('Recent readings', overline: true),
              AppCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    for (var i = 0; i < sorted.length && i < 15; i++) ...[
                      if (i > 0)
                        const Divider(height: 1, indent: Space.md),
                      _ReadingTile(sorted[sorted.length - 1 - i]),
                    ],
                  ],
                ),
              ),
            ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _P {
  const _P(this.at, this.value);
  final DateTime at;
  final double value;
}

class _Series {
  const _Series(this.label, this.points);
  final String label;
  final List<_P> points;
}

class _VitalsChart extends StatelessWidget {
  const _VitalsChart({
    required this.title,
    required this.unit,
    required this.series,
  });

  final String title;
  final String unit;
  final List<_Series> series;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final all = series.expand((s) => s.points).toList();
    if (all.length < 2) return const SizedBox.shrink();

    final minX = all
        .map((p) => p.at.millisecondsSinceEpoch)
        .reduce((a, b) => a < b ? a : b);
    final maxX = all
        .map((p) => p.at.millisecondsSinceEpoch)
        .reduce((a, b) => a > b ? a : b);
    final colors = [theme.colorScheme.primary, theme.colorScheme.tertiary];

    return Padding(
      padding: const EdgeInsets.only(bottom: Space.sm),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$title  ·  $unit', style: theme.textTheme.titleMedium),
            const SizedBox(height: Space.md),
            SizedBox(
              height: 160,
              child: LineChart(
                LineChartData(
                  minX: minX.toDouble(),
                  maxX: maxX.toDouble(),
                  gridData: FlGridData(
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (_) => FlLine(
                      color: theme.colorScheme.outlineVariant,
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(),
                    rightTitles: const AxisTitles(),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 36,
                        getTitlesWidget: (v, meta) => Text(
                          v.toStringAsFixed(0),
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        interval: ((maxX - minX) / 3).clamp(1, double.infinity),
                        getTitlesWidget: (v, meta) => Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            fmtDate(
                              DateTime.fromMillisecondsSinceEpoch(v.toInt()),
                            ),
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    for (var i = 0; i < series.length; i++)
                      LineChartBarData(
                        isCurved: true,
                        color: colors[i % colors.length],
                        dotData: const FlDotData(show: false),
                        spots: [
                          for (final p in series[i].points)
                            FlSpot(
                              p.at.millisecondsSinceEpoch.toDouble(),
                              p.value,
                            ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            if (series.length > 1)
              Padding(
                padding: const EdgeInsets.only(top: Space.xs),
                child: Wrap(
                  spacing: Space.md,
                  children: [
                    for (var i = 0; i < series.length; i++)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: colors[i % colors.length],
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: Space.xxs),
                          Text(
                            series[i].label,
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ReadingTile extends StatelessWidget {
  const _ReadingTile(this.v);
  final Vitals v;
  @override
  Widget build(BuildContext context) {
    final parts = <String>[
      if (v.hasBloodPressure) 'BP ${v.systolic}/${v.diastolic}',
      if (v.heartRate != null) 'HR ${v.heartRate}',
      if (v.spo2 != null) 'SpO₂ ${v.spo2}%',
      if (v.weightKg != null) '${v.weightKg} kg',
      if (v.glucose != null) 'Glucose ${v.glucose}',
      if (v.tempC != null) '${v.tempC} °C',
    ];
    return ListTile(
      dense: true,
      title: Text(fmtDateTime(v.recordedAt)),
      subtitle: Text(parts.join('   ')),
    );
  }
}

Future<void> _openEntrySheet(BuildContext context, WidgetRef ref) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: _VitalsEntryForm(
        onSave: (vitals) async {
          await ref.read(vitalsRepositoryProvider).add(vitals);
          ref.invalidate(patientVitalsProvider);
        },
      ),
    ),
  );
}

class _VitalsEntryForm extends ConsumerStatefulWidget {
  const _VitalsEntryForm({required this.onSave});
  final Future<void> Function(Vitals) onSave;

  @override
  ConsumerState<_VitalsEntryForm> createState() => _VitalsEntryFormState();
}

class _VitalsEntryFormState extends ConsumerState<_VitalsEntryForm> {
  final _fields = <String, TextEditingController>{
    for (final k in [
      'Systolic',
      'Diastolic',
      'Heart rate',
      'SpO2',
      'Weight (kg)',
      'Glucose',
      'Temp (°C)',
    ])
      k: TextEditingController(),
  };
  bool _busy = false;

  @override
  void dispose() {
    for (final c in _fields.values) {
      c.dispose();
    }
    super.dispose();
  }

  int? _int(String k) => int.tryParse(_fields[k]!.text.trim());
  double? _dbl(String k) => double.tryParse(_fields[k]!.text.trim());

  Future<void> _save() async {
    setState(() => _busy = true);
    final user = ref.read(currentUserProvider)!;
    await widget.onSave(
      Vitals(
        id: '',
        patientId: user.id,
        recordedAt: DateTime.now(),
        systolic: _int('Systolic'),
        diastolic: _int('Diastolic'),
        heartRate: _int('Heart rate'),
        spo2: _int('SpO2'),
        weightKg: _dbl('Weight (kg)'),
        glucose: _dbl('Glucose'),
        tempC: _dbl('Temp (°C)'),
      ),
    );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(Space.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('New reading', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: Space.md),
          Wrap(
            spacing: Space.sm,
            runSpacing: Space.sm,
            children: [
              for (final entry in _fields.entries)
                SizedBox(
                  width: 150,
                  child: TextField(
                    controller: entry.value,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(labelText: entry.key),
                  ),
                ),
            ],
          ),
          const SizedBox(height: Space.lg),
          FilledButton(
            onPressed: _busy ? null : _save,
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

/// Health Records — the patient's clinical history, in two views:
/// their visit timeline and their medications, chosen with a top toggle.
library;

import 'package:flutter/material.dart';

import '../../../app/theme/theme.dart';
import '../../billing/presentation/billing_screen.dart';
import '../../records/presentation/medications_screen.dart';
import 'timeline_screen.dart';

enum _RecordsView { timeline, medications, bills }

class HealthRecordsScreen extends StatefulWidget {
  const HealthRecordsScreen({this.startOnMedications = false, super.key});

  final bool startOnMedications;

  @override
  State<HealthRecordsScreen> createState() => _HealthRecordsScreenState();
}

class _HealthRecordsScreenState extends State<HealthRecordsScreen> {
  late _RecordsView _view = widget.startOnMedications
      ? _RecordsView.medications
      : _RecordsView.timeline;

  @override
  Widget build(BuildContext context) {
    final gutter = WindowSize.of(context).gutter;

    return Scaffold(
      appBar: AppBar(title: const Text('Records')),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(gutter, Space.sm, gutter, Space.sm),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: Space.maxContentWidth,
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<_RecordsView>(
                    segments: const [
                      ButtonSegment(
                        value: _RecordsView.timeline,
                        icon: Icon(Icons.timeline_outlined),
                        label: Text('Timeline'),
                      ),
                      ButtonSegment(
                        value: _RecordsView.medications,
                        icon: Icon(Icons.medication_outlined),
                        label: Text('Medications'),
                      ),
                      ButtonSegment(
                        value: _RecordsView.bills,
                        icon: Icon(Icons.receipt_long_outlined),
                        label: Text('Bills'),
                      ),
                    ],
                    selected: {_view},
                    showSelectedIcon: false,
                    onSelectionChanged: (s) =>
                        setState(() => _view = s.first),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: switch (_view) {
              _RecordsView.timeline => const TimelineScreen(embedded: true),
              _RecordsView.medications => const MedicationsScreen(
                embedded: true,
              ),
              _RecordsView.bills => const BillingScreen(embedded: true),
            },
          ),
        ],
      ),
    );
  }
}

/// Health Records — the patient's clinical history, in two views:
/// their visit timeline and their medications, chosen with a top toggle.
library;

import 'package:flutter/material.dart';

import '../../../app/theme/theme.dart';
import '../../records/presentation/medications_screen.dart';
import 'timeline_screen.dart';

enum _RecordsView { timeline, medications }

class HealthRecordsScreen extends StatefulWidget {
  const HealthRecordsScreen({super.key});

  @override
  State<HealthRecordsScreen> createState() => _HealthRecordsScreenState();
}

class _HealthRecordsScreenState extends State<HealthRecordsScreen> {
  _RecordsView _view = _RecordsView.timeline;

  @override
  Widget build(BuildContext context) {
    final gutter = WindowSize.of(context).gutter;

    return Scaffold(
      appBar: AppBar(title: const Text('Health Records')),
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
                        label: Text('Visit timeline'),
                      ),
                      ButtonSegment(
                        value: _RecordsView.medications,
                        icon: Icon(Icons.medication_outlined),
                        label: Text('Medications'),
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
            },
          ),
        ],
      ),
    );
  }
}

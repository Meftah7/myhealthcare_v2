import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/theme/theme.dart';
import '../../../core/ui/patient/patient_components.dart';
import '../../../l10n/app_localizations.dart';
import 'health_tools_directory.dart';
import 'tool_widgets.dart';

/// Verified Bahrain National Portal ambulance/emergency number, 11 Oct 2026.
/// This is a device phone action, never an in-app clinical dispatch.
final emergencyPhoneUri = Uri(scheme: 'tel', path: '999');
final emergencyDialerProvider = Provider<Future<bool> Function(Uri)>(
  (ref) =>
      (uri) => launchUrl(uri, mode: LaunchMode.externalApplication),
);

class EmergencyServicesScreen extends ConsumerStatefulWidget {
  const EmergencyServicesScreen({super.key});
  @override
  ConsumerState<EmergencyServicesScreen> createState() =>
      _EmergencyServicesScreenState();
}

class _EmergencyServicesScreenState
    extends ConsumerState<EmergencyServicesScreen> {
  bool _opening = false;
  bool _failed = false;

  Future<void> _call() async {
    if (_opening) return;
    setState(() {
      _opening = true;
      _failed = false;
    });
    var opened = false;
    try {
      opened = await ref.read(emergencyDialerProvider)(emergencyPhoneUri);
    } catch (_) {
      /* A device without a dialer keeps the number visible. */
    }
    if (mounted) {
      setState(() {
        _opening = false;
        _failed = !opened;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    Widget planned(String title, String description, IconData icon) =>
        ToolEntryRow(
          title: title,
          description: description,
          icon: icon,
          onTap: () => explainFutureTool(context, title, description),
        );
    return PatientPageScaffold(
      appBar: toolsAppBar(context, t.htEmergencyTitle),
      children: [
        Text(
          t.htEmergencyTitle,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: Space.md),
        SurfaceCard(
          child: Text(
            t.htEmergencyRegion,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        const SizedBox(height: Space.lg),
        ToolEntryRow(
          key: const ValueKey('emergency-call'),
          title: t.htCallAmbulance,
          description: t.htCallDescription,
          icon: Icons.phone_in_talk_outlined,
          onTap: _call,
        ),
        if (_opening) const LinearProgressIndicator(),
        if (_failed) ...[
          Semantics(
            liveRegion: true,
            child: Text(
              t.htPhoneUnavailable,
              key: const ValueKey('emergency-phone-failed'),
            ),
          ),
          const SizedBox(height: Space.md),
        ],
        Text(t.htScope),
        const SizedBox(height: Space.md),
        planned(
          t.htNearestEr,
          t.htNearestErUnavailable,
          Icons.local_hospital_outlined,
        ),
        planned(
          t.htRapidResponse,
          t.htRapidUnavailable,
          Icons.emergency_outlined,
        ),
        planned(
          t.htEmergencyCheckIn,
          t.htCheckInUnavailable,
          Icons.assignment_outlined,
        ),
      ],
    );
  }
}

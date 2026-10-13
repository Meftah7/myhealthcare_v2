/// Shared-server appointments, messages and desk billing views. Every action
/// is a server call; nothing is written locally or shown as done before the
/// server confirms it. Errors keep the user's input.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../../core/failures.dart';
import '../../../core/presentation/readable_label.dart';
import '../../../core/utils/format.dart';
import '../../../data/remote/shared_client.dart';

typedef Tr = String Function(String en, String ar);

String _error(Object e) => e is Failure ? e.message : '$e';

DateTime _local(Object? iso) => DateTime.parse('$iso').toLocal();

/// Appointments: patients see and cancel their own; the front desk books
/// for the selected patient and checks arrivals in; clinicians see theirs.
class SharedAppointmentsView extends StatefulWidget {
  const SharedAppointmentsView({
    required this.repository,
    required this.user,
    required this.people,
    required this.tr,
    this.patient,
    super.key,
  });

  final SharedWorkspaceRepository repository;
  final Map<String, dynamic> user;
  final List<Map<String, dynamic>> people;
  final String? patient;
  final Tr tr;

  @override
  State<SharedAppointmentsView> createState() => _AppointmentsState();
}

class _AppointmentsState extends State<SharedAppointmentsView> {
  Future<List<Map<String, dynamic>>>? _load;
  bool _busy = false;
  String? _message;

  bool get _desk =>
      widget.user['role'] == 'admin' || widget.user['job'] == 'receptionist';

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void didUpdateWidget(SharedAppointmentsView old) {
    super.didUpdateWidget(old);
    if (old.patient != widget.patient) _reload();
  }

  void _reload() => setState(() {
    _load = widget.repository.appointments(
      patientId: _desk ? widget.patient : null,
    );
  });

  Future<void> _act(Future<void> Function() body, String done) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await body();
      _message = done;
      _reload();
    } catch (e) {
      _message = _error(e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _book() async {
    final patient = widget.user['role'] == 'patient'
        ? widget.user['id'] as String
        : widget.patient;
    if (patient == null) return;
    final clinicians = widget.people
        .where(
          (p) =>
              p['role'] == 'staff' && ['doctor', 'dentist'].contains(p['job']),
        )
        .toList();
    final picked = await showDialog<(String, DateTime)>(
      context: context,
      builder: (_) => _BookDialog(clinicians: clinicians, tr: widget.tr),
    );
    if (picked == null) return;
    // One key per confirmed request: a retry after a lost reply books once.
    final key = const Uuid().v4();
    await _act(
      () => widget.repository.book(
        patientId: patient,
        staffId: picked.$1,
        start: picked.$2,
        end: picked.$2.add(const Duration(minutes: 20)),
        idempotencyKey: key,
      ),
      widget.tr(
        'Booked. The server confirmed the time.',
        'تم الحجز وأكد الخادم الموعد.',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tr = widget.tr;
    final role = widget.user['role'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (role == 'patient' || (_desk && widget.patient != null))
          FilledButton.icon(
            onPressed: _busy ? null : _book,
            icon: const Icon(Icons.event_available_outlined),
            label: Text(tr('Book a visit', 'احجز زيارة')),
          ),
        if (_message != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Semantics(liveRegion: true, child: Text(_message!)),
          ),
        FutureBuilder<List<Map<String, dynamic>>>(
          future: _load,
          builder: (context, snap) {
            if (snap.hasError) {
              return ListTile(
                title: Text(_error(snap.error!)),
                trailing: TextButton(
                  onPressed: _reload,
                  child: Text(tr('Retry', 'إعادة المحاولة')),
                ),
              );
            }
            if (!snap.hasData) return const LinearProgressIndicator();
            final list = snap.data!;
            if (list.isEmpty) {
              return Text(tr('No appointments.', 'لا توجد مواعيد.'));
            }
            return Column(
              children: [
                for (final a in list)
                  Card(
                    child: ListTile(
                      title: ReadableLabel(
                        '${fmtDate(_local(a['start']))} ${fmtTime(_local(a['start']))}',
                      ),
                      subtitle: ReadableLabel(
                        '${a['status']} · v${a['version']}',
                      ),
                      trailing: Wrap(
                        spacing: 4,
                        children: [
                          if (_desk && a['status'] == 'booked')
                            TextButton(
                              onPressed: _busy
                                  ? null
                                  : () => _act(
                                      () => widget.repository.appointmentAction(
                                        a['id'] as String,
                                        'check-in',
                                        expectedVersion: a['version'] as int,
                                      ),
                                      tr(
                                        'Arrival recorded.',
                                        'تم تسجيل الوصول.',
                                      ),
                                    ),
                              child: Text(tr('Mark arrived', 'تسجيل الوصول')),
                            ),
                          if (a['status'] == 'booked')
                            TextButton(
                              onPressed: _busy
                                  ? null
                                  : () => _act(
                                      () => widget.repository.appointmentAction(
                                        a['id'] as String,
                                        'cancel',
                                        expectedVersion: a['version'] as int,
                                        reason: 'Cancelled in shared workspace',
                                      ),
                                      tr('Cancelled.', 'تم الإلغاء.'),
                                    ),
                              child: Text(tr('Cancel', 'إلغاء')),
                            ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _BookDialog extends StatefulWidget {
  const _BookDialog({required this.clinicians, required this.tr});

  final List<Map<String, dynamic>> clinicians;
  final Tr tr;

  @override
  State<_BookDialog> createState() => _BookDialogState();
}

class _BookDialogState extends State<_BookDialog> {
  String? _staff;
  DateTime? _day;
  TimeOfDay? _time;

  @override
  Widget build(BuildContext context) {
    final tr = widget.tr;
    final ready = _staff != null && _day != null && _time != null;
    return AlertDialog(
      title: Text(tr('Book a visit', 'احجز زيارة')),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.clinicians.isEmpty)
              Text(
                tr(
                  'No bookable clinicians are visible to you.',
                  'لا يوجد أطباء متاحون للحجز.',
                ),
              ),
            DropdownButtonFormField<String>(
              initialValue: _staff,
              isExpanded: true,
              decoration: InputDecoration(labelText: tr('Clinician', 'الطبيب')),
              items: [
                for (final c in widget.clinicians)
                  DropdownMenuItem(
                    value: c['id'] as String,
                    child: Text(clinicianName(c['fullName'] as String)),
                  ),
              ],
              onChanged: (v) => setState(() => _staff = v),
            ),
            OutlinedButton(
              onPressed: () async {
                final now = DateTime.now();
                final d = await showDatePicker(
                  context: context,
                  initialDate: now.add(const Duration(days: 1)),
                  firstDate: now,
                  lastDate: now.add(const Duration(days: 120)),
                );
                if (d != null) setState(() => _day = d);
              },
              child: Text(
                _day == null ? tr('Choose day', 'اختر اليوم') : fmtDate(_day!),
              ),
            ),
            OutlinedButton(
              onPressed: () async {
                final t = await showTimePicker(
                  context: context,
                  initialTime: const TimeOfDay(hour: 9, minute: 0),
                );
                if (t != null) setState(() => _time = t);
              },
              child: Text(
                _time == null
                    ? tr('Choose time', 'اختر الوقت')
                    : _time!.format(context),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(tr('Close', 'إغلاق')),
        ),
        FilledButton(
          onPressed: ready
              ? () => Navigator.pop(context, (
                  _staff!,
                  DateTime(
                    _day!.year,
                    _day!.month,
                    _day!.day,
                    _time!.hour,
                    _time!.minute,
                  ),
                ))
              : null,
          child: Text(tr('Book', 'احجز')),
        ),
      ],
    );
  }
}

/// Secure messages between a patient and a clinician with a care
/// relationship. A message shows as sent only after the server stores it.
class SharedMessagesView extends StatefulWidget {
  const SharedMessagesView({
    required this.repository,
    required this.user,
    required this.tr,
    super.key,
  });

  final SharedWorkspaceRepository repository;
  final Map<String, dynamic> user;
  final Tr tr;

  @override
  State<SharedMessagesView> createState() => _MessagesState();
}

class _MessagesState extends State<SharedMessagesView> {
  Future<List<Map<String, dynamic>>>? _threads;
  String? _counterpart;
  Future<List<Map<String, dynamic>>>? _thread;
  final _draft = TextEditingController();
  String? _pendingKey;
  bool _sending = false;
  String? _error_;

  bool get _isPatient => widget.user['role'] == 'patient';

  @override
  void initState() {
    super.initState();
    _threads = widget.repository.threads();
  }

  @override
  void dispose() {
    _draft.dispose();
    super.dispose();
  }

  (String, String) _pair(String counterpart) => _isPatient
      ? (widget.user['id'] as String, counterpart)
      : (counterpart, widget.user['id'] as String);

  void _open(String counterpart) {
    final (p, s) = _pair(counterpart);
    setState(() {
      _counterpart = counterpart;
      _thread = widget.repository.messages(p, s);
    });
    unawaited(widget.repository.markRead(p, s).catchError((_) {}));
  }

  Future<void> _send() async {
    final text = _draft.text.trim();
    final c = _counterpart;
    if (text.isEmpty || c == null || _sending) return;
    final (p, s) = _pair(c);
    // The same key is reused until the server confirms, so a retry after a
    // failure never sends a duplicate.
    _pendingKey ??= const Uuid().v4();
    setState(() {
      _sending = true;
      _error_ = null;
    });
    try {
      await widget.repository.sendMessage(
        patientId: p,
        staffId: s,
        body: text,
        idempotencyKey: _pendingKey!,
      );
      _draft.clear();
      _pendingKey = null;
      _open(c);
    } catch (e) {
      // Draft kept; nothing is shown as sent.
      _error_ = _error(e);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tr = widget.tr;
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _threads,
      builder: (context, snap) {
        if (snap.hasError) return Text(_error(snap.error!));
        if (!snap.hasData) return const LinearProgressIndicator();
        final threads = snap.data!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (threads.isEmpty)
              Text(tr('No conversations yet.', 'لا توجد محادثات بعد.')),
            for (final t in threads)
              ListTile(
                selected: t['counterpartId'] == _counterpart,
                title: Text('${t['counterpartName']}'),
                trailing: (t['unread'] as num) > 0
                    ? Badge(label: Text('${t['unread']}'))
                    : null,
                onTap: () => _open(t['counterpartId'] as String),
              ),
            if (_thread != null) ...[
              const Divider(),
              FutureBuilder<List<Map<String, dynamic>>>(
                future: _thread,
                builder: (context, s) {
                  if (s.hasError) return Text(_error(s.error!));
                  if (!s.hasData) return const LinearProgressIndicator();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final m in s.data!)
                        Align(
                          alignment: m['senderId'] == widget.user['id']
                              ? AlignmentDirectional.centerEnd
                              : AlignmentDirectional.centerStart,
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ReadableLabel('${m['body']}'),
                                  Text(
                                    '${fmtTime(_local(m['at']))} · ${tr('sent', 'أُرسلت')}',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.labelSmall,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
              TextField(
                controller: _draft,
                minLines: 1,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: tr('Message', 'رسالة'),
                  errorText: _error_,
                ),
              ),
              FilledButton(
                onPressed: _sending ? null : _send,
                child: Text(
                  _sending
                      ? tr('Sending…', 'جارٍ الإرسال…')
                      : tr('Send', 'إرسال'),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

/// Invoices and desk payment records (integer fils, three-decimal BHD).
class SharedBillingView extends StatefulWidget {
  const SharedBillingView({
    required this.repository,
    required this.user,
    required this.tr,
    this.patient,
    super.key,
  });

  final SharedWorkspaceRepository repository;
  final Map<String, dynamic> user;
  final String? patient;
  final Tr tr;

  @override
  State<SharedBillingView> createState() => _BillingState();
}

class _BillingState extends State<SharedBillingView> {
  Future<List<Map<String, dynamic>>>? _load;
  bool _busy = false;
  String? _message;

  bool get _desk =>
      widget.user['role'] == 'admin' || widget.user['job'] == 'receptionist';

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void didUpdateWidget(SharedBillingView old) {
    super.didUpdateWidget(old);
    if (old.patient != widget.patient) _reload();
  }

  void _reload() => setState(() {
    _load = widget.repository.invoices(
      widget.user['role'] == 'patient' ? null : widget.patient,
    );
  });

  Future<void> _record(Map<String, dynamic> invoice) async {
    final due = (invoice['amountFils'] as int) - (invoice['paidFils'] as int);
    final controller = TextEditingController(
      text: (due / 1000).toStringAsFixed(3),
    );
    final amount = await showDialog<int>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(
          widget.tr('Record desk payment', 'تسجيل دفعة في الاستقبال'),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(labelText: 'BHD'),
            ),
            const SizedBox(height: 8),
            Text(
              widget.tr(
                'Records cash/card taken at the desk. No payment gateway is connected; no money moves here.',
                'يسجل المبلغ المدفوع في الاستقبال. لا توجد بوابة دفع متصلة؛ لا تُنقل أموال هنا.',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: Text(widget.tr('Close', 'إغلاق')),
          ),
          FilledButton(
            onPressed: () {
              final bhd = double.tryParse(controller.text.trim());
              Navigator.pop(c, bhd == null ? null : (bhd * 1000).round());
            },
            child: Text(widget.tr('Record', 'تسجيل')),
          ),
        ],
      ),
    );
    controller.dispose();
    if (amount == null || amount <= 0 || _busy) return;
    final key = const Uuid().v4();
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await widget.repository.recordDeskPayment(
        invoice['id'] as String,
        amountFils: amount,
        expectedVersion: invoice['version'] as int,
        idempotencyKey: key,
      );
      _message = widget.tr('Desk payment recorded.', 'تم تسجيل الدفعة.');
      _reload();
    } catch (e) {
      _message = _error(e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tr = widget.tr;
    if (!_desk && widget.user['role'] != 'patient') {
      return Text(
        tr(
          'Billing is handled by the front desk.',
          'تتولى الاستقبال الفواتير.',
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_message != null)
          Semantics(liveRegion: true, child: Text(_message!)),
        FutureBuilder<List<Map<String, dynamic>>>(
          future: _load,
          builder: (context, snap) {
            if (snap.hasError) {
              return ListTile(
                title: Text(_error(snap.error!)),
                trailing: TextButton(
                  onPressed: _reload,
                  child: Text(tr('Retry', 'إعادة المحاولة')),
                ),
              );
            }
            if (!snap.hasData) return const LinearProgressIndicator();
            if (snap.data!.isEmpty) {
              return Text(tr('No invoices.', 'لا توجد فواتير.'));
            }
            return Column(
              children: [
                for (final i in snap.data!)
                  Card(
                    child: ListTile(
                      title: ReadableLabel(
                        '${i['description']} · ${fmtBhd((i['amountFils'] as int) / 1000)}',
                      ),
                      subtitle: ReadableLabel(
                        '${i['status'] == 'paid' ? tr('Paid', 'مدفوعة') : tr('Outstanding', 'مستحقة')} · '
                        '${tr('paid', 'المدفوع')} ${fmtBhd((i['paidFils'] as int) / 1000)}',
                      ),
                      trailing: _desk && i['status'] == 'outstanding'
                          ? TextButton(
                              onPressed: _busy ? null : () => _record(i),
                              child: Text(tr('Record payment', 'تسجيل دفعة')),
                            )
                          : null,
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

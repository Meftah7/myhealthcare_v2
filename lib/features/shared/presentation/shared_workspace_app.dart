import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:uuid/uuid.dart';

import '../../../app/theme/theme.dart';
import '../../../core/failures.dart';
import '../../../core/presentation/readable_label.dart';
import '../../../data/remote/shared_client.dart';
import '../../../l10n/app_localizations.dart';
import '../../patient/presentation/document_download_button.dart';

/// Isolated shared pilot: deliberately never instantiates a device database.
/// Existing local Records/Profile UI remains untouched by this entry point.
class SharedWorkspaceApp extends StatefulWidget {
  const SharedWorkspaceApp({required this.origin, this.client, super.key});
  final String origin;

  /// The workspace owns and closes this transport when provided.
  final SharedClient? client;
  @override
  State<SharedWorkspaceApp> createState() => _SharedWorkspaceState();
}

class _SharedWorkspaceState extends State<SharedWorkspaceApp> {
  late final SharedClient client;
  late final SharedWorkspaceRepository repository;
  final navigator = GlobalKey<NavigatorState>();
  StreamSubscription<Map<String, dynamic>?>? session;
  Timer? refresh;
  DateTime? lastActivity;
  bool ar = false, busy = false;
  String? error, patient;
  String view = 'home';
  List<Map<String, dynamic>> people = [],
      tasks = [],
      documents = [],
      originals = [],
      visits = [],
      templates = [],
      requests = [],
      notices = [];
  Map<String, dynamic>? health;
  final email = TextEditingController(), password = TextEditingController();
  String tr(String en, String arabic) => ar ? arabic : en;
  void touch() {
    final now = DateTime.now();
    if (client.user == null ||
        lastActivity != null &&
            now.difference(lastActivity!) < const Duration(seconds: 30))
      return;
    lastActivity = now;
    unawaited(
      client
          .request('/api/activity', method: 'POST', body: {})
          .then<void>(
            (_) {},
            onError: (Object e) {
              if (mounted)
                setState(
                  () => error = e is Failure
                      ? e.message
                      : tr('Server unavailable.', 'الخادم غير متاح.'),
                );
            },
          ),
    );
  }

  @override
  void initState() {
    super.initState();
    client = widget.client ?? SharedClient(widget.origin);
    repository = SharedWorkspaceRepository(client);
    session = client.sessions.listen((user) {
      if (!mounted) return;
      if (user == null)
        navigator.currentState?.popUntil((route) => route.isFirst);
      setState(() {
        people = [];
        tasks = [];
        documents = [];
        originals = [];
        visits = [];
        templates = [];
        requests = [];
        notices = [];
        lastActivity = null;
        health = null;
        patient = null;
        view = 'home';
      });
    });
    refresh = Timer.periodic(const Duration(seconds: 10), (_) {
      if (client.user != null && !busy) unawaited(perform(load));
    });
  }

  @override
  void dispose() {
    refresh?.cancel();
    unawaited(session?.cancel());
    unawaited(client.close());
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> perform(Future<void> Function() action) async {
    if (busy) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await action();
    } on Failure catch (failure) {
      if (mounted) setState(() => error = failure.message);
    } on Object {
      if (mounted) {
        setState(
          () => error = tr(
            'Could not complete this operation.',
            'تعذر إكمال العملية.',
          ),
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> load() async {
    final generation = client.generation;
    final data = await repository.people();
    final messages = await repository.notifications();
    final role = client.user?['role'];
    if (role == null || !mounted) return;
    final selected =
        patient ??
        (role == 'patient'
            ? client.user!['id'] as String
            : data.where((u) => u['role'] == 'patient').firstOrNull?['id']
                  as String?);
    final work = role == 'staff'
        ? await repository.tasks()
        : <Map<String, dynamic>>[];
    final docs = selected == null
        ? <Map<String, dynamic>>[]
        : await repository.documents(selected);
    final files = selected == null || role == 'admin'
        ? <Map<String, dynamic>>[]
        : await repository.originals(selected);
    final visitData = selected == null || role != 'staff'
        ? <Map<String, dynamic>>[]
        : await repository.visits(selected);
    final policies = role == 'patient'
        ? <Map<String, dynamic>>[]
        : await repository.templates();
    final drafts = selected != null && role == 'staff'
        ? await repository.requests(selected)
        : <Map<String, dynamic>>[];
    final status = role == 'admin' ? await repository.health() : null;
    if (!mounted || client.generation != generation) return;
    setState(() {
      people = data;
      notices = messages;
      patient = selected;
      tasks = work;
      documents = docs;
      originals = files;
      visits = visitData;
      templates = policies;
      requests = drafts;
      health = status;
    });
  }

  Future<Map<String, String>?> form(
    BuildContext context,
    String title,
    Map<String, String> initial, {
    Set<String> secret = const {},
  }) async {
    final controls = {
      for (final entry in initial.entries)
        entry.key: TextEditingController(text: entry.value),
    };
    try {
      return await showDialog<Map<String, String>>(
        context: context,
        builder: (c) => AlertDialog(
          title: Text(title),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final entry in controls.entries)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: TextField(
                        controller: entry.value,
                        onChanged: (_) => touch(),
                        obscureText: secret.contains(entry.key),
                        maxLines: secret.contains(entry.key) ? 1 : null,
                        decoration: InputDecoration(labelText: entry.key),
                      ),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c),
              child: Text(tr('Cancel', 'إلغاء')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(c, {
                for (final entry in controls.entries)
                  entry.key: entry.value.text.trim(),
              }),
              child: Text(tr('Save', 'حفظ')),
            ),
          ],
        ),
      );
    } finally {
      for (final control in controls.values) {
        control.dispose();
      }
    }
  }

  Future<void> newTask(BuildContext context) async {
    if (patient == null) return;
    final input = await form(context, tr('Create follow-up', 'إنشاء متابعة'), {
      'Title': '',
      'Source reference': '',
    });
    if (input == null) return;
    final command = {
      'patientId': patient,
      'sourceId': input['Source reference'],
      'title': input['Title'],
      'kind': 'followUpDue',
      'idempotencyKey': const Uuid().v4(),
    };
    await perform(() async {
      await repository.createTask(command);
      await load();
    });
  }

  Future<void> outcome(BuildContext context, Map<String, dynamic> task) async {
    final input = await form(context, tr('Record outcome', 'تسجيل النتيجة'), {
      'Status': 'done',
      'Outcome': '',
      'Review date (ISO, for waiting/blocked)': '',
    });
    if (input == null) return;
    await perform(() async {
      final review = input['Review date (ISO, for waiting/blocked)'];
      await repository.setTaskStatus(
        task,
        input['Status']!,
        input['Outcome']!,
        reviewAt: review == null || review.isEmpty
            ? null
            : DateTime.parse(review),
      );
      await load();
    });
  }

  Future<void> prepare(BuildContext context) async {
    if (patient == null || visits.isEmpty || templates.isEmpty) {
      setState(
        () => error = tr(
          'A completed visit and clinic template are required.',
          'يلزم وجود زيارة مكتملة وقالب عيادة.',
        ),
      );
      return;
    }
    final input =
        await form(context, tr('Prepare sick leave', 'إعداد إجازة مرضية'), {
          'Visit reference': visits.first['id'] as String,
          'Template reference':
              templates
                      .where((t) => t['type'] == 'sickLeaveCertificate')
                      .firstOrNull?['id']
                  as String? ??
              '',
          'Start date (YYYY-MM-DD)': '',
          'End date (YYYY-MM-DD)': '',
        });
    if (input == null) return;
    await perform(() async {
      final request = await repository.prepareDocument({
        'patientId': patient,
        'visitId': input['Visit reference'],
        'templateId': input['Template reference'],
        'content': {
          'startDate': input['Start date (YYYY-MM-DD)'],
          'endDate': input['End date (YYYY-MM-DD)'],
        },
        'idempotencyKey': const Uuid().v4(),
      });
      await load();
      if (mounted) {
        setState(
          () => error = tr(
            'Draft saved: ${request['id']}. Submit and approve it explicitly below.',
            'تم حفظ المسودة: ${request['id']}. أرسلها واعتمدها بشكل صريح.',
          ),
        );
      }
    });
  }

  Future<void> requestAction(Map<String, dynamic> request) async {
    final action = switch (request['status']) {
      'draft' => 'submit',
      'submitted' => 'approve',
      'approved' => 'issue',
      _ => null,
    };
    if (action == null) return;
    await perform(() async {
      await repository.documentAction(
        request['id'] as String,
        action,
        request['version'] as int,
        key: action == 'issue' ? const Uuid().v4() : null,
      );
      await load();
    });
  }

  Future<void> policy(BuildContext context) async {
    final input = await form(
      context,
      'Record clinic policy decision',
      {
        'Language (en/ar)': 'en',
        'Disclosure (clinic/employer/school)': 'employer',
        'Wording':
            '{patientName} attended on {visitDate}. Leave from {startDate} to {endDate}.',
        'Approved by clinic (true/false)': 'false',
        'Decision reason': '',
        'Confirm password': '',
      },
      secret: {'Confirm password'},
    );
    if (input == null) return;
    await perform(() async {
      final approved = input['Approved by clinic (true/false)'];
      if (!{'true', 'false'}.contains(approved))
        throw const ValidationFailure(
          'Choose true or false for the approval decision.',
        );
      await repository.reauthenticate(input['Confirm password']!);
      await client.request(
        '/api/templates',
        method: 'POST',
        body: {
          'type': 'sickLeaveCertificate',
          'language': input['Language (en/ar)'],
          'disclosure': input['Disclosure (clinic/employer/school)'],
          'wording': input['Wording'],
          'approved': approved == 'true',
          'reason': input['Decision reason'],
        },
      );
      await load();
    });
  }

  Future<void> upload() async {
    if (patient == null) return;
    await perform(() async {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (bytes.length > 20 * 1024 * 1024) {
        throw const ValidationFailure('Choose a PDF no larger than 20 MB.');
      }
      await client.request(
        '/api/originals',
        method: 'POST',
        body: {
          'patientId': patient,
          'base64': base64Encode(bytes),
          'idempotencyKey': const Uuid().v4(),
        },
      );
      await load();
    });
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    navigatorKey: navigator,
    title: 'MyHealth Shared',
    theme: AppTheme.light,
    locale: Locale(ar ? 'ar' : 'en'),
    supportedLocales: const [Locale('en'), Locale('ar')],
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: Listener(
      onPointerDown: (_) => touch(),
      child: Builder(
        builder: (c) => Scaffold(
          appBar: AppBar(
            title: Text(tr('Shared workspace', 'مساحة العمل المشتركة')),
            actions: [
              IconButton(
                tooltip: tr('Language', 'اللغة'),
                icon: const Icon(Icons.language),
                onPressed: () => setState(() => ar = !ar),
              ),
              if (client.user != null)
                IconButton(
                  tooltip: tr('Sign out', 'تسجيل الخروج'),
                  icon: const Icon(Icons.logout),
                  onPressed: busy ? null : () => perform(client.logout),
                ),
            ],
          ),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  ReadableLabel(
                    tr(
                      'Shared pilot: tasks, issued documents and original PDFs use the server. Other clinic modules remain in the local app.',
                      'نسخة مشتركة تجريبية: المهام والمستندات الصادرة وملفات PDF الأصلية على الخادم. وحدات العيادة الأخرى تبقى في التطبيق المحلي.',
                    ),
                  ),
                  if (busy) const LinearProgressIndicator(),
                  if (error != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: ReadableLabel(error!),
                    ),
                  if (client.user == null) ...[
                    const SizedBox(height: 20),
                    TextField(
                      controller: email,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: tr('Email', 'البريد الإلكتروني'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: password,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: tr('Password', 'كلمة المرور'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: busy
                          ? null
                          : () => perform(() async {
                              await client.login(
                                email.text.trim(),
                                password.text,
                              );
                              password.clear();
                              await load();
                            }),
                      child: Text(tr('Sign in to server', 'الدخول إلى الخادم')),
                    ),
                  ] else ...[
                    Text(
                      client.user!['fullName'] as String,
                      style: Theme.of(c).textTheme.headlineSmall,
                    ),
                    Wrap(
                      spacing: 8,
                      children: [
                        for (final (key, en, arabic) in [
                          ('home', 'Home', 'الرئيسية'),
                          ('documents', 'Documents', 'المستندات'),
                          ('records', 'Records', 'السجلات'),
                          ('profile', 'Profile', 'الملف الشخصي'),
                        ])
                          ChoiceChip(
                            label: Text(tr(en, arabic)),
                            selected: view == key,
                            onSelected: (_) => setState(() => view = key),
                          ),
                      ],
                    ),
                    if (client.user!['role'] != 'patient' &&
                        view != 'profile') ...[
                      for (final person in people.where(
                        (p) => p['role'] == 'patient',
                      ))
                        RadioListTile<String>(
                          title: Text(person['fullName'] as String),
                          value: person['id'] as String,
                          groupValue: patient,
                          onChanged: busy
                              ? null
                              : (value) => perform(() async {
                                  patient = value;
                                  await load();
                                }),
                        ),
                    ],
                    if (view == 'profile') ...[
                      ReadableLabel(
                        '${client.user!['email']}\n${client.user!['role']}',
                      ),
                      Text(
                        tr(
                          'Sessions end after inactivity. Signing out clears device memory.',
                          'تنتهي الجلسة بعد عدم النشاط. تسجيل الخروج يمسح بيانات الجلسة من الذاكرة.',
                        ),
                      ),
                    ] else if (view == 'records') ...[
                      OutlinedButton.icon(
                        onPressed: busy || client.user!['role'] == 'admin'
                            ? null
                            : upload,
                        icon: const Icon(Icons.upload_file),
                        label: Text(
                          tr('Upload original PDF', 'رفع ملف PDF أصلي'),
                        ),
                      ),
                      for (final file in originals)
                        DocumentDownloadButton(
                          label: '${file['id']}',
                          filename: 'original-${file['id']}.pdf',
                          build: () async =>
                              await client.request(
                                    '/api/originals/${file['id']}',
                                    binary: true,
                                  )
                                  as Uint8List,
                        ),
                    ] else if (view == 'documents') ...[
                      if (client.user!['role'] == 'staff')
                        Wrap(
                          spacing: 8,
                          children: [
                            OutlinedButton(
                              onPressed: busy ? null : () => prepare(c),
                              child: Text(
                                tr('Prepare sick leave', 'إعداد إجازة مرضية'),
                              ),
                            ),
                          ],
                        ),
                      if (client.user!['role'] == 'admin')
                        OutlinedButton(
                          onPressed: busy ? null : () => policy(c),
                          child: const Text('Record clinic policy decision'),
                        ),
                      for (final request in requests)
                        ListTile(
                          title: Text(request['status'] as String),
                          subtitle: ReadableLabel(request['id'] as String),
                          trailing: request['status'] == 'issued'
                              ? null
                              : TextButton(
                                  onPressed: busy
                                      ? null
                                      : () => requestAction(request),
                                  child: Text(switch (request['status']) {
                                    'draft' => 'Submit',
                                    'submitted' => 'Approve',
                                    'approved' => 'Issue',
                                    _ => 'Review',
                                  }),
                                ),
                        ),
                      for (final doc in documents)
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ReadableLabel(
                                  '${doc['type']}\n${doc['id']}\n${doc['validity']} · ${doc['render']}',
                                ),
                                if (client.user!['role'] == 'staff' &&
                                    doc['render'] != 'ready')
                                  TextButton(
                                    onPressed: busy
                                        ? null
                                        : () => perform(() async {
                                            await repository.render(
                                              doc['id'] as String,
                                            );
                                            await load();
                                          }),
                                    child: Text(
                                      tr(
                                        'Render issued PDF',
                                        'إنشاء PDF الصادر',
                                      ),
                                    ),
                                  ),
                                if (client.user!['role'] != 'admin' &&
                                    doc['render'] == 'ready')
                                  DocumentDownloadButton(
                                    label: tr(
                                      'Download exact issued PDF',
                                      'تحميل PDF الصادر الأصلي',
                                    ),
                                    filename: 'issued-${doc['id']}.pdf',
                                    build: () => repository.download(
                                      doc['id'] as String,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                    ] else ...[
                      OutlinedButton.icon(
                        onPressed: busy ? null : () => perform(load),
                        icon: const Icon(Icons.refresh),
                        label: Text(
                          tr('Refresh from server', 'تحديث من الخادم'),
                        ),
                      ),
                      if (client.user!['role'] == 'staff') ...[
                        OutlinedButton(
                          onPressed: busy ? null : () => newTask(c),
                          child: Text(tr('New follow-up', 'متابعة جديدة')),
                        ),
                        for (final task in tasks)
                          Card(
                            child: ListTile(
                              title: ReadableLabel(task['title'] as String),
                              subtitle: ReadableLabel(
                                '${task['status']} · v${task['version']}',
                              ),
                              onTap: busy ? null : () => outcome(c, task),
                            ),
                          ),
                      ],
                      for (final notice in notices)
                        Card(
                          child: ListTile(
                            leading: const Icon(Icons.notifications_outlined),
                            title: ReadableLabel(notice['message'] as String),
                          ),
                        ),
                      if (health != null) ...[
                        ReadableLabel(
                          '${tr('Storage', 'التخزين')}: ${health!['storage']}\nSchema: ${health!['schema']}\nPending delivery: ${health!['pendingDelivery']}\nFailed delivery: ${health!['failedDelivery']}',
                        ),
                        for (final job in health!['jobs'] as List)
                          ReadableLabel(
                            '${job['key']}: ${job['status']} · ${job['at']}',
                          ),
                        Text(
                          tr(
                            'Payments and external delivery are not configured. Restore is restricted to an offline operator.',
                            'المدفوعات والتوصيل الخارجي غير مهيأة. الاستعادة متاحة فقط لمشغل خارج واجهة الويب.',
                          ),
                        ),
                      ],
                    ],
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/presentation/app_scaffold.dart';
import '../../../core/presentation/feedback.dart';
import '../../../core/result.dart';
import '../../../data/repositories/admin_workspace.dart';
import 'admin_workspace_shared.dart';

final adminConfigurationProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, String>(
      (ref, key) => ref.watch(adminWorkspaceProvider).configuration(key),
    );

class AdminConfigurationScreen extends ConsumerStatefulWidget {
  const AdminConfigurationScreen(this.config, {super.key});
  final String config;
  @override
  ConsumerState<AdminConfigurationScreen> createState() =>
      _ConfigurationState();
}

class _ConfigurationState extends ConsumerState<AdminConfigurationScreen> {
  final form = GlobalKey<FormState>();
  final fields = <String, TextEditingController>{};
  bool loaded = false, busy = false;
  @override
  void dispose() {
    for (final f in fields.values) {
      f.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext c) {
    final config = ref.watch(adminConfigurationProvider(widget.config));
    final labels = switch (widget.config) {
      'clinic' => {
        'name': ('Clinic name', 'اسم العيادة'),
        'address': ('Address', 'العنوان'),
        'contact': ('Contact', 'الاتصال'),
      },
      'integrations' => {
        'apiOrigin': ('Shared API HTTPS origin', 'عنوان API المشترك'),
        'verificationOrigin': (
          'Verification HTTPS origin',
          'عنوان خدمة التحقق',
        ),
      },
      _ => {
        'recoveryOwner': ('Recovery owner', 'مسؤول الاستعادة'),
        'recoveryHours': ('Recovery target (hours)', 'هدف الاستعادة بالساعات'),
        'retentionDays': ('Retention target (days)', 'مدة الاحتفاظ بالأيام'),
      },
    };
    return AppScaffold(
      title: adminText(c, 'Clinic configuration', 'إعدادات العيادة'),
      centerBody: false,
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          config.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text('$e'),
            data: (data) {
              if (!loaded) {
                for (final key in labels.keys) {
                  fields[key] = TextEditingController(
                    text:
                        '${data[key] ?? (key == 'name' ? 'MyHealth Care' : '')}',
                  );
                }
                loaded = true;
              }
              return Form(
                key: form,
                child: Column(
                  children: [
                    for (final entry in labels.entries)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: TextFormField(
                          controller: fields[entry.key],
                          decoration: InputDecoration(
                            labelText: adminText(
                              c,
                              entry.value.$1,
                              entry.value.$2,
                            ),
                          ),
                          maxLength: entry.key == 'address' ? 500 : 200,
                          validator: (v) {
                            if (entry.key == 'name' &&
                                (v == null || v.trim().isEmpty)) {
                              return adminText(c, 'Required', 'مطلوب');
                            }
                            if ({
                                  'recoveryHours',
                                  'retentionDays',
                                }.contains(entry.key) &&
                                (int.tryParse(v ?? '') ?? 0) <= 0) {
                              return adminText(
                                c,
                                'Enter a positive number',
                                'أدخل رقما موجبا',
                              );
                            }
                            return null;
                          },
                        ),
                      ),
                    if (widget.config == 'integrations')
                      Text(
                        adminText(
                          c,
                          'These origins prepare shared deployment. Delivery and registry publication need configured services; secrets stay on the server. Payments remain simulated.',
                          'تجهز هذه العناوين النشر المشترك. يتطلب التسليم ونشر سجل التحقق خدمات معدة. تبقى الأسرار على الخادم والمدفوعات محاكاة.',
                        ),
                      ),
                    if (widget.config == 'backup')
                      Text(
                        adminText(
                          c,
                          'No scheduled backup worker is configured. These recovery targets do not indicate a completed backup or tested restore. Keep recovery authority separate when deploying Task 7.',
                          'لم يتم إعداد عامل نسخ احتياطي مجدول. لا تعني هذه الأهداف وجود نسخة مكتملة أو استعادة مختبرة. افصل صلاحية الاستعادة عند نشر المهمة ٧.',
                        ),
                      ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: busy
                          ? null
                          : () async {
                              if (!form.currentState!.validate()) return;
                              setState(() => busy = true);
                              final result = await Result.guardAsync(
                                () => ref
                                    .read(adminWorkspaceProvider)
                                    .saveConfiguration(widget.config, {
                                      for (final e in fields.entries)
                                        e.key: e.value.text.trim(),
                                    }),
                              );
                              if (!c.mounted) return;
                              setState(() => busy = false);
                              showMutationFeedback(c, result);
                              if (result.isOk) {
                                ref.invalidate(
                                  adminConfigurationProvider(widget.config),
                                );
                              }
                            },
                      child: Text(
                        adminText(c, 'Save configuration', 'حفظ الإعدادات'),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

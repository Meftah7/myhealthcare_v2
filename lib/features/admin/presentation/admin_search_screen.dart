import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/presentation/app_scaffold.dart';
import '../../../data/repositories/admin_workspace.dart';
import 'admin_workspace_shared.dart';

class AdminGlobalSearchScreen extends ConsumerStatefulWidget {
  const AdminGlobalSearchScreen({super.key});
  @override
  ConsumerState<AdminGlobalSearchScreen> createState() => _SearchState();
}

class _SearchState extends ConsumerState<AdminGlobalSearchScreen> {
  String query = '';
  Future<List<AdminSearchHit>>? results;
  @override
  Widget build(BuildContext c) => AppScaffold(
    title: adminText(c, 'Search the workspace', 'البحث في مساحة العمل'),
    centerBody: false,
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        TextField(
          autofocus: true,
          textInputAction: TextInputAction.search,
          onChanged: (v) => query = v,
          decoration: InputDecoration(
            suffixIcon: IconButton(
              tooltip: adminText(c, 'Search', 'بحث'),
              icon: const Icon(Icons.search),
              onPressed: () => setState(
                () => results = ref.read(adminWorkspaceProvider).search(query),
              ),
            ),
            labelText: adminText(
              c,
              'People, bookings or document references',
              'أشخاص أو حجوزات أو مراجع مستندات',
            ),
          ),
          onSubmitted: (v) => setState(() {
            query = v;
            results = ref.read(adminWorkspaceProvider).search(v);
          }),
        ),
        Text(
          adminText(
            c,
            'Enter at least two characters and press Enter. Clinical notes are excluded.',
            'أدخل حرفين على الأقل ثم ابحث. لا تشمل النتائج الملاحظات السريرية.',
          ),
        ),
        if (results != null)
          FutureBuilder<List<AdminSearchHit>>(
            future: results,
            builder: (c, s) {
              if (s.hasError) return Text('${s.error}');
              if (!s.hasData) return const LinearProgressIndicator();
              if (s.data!.isEmpty) {
                return Text(adminText(c, 'No matches.', 'لا توجد نتائج'));
              }
              return Column(
                children: [
                  for (final h in s.data!)
                    ListTile(
                      title: Text(h.label),
                      subtitle: Text(h.detail),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => c.push(h.route),
                    ),
                ],
              );
            },
          ),
      ],
    ),
  );
}

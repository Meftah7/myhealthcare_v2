/// MyHealth Terms and Privacy Policy content, loaded from
/// `assets/policies/policies.json` so the owner can replace the documents and
/// mark them approved without code changes. While `status` is not
/// "approved", the screen shows a prominent draft banner and the list of
/// unresolved facts — draft text is never presented as published policy.
library;

import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum PolicyKind { terms, privacy }

enum PolicyBlockType { heading, paragraph, bullet }

class PolicyBlock {
  const PolicyBlock(this.type, this.text);
  final PolicyBlockType type;
  final String text;
}

class PolicyDocument {
  const PolicyDocument({
    required this.title,
    required this.blocks,
    required this.approved,
    required this.version,
    required this.lastUpdated,
    required this.unresolved,
  });

  final String title;
  final List<PolicyBlock> blocks;

  /// True only when the owner set `"status": "approved"`.
  final bool approved;
  final String version;
  final String lastUpdated;

  /// Facts the owner still has to supply (shown on drafts).
  final List<String> unresolved;
}

/// Parses the small Markdown subset the policy files use: `#`/`##`
/// headings, `- ` bullets and blank-line separated paragraphs.
({String title, List<PolicyBlock> blocks}) parsePolicyMarkdown(String source) {
  var title = '';
  final blocks = <PolicyBlock>[];
  final paragraph = StringBuffer();
  void flush() {
    if (paragraph.isNotEmpty) {
      blocks.add(PolicyBlock(PolicyBlockType.paragraph, paragraph.toString()));
      paragraph.clear();
    }
  }

  for (final raw in const LineSplitter().convert(source)) {
    final line = raw.trim();
    if (line.isEmpty) {
      flush();
    } else if (line.startsWith('# ')) {
      flush();
      title = line.substring(2).trim();
    } else if (line.startsWith('## ')) {
      flush();
      blocks.add(
        PolicyBlock(PolicyBlockType.heading, line.substring(3).trim()),
      );
    } else if (line.startsWith('- ')) {
      flush();
      blocks.add(PolicyBlock(PolicyBlockType.bullet, line.substring(2).trim()));
    } else {
      if (paragraph.isNotEmpty) paragraph.write(' ');
      paragraph.write(line);
    }
  }
  flush();
  return (title: title, blocks: blocks);
}

/// Loads a policy for a language (falls back to English).
Future<PolicyDocument> loadPolicy(
  AssetBundle bundle,
  PolicyKind kind,
  String languageCode,
) async {
  final config =
      jsonDecode(await bundle.loadString('assets/policies/policies.json'))
          as Map<String, dynamic>;
  final docs = (config['documents'] as Map)[kind.name] as Map;
  final path = (docs[languageCode] ?? docs['en']) as String;
  final parsed = parsePolicyMarkdown(await bundle.loadString(path));
  final unresolvedByLang = config['unresolved'] as Map?;
  final unresolved =
      (unresolvedByLang?[languageCode] ?? unresolvedByLang?['en']) as List?;
  return PolicyDocument(
    title: parsed.title,
    blocks: parsed.blocks,
    approved: config['status'] == 'approved',
    version: '${config['version'] ?? ''}',
    lastUpdated: '${config['lastUpdated'] ?? ''}',
    unresolved: [for (final u in unresolved ?? const []) '$u'],
  );
}

final policyProvider = FutureProvider.autoDispose
    .family<PolicyDocument, (PolicyKind, String)>(
      (ref, key) => loadPolicy(rootBundle, key.$1, key.$2),
    );

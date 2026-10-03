/// Upload, take, or remove the account's profile photo, from the badge on
/// the avatar. Native platforms store a local file; the web has no file
/// system, so the image is kept as a base64 data URI instead — both are
/// local to the device either way, nothing is uploaded anywhere.
library;

import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../../../app/theme/theme.dart';
import '../../../core/di.dart';
import '../../../core/presentation/app_card.dart';
import '../../../core/presentation/feedback.dart';
import '../../../core/result.dart';
import '../../../l10n/app_localizations.dart';
import '../application/patient_data_providers.dart';

/// `defaultTargetPlatform` reflects the underlying OS even when running as
/// web (a mobile browser reports android/iOS). Only those actually trigger a
/// live camera capture — desktop web/native just falls back to the same file
/// dialog as "choose photo", which is confusing to show as a second option.
bool get _cameraAvailable =>
    defaultTargetPlatform == TargetPlatform.android ||
    defaultTargetPlatform == TargetPlatform.iOS;

/// Largest source photo accepted, before it becomes a base64 blob on web.
const _maxAvatarBytes = 5 * 1024 * 1024;

Future<void> showAvatarPhotoSheet(
  BuildContext context, {
  required String userId,
  required bool hasPhoto,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) => _AvatarPhotoSheet(userId: userId, hasPhoto: hasPhoto),
  );
}

class _AvatarPhotoSheet extends ConsumerStatefulWidget {
  const _AvatarPhotoSheet({required this.userId, required this.hasPhoto});

  final String userId;
  final bool hasPhoto;

  @override
  ConsumerState<_AvatarPhotoSheet> createState() => _AvatarPhotoSheetState();
}

class _AvatarPhotoSheetState extends ConsumerState<_AvatarPhotoSheet> {
  bool _busy = false;
  String? _error;

  Future<void> _fromCamera() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final t = AppLocalizations.of(context)!;
    try {
      final photo = await ImagePicker().pickImage(source: ImageSource.camera);
      if (photo == null || !mounted) return;
      await _handleBytes(await photo.readAsBytes(), extension: 'jpg', t: t);
    } catch (_) {
      if (mounted) setState(() => _error = t.photoUploadFailedError);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _fromFiles() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final t = AppLocalizations.of(context)!;
    try {
      final file = await FilePicker.pickFile(type: FileType.image);
      if (file == null || !mounted) return;
      await _handleBytes(
        await file.readAsBytes(),
        extension: file.extension ?? 'jpg',
        t: t,
      );
    } catch (_) {
      if (mounted) setState(() => _error = t.photoUploadFailedError);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _handleBytes(
    Uint8List bytes, {
    required String extension,
    required AppLocalizations t,
  }) async {
    if (!mounted) return;
    if (bytes.length > _maxAvatarBytes) {
      setState(() => _error = t.photoTooLargeError);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final avatarPath = kIsWeb
          ? 'data:image/$extension;base64,${base64Encode(bytes)}'
          : await _storeOnDisk(bytes, extension);
      await _save(avatarPath);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = t.photoUploadFailedError;
      });
    }
  }

  Future<String> _storeOnDisk(Uint8List bytes, String extension) async {
    final base = await getApplicationSupportDirectory();
    final dir = Directory('${base.path}/avatars');
    await dir.create(recursive: true);
    final path =
        '${dir.path}/${widget.userId}_'
        '${DateTime.now().microsecondsSinceEpoch}.$extension';
    await File(path).writeAsBytes(bytes, flush: true);
    return path;
  }

  Future<void> _save(String? avatarPath) async {
    final result = await ref
        .read(userRepositoryProvider)
        .setAvatarPath(id: widget.userId, avatarPath: avatarPath);
    if (!mounted) return;
    switch (result) {
      case Ok():
        ref.invalidate(patientProfileProvider);
        Navigator.of(context).pop();
      case Err(:final failure):
        setState(() {
          _busy = false;
          _error = describeFailure(
            AppLocalizations.of(context)!,
            failure,
          ).message;
        });
    }
  }

  Future<void> _remove() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    await _save(null);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(Space.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(t.profilePhotoTitle, style: theme.textTheme.titleLarge),
            const SizedBox(height: Space.md),
            if (_cameraAvailable) ...[
              OutlinedButton.icon(
                icon: const Icon(Icons.photo_camera_outlined),
                label: Text(t.takePhotoAction),
                onPressed: _busy ? null : _fromCamera,
              ),
              const SizedBox(height: Space.sm),
            ],
            OutlinedButton.icon(
              icon: const Icon(Icons.photo_library_outlined),
              label: Text(t.choosePhotoAction),
              onPressed: _busy ? null : _fromFiles,
            ),
            if (widget.hasPhoto) ...[
              const SizedBox(height: Space.sm),
              TextButton.icon(
                icon: const Icon(Icons.no_photography_outlined),
                label: Text(t.removePhotoAction),
                style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.error,
                ),
                onPressed: _busy ? null : _remove,
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: Space.sm),
              InlineBanner.error(_error!),
            ],
            if (_busy) ...[
              const SizedBox(height: Space.md),
              const Center(
                child: SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

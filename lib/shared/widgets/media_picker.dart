import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/l10n_ext.dart';

/// Selector de fotos (cámara o galería) con miniaturas y botón quitar.
class MediaPickerField extends StatelessWidget {
  const MediaPickerField({
    super.key,
    required this.paths,
    required this.onChanged,
    this.max = 8,
  });

  final List<String> paths;
  final ValueChanged<List<String>> onChanged;
  final int max;

  Future<void> _pick(BuildContext context) async {
    final l = context.l10n;
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (c) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined,
                  color: SrRobotColors.primaryTeal),
              title: Text(l.commonCamera, style: AppText.body),
              onTap: () => Navigator.pop(c, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined,
                  color: SrRobotColors.primaryTeal),
              title: Text(l.commonGallery, style: AppText.body),
              onTap: () => Navigator.pop(c, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (source == null) return;
    final picker = ImagePicker();
    final remaining = max - paths.length;
    List<XFile> picked;
    if (source == ImageSource.camera) {
      final one = await picker.pickImage(
          source: ImageSource.camera, imageQuality: 75, maxWidth: 1600);
      picked = one == null ? [] : [one];
    } else {
      picked = await picker.pickMultiImage(
          imageQuality: 75, maxWidth: 1600, limit: remaining > 1 ? remaining : null);
    }
    if (picked.isEmpty) return;
    onChanged([...paths, ...picked.map((x) => x.path)].take(max).toList());
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 84,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          if (paths.length < max)
            GestureDetector(
              onTap: () => _pick(context),
              child: Container(
                width: 84,
                decoration: BoxDecoration(
                  color: SrRobotColors.softTeal,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: SrRobotColors.primaryTeal),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.add_a_photo_outlined,
                        color: SrRobotColors.primaryTeal),
                    const SizedBox(height: 4),
                    Text(context.l10n.commonAddPhoto,
                        textAlign: TextAlign.center,
                        style: AppText.tag
                            .copyWith(color: SrRobotColors.darkTeal)),
                  ],
                ),
              ),
            ),
          for (final p in paths)
            Padding(
              padding: const EdgeInsets.only(left: 10),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.file(File(p),
                        width: 84, height: 84, fit: BoxFit.cover),
                  ),
                  Positioned(
                    right: 4,
                    top: 4,
                    child: GestureDetector(
                      onTap: () =>
                          onChanged(paths.where((x) => x != p).toList()),
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                            color: SrRobotColors.textInk,
                            shape: BoxShape.circle),
                        child: const Icon(Icons.close_rounded,
                            size: 14, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

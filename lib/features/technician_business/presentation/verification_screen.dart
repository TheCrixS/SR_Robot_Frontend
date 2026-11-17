import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/l10n_ext.dart';
import '../../../shared/data/business_repository.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/robot_avatar.dart';
import '../../../shared/widgets/sr_card.dart';

/// Carga de documentos (ID/RUT + foto del local) y envío a revisión.
class VerificationScreen extends ConsumerStatefulWidget {
  const VerificationScreen({super.key});

  @override
  ConsumerState<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends ConsumerState<VerificationScreen> {
  final Map<String, String> _docs = {};
  bool _busy = false;
  String? _error;

  Future<void> _pick(String type) async {
    final x = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 80, maxWidth: 2000);
    if (x != null) setState(() => _docs[type] = x.path);
  }

  Future<void> _submit() async {
    final l = context.l10n;
    if (!_docs.containsKey('ID') && !_docs.containsKey('RUT')) {
      setState(() => _error = l.verifyNeedId);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(businessRepositoryProvider).submitVerification(_docs);
      ref.invalidate(myBusinessProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l.verifySent)));
      context.pop();
    } catch (e) {
      if (mounted) setState(() => _error = errorText(context, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final docs = [
      ('ID', l.verifyDocId, Icons.badge_outlined),
      ('RUT', l.verifyDocRut, Icons.description_outlined),
      ('LOCAL_PHOTO', l.verifyDocLocal, Icons.storefront_outlined),
    ];
    return Scaffold(
      appBar: AppBar(title: Text(l.verifyTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        children: [
          const Center(child: RobotAvatar(size: 96)),
          const SizedBox(height: 12),
          Text(l.verifyBody, textAlign: TextAlign.center, style: AppText.bodyGray),
          const SizedBox(height: 20),
          for (final (type, label, icon) in docs) ...[
            SrCard(
              onTap: () => _pick(type),
              child: Row(
                children: [
                  Icon(icon, color: SrRobotColors.primaryTeal),
                  const SizedBox(width: 12),
                  Expanded(child: Text(label, style: AppText.bodyMedium)),
                  if (_docs.containsKey(type))
                    const Icon(Icons.check_circle_rounded,
                        color: SrRobotColors.lime),
                  const SizedBox(width: 8),
                  Text(_docs.containsKey(type) ? l.verifyChange : l.verifyPick,
                      style: AppText.meta.copyWith(
                          color: SrRobotColors.primaryTeal,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
          if (_error != null) ...[
            const SizedBox(height: 6),
            Text(_error!,
                style: AppText.meta.copyWith(color: SrRobotColors.alertRed)),
          ],
          const SizedBox(height: 16),
          SrButton(label: l.verifySubmit, loading: _busy, onPressed: _submit),
        ],
      ),
    );
  }
}

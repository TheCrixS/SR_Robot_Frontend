import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_settings.dart';
import '../../../core/config/regional_profile.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/l10n_ext.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/widgets/brand_header.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/robot_avatar.dart';
import '../data/auth_repository.dart';
import '../domain/session_controller.dart';
import 'otp_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  UserRole _role = UserRole.client;
  bool _usePhone = true;
  bool _usePassword = false;
  bool _loading = false;
  String? _error;
  late RegionProfile _region = ref.read(regionProfileProvider);

  final _idCtrl = TextEditingController();
  final _pwdCtrl = TextEditingController();

  @override
  void dispose() {
    _idCtrl.dispose();
    _pwdCtrl.dispose();
    super.dispose();
  }

  LoginIdentifier? _identifier() {
    final l = context.l10n;
    final raw = _idCtrl.text.trim();
    if (_usePhone) {
      final digits = raw.replaceAll(RegExp(r'\D'), '');
      if (!Validators.isPhone(digits)) {
        setState(() => _error = l.loginInvalidPhone);
        return null;
      }
      return LoginIdentifier.phone('${_region.phonePrefix}$digits');
    }
    if (!Validators.isEmail(raw)) {
      setState(() => _error = l.loginInvalidEmail);
      return null;
    }
    return LoginIdentifier.email(raw.toLowerCase());
  }

  Future<void> _submit() async {
    final l = context.l10n;
    setState(() => _error = null);
    final id = _identifier();
    if (id == null) return;

    if (_usePassword && !Validators.isPassword(_pwdCtrl.text)) {
      setState(() => _error = l.loginInvalidPassword);
      return;
    }

    setState(() => _loading = true);
    final repo = ref.read(authRepositoryProvider);
    try {
      if (_usePassword) {
        final user = await repo.loginWithPassword(id, _pwdCtrl.text, _role);
        final ok =
            await ref.read(sessionProvider.notifier).signedIn(user, _role);
        if (!ok && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l.loginNoTechnicianRole)));
        }
      } else {
        final res = await repo.requestOtp(id);
        if (!mounted) return;
        context.push(Routes.otp,
            extra: OtpArgs(identifier: id, role: _role, request: res));
      }
    } catch (e) {
      if (!mounted) return;
      final err = ApiException.from(e);
      setState(() => _error =
          err.statusCode == 401 ? l.loginWrongCredentials : errorText(context, e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            BrandHeader(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
              child: Column(
                children: [
                  const RobotAvatar(size: 110),
                  const SizedBox(height: 12),
                  Text(l.loginTitle,
                      style: AppText.h1.copyWith(color: Colors.white)),
                  const SizedBox(height: 6),
                  Text(
                    l.loginSubtitle,
                    textAlign: TextAlign.center,
                    style: AppText.body
                        .copyWith(color: Colors.white.withValues(alpha: 0.92)),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _RoleCard(
                          emoji: '🛠️',
                          title: l.loginNeedRepair,
                          subtitle: l.loginNeedRepairHint,
                          selected: _role == UserRole.client,
                          onTap: () => setState(() => _role = UserRole.client),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _RoleCard(
                          emoji: '🔧',
                          title: l.loginIamTechnician,
                          subtitle: l.loginIamTechnicianHint,
                          selected: _role == UserRole.technician,
                          onTap: () =>
                              setState(() => _role = UserRole.technician),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _Segmented(
                    left: l.loginPhoneTab,
                    right: l.loginEmailTab,
                    leftSelected: _usePhone,
                    onChanged: (phone) => setState(() {
                      _usePhone = phone;
                      _idCtrl.clear();
                      _error = null;
                    }),
                  ),
                  const SizedBox(height: 14),
                  if (_usePhone)
                    Row(
                      children: [
                        _CountryPrefix(
                          region: _region,
                          onChanged: (r) {
                            setState(() => _region = r);
                            ref
                                .read(appSettingsProvider.notifier)
                                .setCountry(r.countryCode);
                          },
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _idCtrl,
                            keyboardType: TextInputType.phone,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                  RegExp(r'[0-9 ]')),
                            ],
                            style: AppText.body,
                            decoration:
                                InputDecoration(hintText: l.loginPhoneHint),
                          ),
                        ),
                      ],
                    )
                  else
                    TextField(
                      controller: _idCtrl,
                      keyboardType: TextInputType.emailAddress,
                      autocorrect: false,
                      style: AppText.body,
                      decoration: InputDecoration(
                        hintText: l.loginEmailHint,
                        prefixIcon: const Icon(Icons.mail_outline_rounded,
                            color: SrRobotColors.textGray),
                      ),
                    ),
                  if (_usePassword) ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: _pwdCtrl,
                      obscureText: true,
                      style: AppText.body,
                      decoration: InputDecoration(
                        hintText: l.loginPasswordHint,
                        prefixIcon: const Icon(Icons.lock_outline_rounded,
                            color: SrRobotColors.textGray),
                      ),
                      onSubmitted: (_) => _submit(),
                    ),
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: 10),
                    Text(_error!,
                        style: AppText.meta
                            .copyWith(color: SrRobotColors.alertRed)),
                  ],
                  const SizedBox(height: 20),
                  SrButton(
                    label: _usePassword ? l.loginSubmitPassword : l.loginSendCode,
                    loading: _loading,
                    onPressed: _submit,
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => setState(() {
                      _usePassword = !_usePassword;
                      _error = null;
                    }),
                    child: Text(
                      _usePassword ? l.loginWithCode : l.loginWithPassword,
                      style: AppText.bodyMedium
                          .copyWith(color: SrRobotColors.primaryTeal),
                    ),
                  ),
                  _DemoSwitch(
                    value: ref.watch(appSettingsProvider).demoMode,
                    onChanged: (v) {
                      ref.read(appSettingsProvider.notifier).setDemoMode(v);
                      setState(() => _error = null);
                    },
                  ),
                  // Wrap: si no cabe en una línea, "Crear cuenta" baja sin desbordar.
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(l.loginNoAccount, style: AppText.meta),
                      TextButton(
                        onPressed: () =>
                            context.push(Routes.register, extra: _role),
                        child: Text(
                          l.loginCreateAccount,
                          style: AppText.meta.copyWith(
                              color: SrRobotColors.primaryTeal,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DemoSwitch extends StatelessWidget {
  const _DemoSwitch({required this.value, required this.onChanged});
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Container(
      margin: const EdgeInsets.only(top: 4, bottom: 4),
      padding: const EdgeInsets.fromLTRB(14, 4, 6, 4),
      decoration: BoxDecoration(
        color: value
            ? SrRobotColors.yellowAccent.withValues(alpha: 0.35)
            : SrRobotColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SrRobotColors.lineBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.science_outlined,
                  size: 20, color: SrRobotColors.textGray),
              const SizedBox(width: 8),
              Expanded(child: Text(l.loginDemoMode, style: AppText.bodyMedium)),
              Switch(value: value, onChanged: onChanged),
            ],
          ),
          if (value)
            Padding(
              padding: const EdgeInsets.only(bottom: 8, right: 8),
              child: Text(l.loginDemoHint, style: AppText.small),
            ),
        ],
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String emoji;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? SrRobotColors.softTeal : SrRobotColors.surfaceWhite,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? SrRobotColors.primaryTeal
                : SrRobotColors.lineBorder,
            width: 1.5,
          ),
          boxShadow: SrRobotColors.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 26)),
            const SizedBox(height: 8),
            Text(title, style: AppText.bodyMedium.copyWith(fontWeight: FontWeight.w700)),
            Text(subtitle, style: AppText.small),
          ],
        ),
      ),
    );
  }
}

class _Segmented extends StatelessWidget {
  const _Segmented({
    required this.left,
    required this.right,
    required this.leftSelected,
    required this.onChanged,
  });

  final String left;
  final String right;
  final bool leftSelected;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget seg(String text, bool selected, bool value) => Expanded(
          child: GestureDetector(
            onTap: () => onChanged(value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.symmetric(vertical: 10),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? SrRobotColors.surfaceWhite : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                boxShadow: selected ? SrRobotColors.cardShadow : null,
              ),
              child: Text(
                text,
                style: AppText.meta.copyWith(
                  color: selected ? SrRobotColors.textInk : SrRobotColors.textGray,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        );

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: SrRobotColors.lineBorder.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(children: [
        seg(left, leftSelected, true),
        seg(right, !leftSelected, false),
      ]),
    );
  }
}

class _CountryPrefix extends StatelessWidget {
  const _CountryPrefix({required this.region, required this.onChanged});
  final RegionProfile region;
  final ValueChanged<RegionProfile> onChanged;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<RegionProfile>(
      onSelected: onChanged,
      itemBuilder: (_) => [
        for (final r in RegionProfile.all)
          PopupMenuItem(
            value: r,
            child: Text('${r.phonePrefix}  ${r.countryName}', style: AppText.body),
          ),
      ],
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: SrRobotColors.surfaceWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: SrRobotColors.lineBorder),
        ),
        child: Row(
          children: [
            Text(region.phonePrefix, style: AppText.bodyMedium),
            const Icon(Icons.keyboard_arrow_down_rounded,
                color: SrRobotColors.textGray),
          ],
        ),
      ),
    );
  }
}

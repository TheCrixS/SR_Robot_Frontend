import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/regional_profile.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/l10n_ext.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/widgets/custom_button.dart';
import '../data/auth_repository.dart';
import '../domain/session_controller.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key, this.initialRole});
  final UserRole? initialRole;

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _pwd = TextEditingController();
  bool _terms = false;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _pwd.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l = context.l10n;
    final region = ref.read(regionProfileProvider);
    final email = _email.text.trim().toLowerCase();
    final phoneDigits = _phone.text.replaceAll(RegExp(r'\D'), '');

    String? err;
    if (_name.text.trim().isEmpty) {
      err = l.registerNameRequired;
    } else if (email.isNotEmpty && !Validators.isEmail(email)) {
      err = l.loginInvalidEmail;
    } else if (email.isEmpty && !Validators.isPhone(phoneDigits)) {
      err = l.loginInvalidPhone;
    } else if (!Validators.isPassword(_pwd.text)) {
      err = l.loginInvalidPassword;
    } else if (!_terms) {
      err = l.registerTermsRequired;
    }
    if (err != null) {
      setState(() => _error = err);
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final id = email.isNotEmpty
          ? LoginIdentifier.email(email)
          : LoginIdentifier.phone('${region.phonePrefix}$phoneDigits');
      final role = widget.initialRole ?? UserRole.client;
      final user = await ref.read(authRepositoryProvider).register(
            name: _name.text.trim(),
            id: id,
            password: _pwd.text,
            role: role,
            country: region.countryCode,
            locale: region.locale.replaceAll('_', '-'),
          );
      await ref.read(sessionProvider.notifier).signedIn(user, user.activeRole);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = ApiException.from(e).statusCode == 409
          ? l.registerAlreadyExists
          : errorText(context, e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final region = ref.watch(regionProfileProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l.registerTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          TextField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            style: AppText.body,
            decoration: InputDecoration(hintText: l.registerName),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            style: AppText.body,
            decoration: InputDecoration(hintText: l.loginEmailHint),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            style: AppText.body,
            decoration: InputDecoration(
              hintText: l.loginPhoneHint,
              prefixText: '${region.phonePrefix} ',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _pwd,
            obscureText: true,
            style: AppText.body,
            decoration: InputDecoration(hintText: l.loginPasswordHint),
          ),
          const SizedBox(height: 8),
          CheckboxListTile(
            value: _terms,
            onChanged: (v) => setState(() => _terms = v ?? false),
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            activeColor: SrRobotColors.primaryTeal,
            title: Text(l.registerAcceptTerms, style: AppText.meta),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(_error!,
                  style: AppText.meta.copyWith(color: SrRobotColors.alertRed)),
            ),
          const SizedBox(height: 12),
          SrButton(
              label: l.registerSubmit, loading: _loading, onPressed: _submit),
        ],
      ),
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/l10n_ext.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/widgets/custom_button.dart';
import '../data/auth_repository.dart';
import '../domain/session_controller.dart';

class OtpArgs {
  final LoginIdentifier identifier;
  final UserRole role;
  final OtpRequestResult request;
  const OtpArgs(
      {required this.identifier, required this.role, required this.request});
}

/// Verificación de 6 dígitos con auto-enfoque y cuenta regresiva de 60 s.
class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({super.key, required this.args});
  final OtpArgs args;

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  static const _length = 6;
  final _ctrls = List.generate(_length, (_) => TextEditingController());
  final _nodes = List.generate(_length, (_) => FocusNode());

  Timer? _timer;
  int _seconds = 60;
  bool _loading = false;
  String? _error;
  late String? _demoCode = widget.args.request.demoCode;

  @override
  void initState() {
    super.initState();
    _startTimer();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _nodes.first.requestFocus());
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _seconds = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_seconds <= 1) t.cancel();
      if (mounted) setState(() => _seconds--);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _ctrls) {
      c.dispose();
    }
    for (final n in _nodes) {
      n.dispose();
    }
    super.dispose();
  }

  String get _code => _ctrls.map((c) => c.text).join();

  void _onChanged(int i, String v) {
    if (v.length > 1) {
      // Pegado de código completo.
      final digits = v.replaceAll(RegExp(r'\D'), '');
      for (var k = 0; k < _length; k++) {
        _ctrls[k].text = k < digits.length ? digits[k] : '';
      }
      final last = digits.isEmpty
          ? 0
          : (digits.length > _length ? _length : digits.length) - 1;
      _nodes[last].requestFocus();
    } else if (v.isNotEmpty && i < _length - 1) {
      _nodes[i + 1].requestFocus();
    } else if (v.isEmpty && i > 0) {
      _nodes[i - 1].requestFocus();
    }
    setState(() => _error = null);
    if (_code.length == _length) _verify();
  }

  Future<void> _verify() async {
    if (_loading || _code.length != _length) return;
    final l = context.l10n;
    setState(() => _loading = true);
    try {
      final repo = ref.read(authRepositoryProvider);
      final user = await repo.verifyOtp(widget.args.identifier, _code);
      final ok = await ref
          .read(sessionProvider.notifier)
          .signedIn(user, widget.args.role);
      if (!ok && mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l.loginNoTechnicianRole)));
      }
    } catch (e) {
      if (!mounted) return;
      final err = ApiException.from(e);
      setState(() => _error = (err.statusCode == 400 || err.statusCode == 401)
          ? l.otpInvalid
          : errorText(context, e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resend() async {
    final l = context.l10n;
    try {
      final res = await ref
          .read(authRepositoryProvider)
          .requestOtp(widget.args.identifier);
      if (!mounted) return;
      setState(() => _demoCode = res.demoCode);
      _startTimer();
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l.otpResent)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(errorText(context, e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.otpTitle, style: AppText.h1),
              const SizedBox(height: 6),
              Text(l.otpSubtitle(widget.args.identifier.display),
                  style: AppText.bodyGray),
              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (var i = 0; i < _length; i++)
                    SizedBox(
                      width: 50,
                      height: 58,
                      child: TextField(
                        controller: _ctrls[i],
                        focusNode: _nodes[i],
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        style: AppText.h2,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(_length),
                        ],
                        decoration: InputDecoration(
                          contentPadding: EdgeInsets.zero,
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: _error != null
                                  ? SrRobotColors.alertRed
                                  : SrRobotColors.lineBorder,
                            ),
                          ),
                        ),
                        onChanged: (v) => _onChanged(i, v),
                      ),
                    ),
                ],
              ),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(_error!,
                    style:
                        AppText.meta.copyWith(color: SrRobotColors.alertRed)),
              ],
              if (_demoCode != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: SrRobotColors.yellowAccent.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(l.otpDemoCode(_demoCode!), style: AppText.meta),
                ),
              ],
              const SizedBox(height: 20),
              Center(
                child: _seconds > 0
                    ? Text(l.otpResendIn(_seconds), style: AppText.meta)
                    : TextButton(
                        onPressed: _resend,
                        child: Text(l.otpResend,
                            style: AppText.bodyMedium
                                .copyWith(color: SrRobotColors.primaryTeal)),
                      ),
              ),
              const Spacer(),
              SrButton(
                label: l.otpVerify,
                loading: _loading,
                onPressed: _code.length == _length ? _verify : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/l10n_ext.dart';
import 'custom_button.dart';
import 'robot_avatar.dart';

/// Estado vacío con la mascota.
class EmptyStateView extends StatelessWidget {
  const EmptyStateView({
    super.key,
    required this.title,
    this.body,
    this.actionLabel,
    this.onAction,
    this.robotSize = 120,
  });

  final String title;
  final String? body;
  final String? actionLabel;
  final VoidCallback? onAction;
  final double robotSize;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RobotAvatar(size: robotSize),
            const SizedBox(height: 16),
            Text(title, style: AppText.h3, textAlign: TextAlign.center),
            if (body != null) ...[
              const SizedBox(height: 6),
              Text(body!, style: AppText.bodyGray, textAlign: TextAlign.center),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 20),
              SrButton(
                  label: actionLabel!, onPressed: onAction, expand: false),
            ],
          ],
        ),
      ),
    );
  }
}

/// Pantalla de carga con la mascota.
class LoadingView extends StatelessWidget {
  const LoadingView({super.key, this.message});
  final String? message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const RobotAvatar(size: 88),
          const SizedBox(height: 12),
          Text(message ?? context.l10n.commonLoading, style: AppText.meta),
        ],
      ),
    );
  }
}

/// Error con botón de reintento.
class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.error, required this.onRetry});
  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return EmptyStateView(
      title: errorText(context, error),
      actionLabel: context.l10n.commonRetry,
      onAction: onRetry,
      robotSize: 96,
    );
  }
}

/// Placeholder de secciones pendientes de la siguiente fase.
class ComingSoonScreen extends StatelessWidget {
  const ComingSoonScreen({super.key, this.title});
  final String? title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: title == null ? null : AppBar(title: Text(title!)),
      body: EmptyStateView(
        title: context.l10n.commonComingSoonTitle,
        body: context.l10n.commonComingSoonBody,
      ),
    );
  }
}

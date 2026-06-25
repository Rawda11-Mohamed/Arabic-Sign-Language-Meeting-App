import 'package:flutter/material.dart';

/// Reusable card widget with accessibility support
class AppCard extends StatelessWidget {
  final String? title;
  final List<Widget> children;
  final List<AppCardAction>? actions;
  final EdgeInsets? padding;
  final VoidCallback? onTap;

  const AppCard({
    super.key,
    this.title,
    required this.children,
    this.actions,
    this.padding,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: onTap != null,
      label: title ?? 'Card',
      child: Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null) ...[
                  Text(
                    title!,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                ],
                ...children,
                if (actions != null && actions!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  ...actions!.map((action) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: AppCardActionButton(action: action),
                      )),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Card action model
class AppCardAction {
  final String label;
  final VoidCallback onTap;
  final IconData? icon;

  const AppCardAction({
    required this.label,
    required this.onTap,
    this.icon,
  });
}

/// Card action button widget
class AppCardActionButton extends StatelessWidget {
  final AppCardAction action;

  const AppCardActionButton({super.key, required this.action});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: action.onTap,
        icon: action.icon != null
            ? Icon(action.icon)
            : const SizedBox.shrink(),
        label: Text(action.label),
        style: OutlinedButton.styleFrom(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }
}


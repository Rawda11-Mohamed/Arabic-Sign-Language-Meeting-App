import 'package:flutter/material.dart';

/// Reusable toggle switch widget with accessibility support
class AppToggle extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final String? description;

  const AppToggle({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      value: value ? 'Enabled' : 'Disabled',
      child: SwitchListTile(
        title: Text(label),
        subtitle: description != null ? Text(description!) : null,
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}


import 'package:flutter/material.dart';

/// Reusable dropdown widget with accessibility support
class AppDropdown<T> extends StatelessWidget {
  final String label;
  final List<T> options;
  final T? value;
  final ValueChanged<T?> onChanged;
  final String Function(T) getLabel;

  const AppDropdown({
    super.key,
    required this.label,
    required this.options,
    this.value,
    required this.onChanged,
    required this.getLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      value: value != null ? getLabel(value as T) : null,
      child: DropdownButtonFormField<T>(
        decoration: InputDecoration(
          labelText: label,
        ),
        value: value,
        items: options.map((option) {
          return DropdownMenuItem<T>(
            value: option,
            child: Text(getLabel(option)),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }
}


import 'package:flutter/material.dart';

/// Reusable radio group widget with accessibility support
class AppRadioGroup<T> extends StatelessWidget {
  final String label;
  final List<T> options;
  final T? selectedValue;
  final ValueChanged<T?> onChanged;
  final String Function(T) getLabel;

  const AppRadioGroup({
    super.key,
    required this.label,
    required this.options,
    this.selectedValue,
    required this.onChanged,
    required this.getLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          ...options.map((option) => RadioListTile<T>(
                title: Text(getLabel(option)),
                value: option,
                groupValue: selectedValue,
                onChanged: onChanged,
                contentPadding: EdgeInsets.zero,
              )),
        ],
      ),
    );
  }
}


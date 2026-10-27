import 'package:flutter/material.dart';

import '../core/date_preset.dart';

class DateFilterButton extends StatelessWidget {
  final DatePreset value;
  final ValueChanged<DatePreset> onChanged;

  const DateFilterButton({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<DatePreset>(
      tooltip: 'Filter by date',
      initialValue: value,
      onSelected: onChanged,
      itemBuilder: (context) => [
        for (final preset in DatePreset.values)
          PopupMenuItem(
            value: preset,
            child: Row(
              children: [
                if (preset == value)
                  const Icon(Icons.check, size: 18)
                else
                  const SizedBox(width: 18),
                const SizedBox(width: 10),
                Text(preset.label),
              ],
            ),
          ),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.event_outlined, size: 18),
            const SizedBox(width: 6),
            Text(
              value.label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

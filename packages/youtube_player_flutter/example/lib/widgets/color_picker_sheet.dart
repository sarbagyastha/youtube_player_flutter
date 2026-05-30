// Copyright 2021 Sarbagya Dhaubanjar. All rights reserved.
// Use of this source code is governed by a BSD-3-Clause license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

class ColorPickerSheet extends StatelessWidget {
  const ColorPickerSheet({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final Color selected;
  final ValueChanged<Color> onSelected;

  static const _swatches = <({Color color, String label})>[
    (color: Color(0xFF4CAF50), label: 'Green'),
    (color: Color(0xFF2196F3), label: 'Blue'),
    (color: Color(0xFF9C27B0), label: 'Purple'),
    (color: Color(0xFFE91E63), label: 'Pink'),
    (color: Color(0xFFF44336), label: 'Red'),
    (color: Color(0xFFFF9800), label: 'Orange'),
    (color: Color(0xFF009688), label: 'Teal'),
    (color: Color(0xFF00BCD4), label: 'Cyan'),
    (color: Color(0xFF3F51B5), label: 'Indigo'),
    (color: Color(0xFF673AB7), label: 'Deep Purple'),
    (color: Color(0xFFFFC107), label: 'Amber'),
    (color: Color(0xFF03A9F4), label: 'Light Blue'),
  ];

  static void show(
    BuildContext context, {
    required Color selected,
    required ValueChanged<Color> onSelected,
  }) {
    showModalBottomSheet<void>(
      context: context,
      builder: (_) =>
          ColorPickerSheet(selected: selected, onSelected: onSelected),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Theme Color', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 20),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _swatches.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
            ),
            itemBuilder: (context, i) {
              final entry = _swatches[i];
              final isSelected = entry.color.toARGB32() == selected.toARGB32();
              return GestureDetector(
                onTap: () {
                  onSelected(entry.color);
                  Navigator.of(context).pop();
                },
                child: Semantics(
                  label: entry.label,
                  selected: isSelected,
                  button: true,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    decoration: BoxDecoration(
                      color: entry.color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? Colors.white : Colors.transparent,
                        width: 3,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: entry.color.withValues(alpha: 0.6),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ]
                          : null,
                    ),
                    child: isSelected
                        ? const Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 22,
                          )
                        : null,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

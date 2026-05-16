import 'package:flutter/material.dart';

class LabeledValue extends StatelessWidget {
  const LabeledValue(this.label, this.value, {super.key});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        text: '$label: ',
        style: Theme.of(context).textTheme.labelLarge,
        children: [
          TextSpan(
            text: value,
            style: Theme.of(context)
                .textTheme
                .labelMedium!
                .copyWith(fontWeight: FontWeight.w300),
          ),
        ],
      ),
    );
  }
}

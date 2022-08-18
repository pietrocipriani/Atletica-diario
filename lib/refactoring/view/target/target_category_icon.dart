import 'package:atletica/refactoring/model/target.dart';
import 'package:flutter/material.dart';

class TargetCategoryIcon extends StatelessWidget {
  final TargetCategory category;

  const TargetCategoryIcon(this.category, {super.key});

  IconData get _icon {
    switch (category) {
      case TargetCategory.males:
        return Icons.male;
      case TargetCategory.females:
        return Icons.female;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Icon(_icon, color: category.color);
  }
}

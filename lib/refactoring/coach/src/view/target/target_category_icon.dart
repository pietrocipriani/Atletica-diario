import 'package:atletica/refactoring/common/common.dart';
import 'package:flutter/material.dart';

/// The icon [Widget] representing a target category
class TargetCategoryIcon extends StatelessWidget {
  final TargetCategory category;
  final bool mini;

  const TargetCategoryIcon(this.category, {super.key, this.mini = false});

  /// returns the corresponding [IconData]
  IconData get _icon {
    switch (category) {
      case TargetCategory.males:
        return Icons.man;
      case TargetCategory.females:
        return Icons.woman;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Icon(_icon, color: category.color, size: mini ? 16 : null);
  }
}

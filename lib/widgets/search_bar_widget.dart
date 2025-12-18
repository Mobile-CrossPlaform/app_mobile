import 'package:flutter/material.dart';
import '../core/core.dart';

/// Barre de recherche réutilisable
class SearchBarWidget extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;
  final bool showClearButton;
  final bool elevated;

  const SearchBarWidget({
    super.key,
    required this.controller,
    this.focusNode,
    this.hintText = 'Rechercher...',
    this.onChanged,
    this.onClear,
    this.showClearButton = true,
    this.elevated = true,
  });

  @override
  Widget build(BuildContext context) {
    final content = TextField(
      controller: controller,
      focusNode: focusNode,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: const Icon(Icons.search),
        suffixIcon: showClearButton && controller.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  controller.clear();
                  onClear?.call();
                },
              )
            : null,
        border: elevated ? InputBorder.none : OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.cardBorderRadius),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: 14,
        ),
        filled: !elevated,
        fillColor: Colors.grey[100],
      ),
    );

    if (elevated) {
      return Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.cardBorderRadius),
        ),
        child: content,
      );
    }

    return content;
  }
}

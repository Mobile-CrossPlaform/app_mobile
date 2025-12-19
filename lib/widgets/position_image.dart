import 'dart:io';
import 'package:flutter/material.dart';
import '../core/constants.dart';

/// Widget pour afficher une image de position (locale, réseau ou placeholder)
class PositionImage extends StatelessWidget {
  final String? imageUrl;
  final String? localImagePath;
  final double height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final List<String>? tags; // Tags shown below the image when provided

  const PositionImage({
    super.key,
    this.imageUrl,
    this.localImagePath,
    this.height = AppSizes.cardImageHeight,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.tags,
  });

  @override
  Widget build(BuildContext context) {
    Widget imageWidget;

    if (localImagePath != null) {
      imageWidget = Image.file(
        File(localImagePath!),
        height: height,
        width: double.infinity,
        fit: fit,
        errorBuilder: (_, __, ___) => _buildPlaceholder(),
      );
    } else if (imageUrl != null) {
      imageWidget = Image.network(
        imageUrl!,
        height: height,
        width: double.infinity,
        fit: fit,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _buildLoading();
        },
        errorBuilder: (_, __, ___) => _buildError(),
      );
    } else {
      imageWidget = _buildPlaceholder();
    }

    // Apply border radius to the image only
    final clippedImage = borderRadius != null
        ? ClipRRect(borderRadius: borderRadius!, child: imageWidget)
        : imageWidget;

    // If tags exist, render them below the image
    if (tags != null && tags!.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          clippedImage,
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: tags!
                .map(
                  (tag) => Chip(
                    label: Text(tag),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                )
                .toList(),
          ),
        ],
      );
    }

    return clippedImage;
  }

  Widget _buildLoading() {
    return Container(
      height: height,
      color: Colors.grey[200],
      child: const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildError() {
    return Container(
      height: height,
      color: Colors.grey[300],
      child: const Center(child: Icon(Icons.image_not_supported, size: 40)),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      height: height,
      color: Colors.deepPurple.withValues(alpha: 0.1),
      child: const Center(
        child: Icon(Icons.location_on, size: 40, color: Colors.deepPurple),
      ),
    );
  }
}

/// Widget placeholder pour les images
class ImagePlaceholder extends StatelessWidget {
  final double height;
  final IconData icon;
  final Color? iconColor;
  final Color? backgroundColor;

  const ImagePlaceholder({
    super.key,
    this.height = AppSizes.cardImageHeight,
    this.icon = Icons.location_on,
    this.iconColor,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: height,
      color:
          backgroundColor ?? theme.colorScheme.primary.withValues(alpha: 0.1),
      child: Center(
        child: Icon(
          icon,
          size: 40,
          color: iconColor ?? theme.colorScheme.primary,
        ),
      ),
    );
  }
}

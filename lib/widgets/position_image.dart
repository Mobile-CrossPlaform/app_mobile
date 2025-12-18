import 'dart:io';
import 'package:flutter/material.dart';
import '../core/core.dart';

/// Widget d'affichage d'image de position
///
/// Gère l'affichage d'images depuis:
/// - Un fichier local (localImagePath)
/// - Une URL distante (imageUrl)
/// Avec placeholder et gestion des erreurs
class PositionImage extends StatelessWidget {
  final String? imageUrl;
  final String? localImagePath;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? placeholder;
  final Widget? errorWidget;

  const PositionImage({
    super.key,
    this.imageUrl,
    this.localImagePath,
    this.width,
    this.height = AppSizes.cardImageHeight,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    Widget imageWidget;

    // Priorité: image locale > image URL > placeholder
    if (localImagePath != null && localImagePath!.isNotEmpty) {
      final file = File(localImagePath!);
      if (file.existsSync()) {
        imageWidget = Image.file(
          file,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (_, __, ___) => _buildErrorWidget(),
        );
      } else {
        imageWidget = _buildNetworkOrPlaceholder();
      }
    } else {
      imageWidget = _buildNetworkOrPlaceholder();
    }

    // Appliquer le borderRadius si défini
    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: imageWidget,
      );
    }

    return imageWidget;
  }

  Widget _buildNetworkOrPlaceholder() {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return Image.network(
        imageUrl!,
        width: width,
        height: height,
        fit: fit,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _buildLoadingWidget();
        },
        errorBuilder: (_, __, ___) => _buildErrorWidget(),
      );
    }
    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return placeholder ?? Container(
      width: width,
      height: height,
      color: Colors.grey[200],
      child: Icon(
        Icons.image_outlined,
        size: 48,
        color: Colors.grey[400],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return errorWidget ?? Container(
      width: width,
      height: height,
      color: Colors.grey[200],
      child: Icon(
        Icons.broken_image_outlined,
        size: 48,
        color: Colors.grey[400],
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[200],
      child: const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }
}

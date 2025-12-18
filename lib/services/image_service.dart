import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../core/core.dart';

/// Service de sélection d'images
///
/// Ce service gère la prise de photos et la sélection d'images
/// depuis la galerie de l'appareil.
class ImageService {
  // Singleton
  static final ImageService _instance = ImageService._internal();
  factory ImageService() => _instance;
  ImageService._internal();

  final ImagePicker _picker = ImagePicker();

  /// Sélectionne une image depuis la galerie
  Future<File?> pickFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: ImageConfig.maxWidth,
        maxHeight: ImageConfig.maxHeight,
        imageQuality: ImageConfig.quality,
      );
      return image != null ? File(image.path) : null;
    } catch (e) {
      debugPrint('Erreur sélection galerie: $e');
      return null;
    }
  }

  /// Prend une photo avec la caméra
  Future<File?> takePhoto() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: ImageConfig.maxWidth,
        maxHeight: ImageConfig.maxHeight,
        imageQuality: ImageConfig.quality,
      );
      return image != null ? File(image.path) : null;
    } catch (e) {
      debugPrint('Erreur prise de photo: $e');
      return null;
    }
  }

  /// Affiche un dialogue pour choisir la source de l'image
  ///
  /// Retourne le fichier sélectionné ou null si annulé
  Future<File?> showImageSourceDialog(BuildContext context) async {
    // D'abord, demander à l'utilisateur de choisir la source
    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Indicateur de dialogue
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              const Text(
                'Choisir une image',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppSpacing.lg),

              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.blue,
                  child: Icon(Icons.photo_camera, color: Colors.white),
                ),
                title: const Text('Prendre une photo'),
                subtitle: const Text('Utiliser la caméra'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),

              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.green,
                  child: Icon(Icons.photo_library, color: Colors.white),
                ),
                title: const Text('Choisir depuis la galerie'),
                subtitle: const Text('Sélectionner une photo existante'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),

              const SizedBox(height: AppSpacing.sm),

              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annuler'),
              ),
            ],
          ),
        ),
      ),
    );

    // Si aucune source sélectionnée, retourner null
    if (source == null) return null;

    // Récupérer l'image selon la source choisie
    return source == ImageSource.camera
        ? await takePhoto()
        : await pickFromGallery();
  }
}

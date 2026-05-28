import 'dart:io';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

class AttachmentPickerWidget extends StatelessWidget {
  const AttachmentPickerWidget({
    super.key,
    required this.files,
    required this.onAdd,
    required this.onRemove,
    this.maxFiles = 5,
  });

  final List<XFile> files;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;
  final int maxFiles;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (files.isEmpty)
          _EmptyAttachment(onAdd: onAdd)
        else
          _FilledAttachments(
            files: files,
            onAdd: onAdd,
            onRemove: onRemove,
            maxFiles: maxFiles,
          ),
      ],
    );
  }
}

class _EmptyAttachment extends StatelessWidget {
  const _EmptyAttachment({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onAdd,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.border,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Iconsax.camera, size: 22, color: AppColors.primaryLight),
            ),
            const SizedBox(height: 10),
            Text(
              'Adjuntar evidencia fotográfica',
              style: AppTypography.textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Cámara · Galería · PDF · XML',
              style: AppTypography.caption,
            ),
          ],
        ),
      ),
    );
  }
}

class _FilledAttachments extends StatelessWidget {
  const _FilledAttachments({
    required this.files,
    required this.onAdd,
    required this.onRemove,
    required this.maxFiles,
  });
  final List<XFile> files;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;
  final int maxFiles;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Iconsax.image, size: 15, color: AppColors.textTertiary),
            const SizedBox(width: 6),
            Text(
              '${files.length} archivo${files.length != 1 ? 's' : ''} adjunto${files.length != 1 ? 's' : ''}',
              style: AppTypography.caption,
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 92,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              ...List.generate(files.length, (i) {
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: _Thumbnail(
                    file: files[i],
                    onRemove: () => onRemove(i),
                    onTap: () => _previewFile(context, files[i]),
                  ),
                );
              }),
              if (files.length < maxFiles)
                _AddMoreButton(onTap: onAdd),
            ],
          ),
        ),
      ],
    );
  }

  void _previewFile(BuildContext context, XFile file) {
    final isImage = _isImageFile(file.path);
    if (!isImage) return;
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(12),
        child: Stack(
          children: [
            InteractiveViewer(
              child: Image.file(File(file.path), fit: BoxFit.contain),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded, color: Colors.white),
                style: IconButton.styleFrom(backgroundColor: Colors.black45),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isImageFile(String path) {
    final ext = path.toLowerCase().split('.').last;
    return ['jpg', 'jpeg', 'png', 'webp', 'heic', 'heif'].contains(ext);
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.file, required this.onRemove, required this.onTap});
  final XFile file;
  final VoidCallback onRemove;
  final VoidCallback onTap;

  bool get _isImage {
    final ext = file.path.toLowerCase().split('.').last;
    return ['jpg', 'jpeg', 'png', 'webp', 'heic', 'heif'].contains(ext);
  }

  String get _fileName {
    return file.path.split('/').last.split('\\').last;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        GestureDetector(
          onTap: _isImage ? onTap : null,
          child: Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: _isImage
                  ? Image.file(
                      File(file.path),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stack) => _fallbackIcon(),
                    )
                  : _fallbackIcon(),
            ),
          ),
        ),
        // Remove button
        Positioned(
          top: -6,
          right: -6,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              width: 22,
              height: 22,
              decoration: const BoxDecoration(
                color: AppColors.error,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close_rounded, size: 14, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _fallbackIcon() {
    final ext = _fileName.split('.').last.toUpperCase();
    return Container(
      color: AppColors.card,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Iconsax.document_text, size: 24, color: AppColors.textTertiary),
          const SizedBox(height: 4),
          Text(ext, style: AppTypography.caption),
        ],
      ),
    );
  }
}

class _AddMoreButton extends StatelessWidget {
  const _AddMoreButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 84,
        height: 84,
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border, style: BorderStyle.solid),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add_rounded, size: 24, color: AppColors.textTertiary),
            const SizedBox(height: 4),
            Text('Agregar', style: AppTypography.caption),
          ],
        ),
      ),
    );
  }
}

// ─── Source picker helper ─────────────────────────────────────────────────────

Future<List<XFile>> pickAttachments(BuildContext context) async {
  final picker = ImagePicker();

  final source = await showModalBottomSheet<_PickSource>(
    context: context,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text('Adjuntar evidencia', style: AppTypography.textTheme.headlineSmall),
            const SizedBox(height: 16),
            _SourceTile(
              icon: Iconsax.camera,
              label: 'Tomar fotografía',
              subtitle: 'Usar cámara del dispositivo',
              color: AppColors.primary,
              value: _PickSource.camera,
            ),
            const SizedBox(height: 10),
            _SourceTile(
              icon: Iconsax.gallery,
              label: 'Desde galería',
              subtitle: 'Seleccionar imágenes existentes',
              color: AppColors.purple,
              value: _PickSource.gallery,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    ),
  );

  if (source == null) return [];

  try {
    if (source == _PickSource.camera) {
      final file = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1920,
      );
      return file != null ? [file] : [];
    } else {
      final files = await picker.pickMultiImage(
        imageQuality: 85,
        maxWidth: 1920,
      );
      return files;
    }
  } catch (e) {
    return [];
  }
}

enum _PickSource { camera, gallery }

class _SourceTile extends StatelessWidget {
  const _SourceTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final _PickSource value;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.of(context).pop(value),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: color),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppTypography.textTheme.titleMedium),
                  Text(subtitle, style: AppTypography.caption),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

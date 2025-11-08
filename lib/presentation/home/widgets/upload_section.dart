import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_theme.dart';

class UploadSection extends StatelessWidget {
  final String? imagePath;
  final File? imageFile;
  final Function(File) onImageSelected;
  final VoidCallback onReset;

  const UploadSection({
    super.key,
    this.imagePath,
    this.imageFile,
    required this.onImageSelected,
    required this.onReset,
  });

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      onImageSelected(File(pickedFile.path));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Your Photo',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            if (imageFile != null)
              Row(
                children: [
                  // Replace Button
                  InkWell(
                    onTap: _pickImage,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.refresh,
                            size: 16,
                            color: AppTheme.gray600,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Replace',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppTheme.gray600,
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 4),
                  
                  // Clear Button
                  InkWell(
                    onTap: onReset,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.close,
                            size: 16,
                            color: AppTheme.gray600,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Clear',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppTheme.gray600,
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),

        const SizedBox(height: 16),

        // Image Container
        AspectRatio(
          aspectRatio: 4 / 3,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.gray50, AppTheme.gray100],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppTheme.gray200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: imageFile != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Image.file(
                      imageFile!,
                      fit: BoxFit.cover,
                    ),
                  )
                : Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _pickImage,
                      borderRadius: BorderRadius.circular(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppTheme.gray300,
                                width: 2,
                                strokeAlign: BorderSide.strokeAlignInside,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.03),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.upload_outlined,
                              size: 28,
                              color: AppTheme.gray400,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Upload or take a photo',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.gray900,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'JPG, PNG up to 10MB',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppTheme.gray500,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

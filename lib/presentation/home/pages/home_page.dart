import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/photo_provider.dart';
import '../widgets/app_header.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/upload_section.dart';
import '../widgets/generate_section.dart';
import '../widgets/results_tabs.dart';
import '../widgets/image_modal.dart';
import '../widgets/saved_images_card.dart';
import 'saved_images_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? _selectedImageUrl;

  @override
  void initState() {
    super.initState();
    // Load saved images from Firestore on app start
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<PhotoProvider>(context, listen: false);
      provider.loadSavedImages();
    });
  }

  void _showImageModal(String imageUrl) {
    setState(() => _selectedImageUrl = imageUrl);
  }

  void _closeImageModal() {
    setState(() => _selectedImageUrl = null);
  }

  void _navigateToSavedImages() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SavedImagesPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.gray50, AppTheme.gray100],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const AppHeader(),
              Expanded(
                child: Consumer<PhotoProvider>(
                  builder: (context, provider, child) {
                    return SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: MediaQuery.of(context).size.height - 
                                     MediaQuery.of(context).padding.top - 80,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24.0,
                            vertical: 8.0,
                          ),
                          child: _buildContent(provider),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      // Image Modal
      bottomSheet: _selectedImageUrl != null
          ? ImageModal(
              imageUrl: _selectedImageUrl!,
              onClose: _closeImageModal,
            )
          : null,
    );
  }

  Widget _buildContent(PhotoProvider provider) {
    if (provider.appState == AppState.empty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          
          // Saved Images Card - Always accessible
          SavedImagesCard(
            savedCount: provider.savedImages.length,
            onTap: () => _navigateToSavedImages(),
          ),
          
          // Empty State
          EmptyStateWidget(
            onImageSelected: (file) => provider.uploadImage(file),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 32),
        
        // Saved Images Card - Always accessible
        SavedImagesCard(
          savedCount: provider.savedImages.length,
          onTap: () => _navigateToSavedImages(),
        ),
        
        // Upload Section
        UploadSection(
          imagePath: provider.uploadedImagePath,
          imageFile: provider.uploadedImageFile,
          onImageSelected: (file) => provider.uploadImage(file),
          onReset: () => provider.reset(),
        ),

        const SizedBox(height: 24),

        // Generate Section
        GenerateSection(
          appState: provider.appState,
          errorMessage: provider.errorMessage,
          generationProgress: provider.generationProgress,
          hasUploadedImage: provider.hasUploadedImage,
          onGenerate: () => provider.generateImages(),
        ),

        // Results Section
        if (provider.appState == AppState.generating ||
            provider.appState == AppState.results)
          Padding(
            padding: const EdgeInsets.only(top: 32),
            child: ResultsTabs(
              generatedImages: provider.generatedImages,
              savedImages: provider.savedImages,
              isGenerating: provider.appState == AppState.generating,
              onImageTap: _showImageModal,
              onSaveImage: (image) => provider.saveImage(image),
              onUnsaveImage: (imageId) => provider.unsaveImage(imageId),
              isImageSaved: (imageId) => provider.isImageSaved(imageId),
            ),
          ),

        const SizedBox(height: 32),
      ],
    );
  }
}

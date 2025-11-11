import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/generated_image.dart';
import 'results_grid.dart';
import 'saved_grid.dart';

class ResultsTabs extends StatefulWidget {
  final List<GeneratedImage> generatedImages;
  final List<GeneratedImage> savedImages;
  final bool isGenerating;
  final Function(String) onImageTap;
  final Function(GeneratedImage) onSaveImage;
  final Function(String) onUnsaveImage;
  final bool Function(String) isImageSaved;

  const ResultsTabs({
    super.key,
    required this.generatedImages,
    required this.savedImages,
    required this.isGenerating,
    required this.onImageTap,
    required this.onSaveImage,
    required this.onUnsaveImage,
    required this.isImageSaved,
  });

  @override
  State<ResultsTabs> createState() => _ResultsTabsState();
}

class _ResultsTabsState extends State<ResultsTabs>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Custom Tab Bar
        Container(
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: AppTheme.gray200, width: 2),
            ),
          ),
          child: Row(
            children: [
              _buildTab('Generated', 0, widget.generatedImages.length),
              const SizedBox(width: 24),
              _buildTab('Saved', 1, widget.savedImages.length),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Tab Content
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.6,
          child: TabBarView(
            controller: _tabController,
            children: [
              // Generated Tab
              ResultsGrid(
                images: widget.generatedImages,
                isGenerating: widget.isGenerating,
                onImageTap: widget.onImageTap,
                onSaveImage: widget.onSaveImage,
                isImageSaved: widget.isImageSaved,
              ),

              // Saved Tab
              SavedGrid(
                images: widget.savedImages,
                onImageTap: widget.onImageTap,
                onUnsaveImage: widget.onUnsaveImage,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTab(String label, int index, int count) {
    final isSelected = _tabController.index == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _tabController.animateTo(index);
        });
      },
      child: AnimatedBuilder(
        animation: _tabController,
        builder: (context, child) {
          final isActive = _tabController.index == index;

          return Container(
            padding: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: isActive ? AppTheme.brandPrimary : Colors.transparent,
                  width: 2,
                ),
              ),
            ),
            child: Row(
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: isActive ? AppTheme.gray900 : AppTheme.gray500,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (count > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      gradient: AppTheme.brandGradient,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.brandPrimary.withValues(alpha: 0.2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Text(
                      count.toString(),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

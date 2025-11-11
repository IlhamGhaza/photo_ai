import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/photo_provider.dart';

class GenerateSection extends StatefulWidget {
  final AppState appState;
  final String errorMessage;
  final double generationProgress;
  final bool hasUploadedImage;
  final VoidCallback onGenerate;

  const GenerateSection({
    super.key,
    required this.appState,
    required this.errorMessage,
    required this.generationProgress,
    required this.hasUploadedImage,
    required this.onGenerate,
  });

  @override
  State<GenerateSection> createState() => _GenerateSectionState();
}

class _GenerateSectionState extends State<GenerateSection>
    with SingleTickerProviderStateMixin {
  late AnimationController _dotController;

  @override
  void initState() {
    super.initState();
    _dotController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _dotController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isGenerating = widget.appState == AppState.generating;
    final isDisabled = !widget.hasUploadedImage || isGenerating;
    final hasError = widget.appState == AppState.error;

    return Column(
      children: [
        // Generate Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: isDisabled ? null : widget.onGenerate,
            style:
                ElevatedButton.styleFrom(
                  backgroundColor: isDisabled
                      ? AppTheme.gray200
                      : AppTheme.brandPrimary,
                  foregroundColor: isDisabled ? AppTheme.gray400 : Colors.white,
                  disabledBackgroundColor: AppTheme.gray200,
                  disabledForegroundColor: AppTheme.gray400,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: isDisabled ? 0 : 8,
                  shadowColor: AppTheme.brandPrimary.withValues(alpha: 0.3),
                ).copyWith(
                  backgroundColor: isDisabled
                      ? MaterialStateProperty.all(AppTheme.gray200)
                      : MaterialStateProperty.resolveWith((states) {
                          return states.contains(MaterialState.pressed)
                              ? AppTheme.brandSecondary
                              : AppTheme.brandPrimary;
                        }),
                ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isGenerating)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                else
                  const Icon(Icons.auto_awesome, size: 20),
                const SizedBox(width: 12),
                Text(
                  isGenerating ? 'Generating Styles...' : 'Generate Styles',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: isDisabled ? AppTheme.gray400 : Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Loading State
        if (isGenerating) ...[
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.brandPrimary.withValues(alpha: 0.05),
                  AppTheme.brandSecondary.withValues(alpha: 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppTheme.brandPrimary.withValues(alpha: 0.1),
              ),
            ),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Animated Dots
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        children: List.generate(3, (index) {
                          return AnimatedBuilder(
                            animation: _dotController,
                            builder: (context, child) {
                              final delay = index * 0.2;
                              final value =
                                  (_dotController.value + delay) % 1.0;
                              final scale =
                                  1.0 + (0.4 * (1 - (value - 0.5).abs() * 2));
                              final opacity =
                                  0.4 + (0.6 * (1 - (value - 0.5).abs() * 2));

                              return Container(
                                margin: const EdgeInsets.only(right: 6),
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: [
                                    AppTheme.brandPrimary,
                                    AppTheme.brandSecondary,
                                    const Color(0xFFEC4899),
                                  ][index].withValues(alpha: opacity),
                                  shape: BoxShape.circle,
                                ),
                                transform: Matrix4.identity()..scale(scale),
                              );
                            },
                          );
                        }),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'AI Processing',
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Creating your stunning travel photos...',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppTheme.gray600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Progress Bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: widget.generationProgress,
                    minHeight: 6,
                    backgroundColor: Colors.white.withValues(alpha: 0.5),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppTheme.brandPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        // Error State
        if (hasError && widget.errorMessage.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              border: Border.all(color: const Color(0xFFFECACA), width: 2),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.error_outline,
                    color: Color(0xFFDC2626),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Generation Failed',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: const Color(0xFF991B1B),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.errorMessage,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: const Color(0xFFB91C1C),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap "Try Again" to start a new attempt. If the issue persists, check your internet connection',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.gray600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton.icon(
                        onPressed: widget.onGenerate,
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          foregroundColor: const Color(0xFFB91C1C),
                        ),
                        icon: const Icon(Icons.refresh, size: 16),
                        label: Text(
                          'Try Again',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

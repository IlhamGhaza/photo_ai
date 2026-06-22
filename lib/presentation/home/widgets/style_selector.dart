import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// Style option model
class StyleOption {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Color color;

  const StyleOption({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
  });
}

/// Available style options for social media photo generation
class StyleOptions {
  static const List<StyleOption> all = [
    StyleOption(
      id: 'beach',
      name: 'Beach Escape',
      description: 'Sunny beach with turquoise ocean',
      icon: Icons.beach_access,
      color: Color(0xFF06B6D4),
    ),
    StyleOption(
      id: 'mountain',
      name: 'Mountain Adventure',
      description: 'Scenic mountain landscape',
      icon: Icons.landscape,
      color: Color(0xFF10B981),
    ),
    StyleOption(
      id: 'car',
      name: 'Luxury Car',
      description: 'Standing beside a luxury car',
      icon: Icons.directions_car,
      color: Color(0xFF8B5CF6),
    ),
    StyleOption(
      id: 'city',
      name: 'City Life',
      description: 'Vibrant urban street scene',
      icon: Icons.location_city,
      color: Color(0xFFF59E0B),
    ),
    StyleOption(
      id: 'café',
      name: 'Café Moment',
      description: 'Cozy café atmosphere',
      icon: Icons.local_cafe,
      color: Color(0xFFEC4899),
    ),
    StyleOption(
      id: 'night_city',
      name: 'Night City',
      description: 'Neon lights and nightlife',
      icon: Icons.nightlight_round,
      color: Color(0xFF6366F1),
    ),
  ];
}

/// Style selector widget with beautiful cards
class StyleSelector extends StatelessWidget {
  final String? selectedStyle;
  final ValueChanged<String?> onStyleSelected;
  final bool enabled;

  const StyleSelector({
    super.key,
    required this.selectedStyle,
    required this.onStyleSelected,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Container(
              width: 4,
              height: 24,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.brandPrimary, AppTheme.brandSecondary],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Choose Your Scene',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.gray900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Text(
            'Select a lifestyle scene to transform your photo',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppTheme.gray600),
          ),
        ),
        const SizedBox(height: 20),

        // Style Grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: StyleOptions.all.length,
          itemBuilder: (context, index) {
            final style = StyleOptions.all[index];
            final isSelected = selectedStyle == style.id;

            return _StyleCard(
              style: style,
              isSelected: isSelected,
              enabled: enabled,
              onTap: () {
                if (enabled) {
                  onStyleSelected(isSelected ? null : style.id);
                }
              },
            );
          },
        ),
      ],
    );
  }
}

/// Individual style card
class _StyleCard extends StatelessWidget {
  final StyleOption style;
  final bool isSelected;
  final bool enabled;
  final VoidCallback onTap;

  const _StyleCard({
    required this.style,
    required this.isSelected,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    style.color.withOpacity(0.15),
                    style.color.withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? style.color : AppTheme.gray200,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: style.color.withOpacity(0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Stack(
          children: [
            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Icon
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: style.color.withOpacity(isSelected ? 0.2 : 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(style.icon, color: style.color, size: 20),
                  ),

                  // Text
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        style.name,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isSelected ? style.color : AppTheme.gray900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        style.description,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.gray600,
                          fontSize: 11,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Selected indicator
            if (isSelected)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: style.color,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 16),
                ),
              ),

            // Disabled overlay
            if (!enabled)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

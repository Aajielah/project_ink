import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../../models/project.dart';

class CoverPreset {
  final String id;
  final String genre;
  final List<Color> colors;
  final IconData icon;
  final String style; // 'classic', 'modern', 'minimal', 'bold'
  final Color textColor;
  final double iconSize;

  const CoverPreset({
    required this.id,
    required this.genre,
    required this.colors,
    required this.icon,
    required this.style,
    this.textColor = Colors.white,
    this.iconSize = 36.0,
  });
}

// Global list of 40 professionally designed procedural covers
final List<CoverPreset> defaultCovers = [
  // --- FANTASY (Deep gradients, magic/gothic themes) ---
  const CoverPreset(id: 'fantasy_01', genre: 'Fantasy', colors: [Color(0xFF2C3E50), Color(0xFF8E44AD)], icon: Icons.auto_awesome, style: 'classic'),
  const CoverPreset(id: 'fantasy_02', genre: 'Fantasy', colors: [Color(0xFF1A0A2A), Color(0xFF4A154B)], icon: Icons.fort, style: 'bold'),
  const CoverPreset(id: 'fantasy_03', genre: 'Fantasy', colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)], icon: Icons.key, style: 'classic'),
  const CoverPreset(id: 'fantasy_04', genre: 'Fantasy', colors: [Color(0xFF3A6073), Color(0xFF3A7BD5)], icon: Icons.wb_sunny_outlined, style: 'modern'),
  const CoverPreset(id: 'fantasy_05', genre: 'Fantasy', colors: [Color(0xFF833AB4), Color(0xFFFD1D1D), Color(0xFFFCB045)], icon: Icons.local_fire_department, style: 'bold'),

  // --- SCI-FI (Cyberpunk, neon, cosmic) ---
  const CoverPreset(id: 'scifi_01', genre: 'Sci-Fi', colors: [Color(0xFF0F0C20), Color(0xFF00F2FE)], icon: Icons.rocket_launch, style: 'modern'),
  const CoverPreset(id: 'scifi_02', genre: 'Sci-Fi', colors: [Color(0xFF141E30), Color(0xFF243B55)], icon: Icons.public, style: 'minimal'),
  const CoverPreset(id: 'scifi_03', genre: 'Sci-Fi', colors: [Color(0xFF000000), Color(0xFF434343)], icon: Icons.memory, style: 'modern'),
  const CoverPreset(id: 'scifi_04', genre: 'Sci-Fi', colors: [Color(0xFF020024), Color(0xFF090979), Color(0xFF00d4ff)], icon: Icons.science_outlined, style: 'bold'),
  const CoverPreset(id: 'scifi_05', genre: 'Sci-Fi', colors: [Color(0xFF0D0221), Color(0xFF261447), Color(0xFF5A189A)], icon: Icons.explore_outlined, style: 'classic'),

  // --- ROMANCE (Warm, rose, gold, cozy) ---
  const CoverPreset(id: 'romance_01', genre: 'Romance', colors: [Color(0xFFED4264), Color(0xFFFFEDBC)], icon: Icons.favorite, style: 'classic'),
  const CoverPreset(id: 'romance_02', genre: 'Romance', colors: [Color(0xFFFF5F6D), Color(0xFFFFC371)], icon: Icons.wb_twilight, style: 'modern'),
  const CoverPreset(id: 'romance_03', genre: 'Romance', colors: [Color(0xFFD3CBB8), Color(0xFF6D6054)], icon: Icons.spa, style: 'minimal'),
  const CoverPreset(id: 'romance_04', genre: 'Romance', colors: [Color(0xFFFC5C7D), Color(0xFF6A82FB)], icon: Icons.volunteer_activism, style: 'modern'),
  const CoverPreset(id: 'romance_05', genre: 'Romance', colors: [Color(0xFFE8CBC0), Color(0xFF636FA4)], icon: Icons.brush_outlined, style: 'minimal'),

  // --- HORROR (Dark crimson, eerie, gothic) ---
  const CoverPreset(id: 'horror_01', genre: 'Horror', colors: [Color(0xFF140101), Color(0xFF4A0000)], icon: Icons.brightness_3, style: 'bold', textColor: Color(0xFFE50914)),
  const CoverPreset(id: 'horror_02', genre: 'Horror', colors: [Color(0xFF000000), Color(0xFF1C1C1C)], icon: Icons.warning_amber, style: 'minimal', textColor: Color(0xFF900C3F)),
  const CoverPreset(id: 'horror_03', genre: 'Horror', colors: [Color(0xFF0B0C10), Color(0xFF1F2833), Color(0xFFC5C6C7)], icon: Icons.sentiment_very_dissatisfied, style: 'classic'),
  const CoverPreset(id: 'horror_04', genre: 'Horror', colors: [Color(0xFF000000), Color(0xFF310404)], icon: Icons.visibility_outlined, style: 'bold'),
  const CoverPreset(id: 'horror_05', genre: 'Horror', colors: [Color(0xFF1E130C), Color(0xFF9A8478)], icon: Icons.gavel, style: 'minimal'),

  // --- MYSTERY (Dusk, shadows, secrets) ---
  const CoverPreset(id: 'mystery_01', genre: 'Mystery', colors: [Color(0xFF3D7EAA), Color(0xFFFFE47A)], icon: Icons.search, style: 'classic'),
  const CoverPreset(id: 'mystery_02', genre: 'Mystery', colors: [Color(0xFF000428), Color(0xFF004e92)], icon: Icons.fingerprint, style: 'modern'),
  const CoverPreset(id: 'mystery_03', genre: 'Mystery', colors: [Color(0xFF4B79A1), Color(0xFF283E51)], icon: Icons.lock_outline, style: 'minimal'),
  const CoverPreset(id: 'mystery_04', genre: 'Mystery', colors: [Color(0xFF232526), Color(0xFF414345)], icon: Icons.help_outline, style: 'classic'),
  const CoverPreset(id: 'mystery_05', genre: 'Mystery', colors: [Color(0xFF1F4068), Color(0xFF162447), Color(0xFF1B1B2F)], icon: Icons.explore, style: 'modern'),

  // --- ACTION (Fiery, dynamic, steel) ---
  const CoverPreset(id: 'action_01', genre: 'Action', colors: [Color(0xFFF12711), Color(0xFFF5AF19)], icon: Icons.flash_on, style: 'bold'),
  const CoverPreset(id: 'action_02', genre: 'Action', colors: [Color(0xFF111111), Color(0xFFD62246)], icon: Icons.shield, style: 'bold'),
  const CoverPreset(id: 'action_03', genre: 'Action', colors: [Color(0xFF1D2B64), Color(0xFFF8CDDA)], icon: Icons.adjust, style: 'modern'),
  const CoverPreset(id: 'action_04', genre: 'Action', colors: [Color(0xFF42275a), Color(0xFF734b6d)], icon: Icons.sports_martial_arts, style: 'classic'),
  const CoverPreset(id: 'action_05', genre: 'Action', colors: [Color(0xFF29323c), Color(0xFF485563)], icon: Icons.track_changes, style: 'minimal'),

  // --- MINIMALIST (Clean pastel, elegant typography) ---
  const CoverPreset(id: 'minimalist_01', genre: 'Minimalist', colors: [Color(0xFFECE9E6), Color(0xFFFFFFFF)], icon: Icons.lens_blur_outlined, style: 'minimal', textColor: Color(0xFF2C3E50)),
  const CoverPreset(id: 'minimalist_02', genre: 'Minimalist', colors: [Color(0xFFE6DADA), Color(0xFF274046)], icon: Icons.trip_origin, style: 'minimal'),
  const CoverPreset(id: 'minimalist_03', genre: 'Minimalist', colors: [Color(0xFFF3F3F3), Color(0xFFE5E5E5)], icon: Icons.remove, style: 'minimal', textColor: Colors.black87),
  const CoverPreset(id: 'minimalist_04', genre: 'Minimalist', colors: [Color(0xFFD4D3DD), Color(0xFFEFEFBB)], icon: Icons.square_foot_outlined, style: 'minimal', textColor: Colors.brown),
  const CoverPreset(id: 'minimalist_05', genre: 'Minimalist', colors: [Color(0xFF757F9A), Color(0xFFD7DDE8)], icon: Icons.space_bar, style: 'minimal', textColor: Colors.black),

  // --- ABSTRACT (Artistic shapes, gradients) ---
  const CoverPreset(id: 'abstract_01', genre: 'Abstract', colors: [Color(0xFFFF007F), Color(0xFF7F00FF)], icon: Icons.grain, style: 'modern'),
  const CoverPreset(id: 'abstract_02', genre: 'Abstract', colors: [Color(0xFF00FF87), Color(0xFF60EFFF)], icon: Icons.bubble_chart_outlined, style: 'bold'),
  const CoverPreset(id: 'abstract_03', genre: 'Abstract', colors: [Color(0xFF4facfe), Color(0xFF00f2fe)], icon: Icons.all_inclusive, style: 'modern'),
  const CoverPreset(id: 'abstract_04', genre: 'Abstract', colors: [Color(0xFFFFB300), Color(0xFFF77737), Color(0xFF812BB2)], icon: Icons.category_outlined, style: 'bold'),
  const CoverPreset(id: 'abstract_05', genre: 'Abstract', colors: [Color(0xFF11998e), Color(0xFF38ef7d)], icon: Icons.texture, style: 'modern'),
];

class BookCoverWidget extends StatelessWidget {
  final String title;
  final String? coverImagePath;
  final String? coverType;
  final double width;
  final double height;
  final double borderRadius;
  final bool showTitle;

  const BookCoverWidget({
    super.key,
    required this.title,
    this.coverImagePath,
    this.coverType,
    this.width = 120,
    this.height = 160,
    this.borderRadius = 8.0,
    this.showTitle = true,
  });

  CoverPreset _getPreset() {
    // If the style matches one of our 40 presets
    if (coverType == 'default' && coverImagePath != null) {
      final preset = defaultCovers.firstWhere((c) => c.id == coverImagePath, orElse: () => defaultCovers.first);
      return preset;
    }
    
    // Deterministic fallback based on title hash
    final index = title.hashCode.abs() % defaultCovers.length;
    return defaultCovers[index];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUploaded = coverType == 'uploaded' && coverImagePath != null;

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceVariant,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 6,
              offset: const Offset(0, 3),
            )
          ]
        ),
        child: isUploaded ? _buildUploadedCover(context) : _buildProceduralCover(context),
      ),
    );
  }

  Widget _buildUploadedCover(BuildContext context) {
    final file = File(coverImagePath!);
    if (file.existsSync()) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.file(
            file,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _buildPlaceholderFallback(),
          ),
          if (showTitle) _buildTitleOverlay(),
        ],
      );
    }
    return _buildPlaceholderFallback();
  }

  Widget _buildPlaceholderFallback() {
    // Fallback to a procedural cover if file doesn't exist
    return _buildProceduralCover(null);
  }

  Widget _buildTitleOverlay() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [Colors.black.withOpacity(0.85), Colors.transparent],
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
        child: Text(
          title,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10.0,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }

  Widget _buildProceduralCover(BuildContext? context) {
    final preset = _getPreset();
    
    return Stack(
      fit: StackFit.expand,
      children: [
        // Background Gradient
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: preset.colors,
            ),
          ),
        ),
        
        // Background Pattern Overlay
        CustomPaint(
          painter: _CoverPatternPainter(style: preset.style, seed: title.hashCode),
        ),

        // Design Layout elements based on style
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Top border / Category tag
              Align(
                alignment: Alignment.topCenter,
                child: Container(
                  margin: const EdgeInsets.only(top: 4.0),
                  padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                  child: Text(
                    preset.genre.toUpperCase(),
                    style: TextStyle(
                      color: preset.textColor.withOpacity(0.8),
                      fontSize: 8,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ),

              // Center Icon / Focal point
              Icon(
                preset.icon,
                color: preset.textColor.withOpacity(0.85),
                size: width * 0.3,
              ),

              // Bottom Title / Author placeholder
              if (showTitle)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: preset.textColor,
                      fontSize: max(9.0, width * 0.08),
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                    ),
                  ),
                )
              else
                const SizedBox(),
            ],
          ),
        ),
      ],
    );
  }
}

// Background pattern painter to give each cover style texture
class _CoverPatternPainter extends CustomPainter {
  final String style;
  final int seed;

  _CoverPatternPainter({required this.style, required this.seed});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final random = Random(seed);

    if (style == 'classic') {
      // Draw concentric rectangles / frames
      canvas.drawRect(
        Rect.fromLTRB(8, 8, size.width - 8, size.height - 8),
        paint..strokeWidth = 1.5,
      );
      canvas.drawRect(
        Rect.fromLTRB(12, 12, size.width - 12, size.height - 12),
        paint..strokeWidth = 0.5,
      );
    } else if (style == 'modern') {
      // Draw intersecting diagonal lines
      for (int i = 0; i < 6; i++) {
        final startX = random.nextDouble() * size.width;
        final startY = random.nextDouble() * size.height;
        final endX = random.nextDouble() * size.width;
        final endY = random.nextDouble() * size.height;
        canvas.drawLine(Offset(startX, startY), Offset(endX, endY), paint);
      }
    } else if (style == 'bold') {
      // Draw intersecting circles/bubbles
      paint.style = PaintingStyle.fill;
      paint.color = Colors.black.withOpacity(0.04);
      for (int i = 0; i < 4; i++) {
        final cx = random.nextDouble() * size.width;
        final cy = random.nextDouble() * size.height;
        final r = 20.0 + random.nextDouble() * 30.0;
        canvas.drawCircle(Offset(cx, cy), r, paint);
      }
    } else if (style == 'minimal') {
      // Draw a subtle border frame
      paint.strokeWidth = 1.0;
      canvas.drawRect(
        Rect.fromLTRB(6, 6, size.width - 6, size.height - 6),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CoverPatternPainter oldDelegate) => false;
}

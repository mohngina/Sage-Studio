import 'package:flutter/material.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/theme/typography.dart';
import '../../core/responsive/breakpoints.dart';
import '../../core/responsive/responsive_layout.dart';
import '../../core/widgets/signature_watermark.dart';
import '../../core/widgets/thin_rule.dart';
import '../../core/widgets/sage_button.dart';
import '../../data/content_data.dart';

class FounderPage extends StatefulWidget {
  final Function(String) onNavigate;
  const FounderPage({super.key, required this.onNavigate});

  @override
  State<FounderPage> createState() => _FounderPageState();
}

class _FounderPageState extends State<FounderPage> {
  int _activeTab = 0;

  @override
  Widget build(BuildContext context) {
    final isMobile = Breakpoints.isMobile(context);

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? DesignTokens.mobilePadding : DesignTokens.desktopPadding,
          vertical: isMobile ? DesignTokens.xl : DesignTokens.xxl,
        ),
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: DesignTokens.maxContentWidth),
            child: Stack(
              children: [
                const Positioned(
                  right: 0,
                  bottom: 40,
                  child: SignatureWatermark(fontSize: 140),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Founder's Page", style: AppTypography.heroTitle().copyWith(fontSize: isMobile ? 40 : 64)),
                    const SizedBox(height: DesignTokens.sm),
                    Text("MEET THE CREATIVE DIRECTOR & CERAMIC ARTISAN", style: AppTypography.labelUppercase()),
                    const SizedBox(height: DesignTokens.xl),
                    const ThinRule(),
                    const SizedBox(height: DesignTokens.xxxl),
                    ResponsiveLayout(
                      mobile: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _FounderPortraitFrame(),
                          const SizedBox(height: DesignTokens.xxl),
                          _FounderContentColumn(
                            activeTab: _activeTab,
                            onTabChange: (index) => setState(() => _activeTab = index),
                            onNavigate: widget.onNavigate,
                          ),
                        ],
                      ),
                      desktop: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Expanded(
                            flex: 5,
                            child: _FounderPortraitFrame(),
                          ),
                          const SizedBox(width: DesignTokens.xxxl),
                          Expanded(
                            flex: 6,
                            child: _FounderContentColumn(
                              activeTab: _activeTab,
                              onTabChange: (index) => setState(() => _activeTab = index),
                              onNavigate: widget.onNavigate,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FounderPortraitFrame extends StatelessWidget {
  const _FounderPortraitFrame();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 580,
      decoration: BoxDecoration(
        color: DesignTokens.softBackground,
        border: Border.all(color: DesignTokens.borderLight),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ContentData.founderImage.startsWith('http')
              ? Image.network(
                  ContentData.founderImage,
                  fit: BoxFit.cover,
                )
              : Image.asset(
                  ContentData.founderImage,
                  fit: BoxFit.cover,
                ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.65),
                ],
              ),
            ),
          ),
          Positioned(
            left: DesignTokens.xl,
            bottom: DesignTokens.xxl,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ContentData.founderTitle,
                  style: AppTypography.heroTitle(color: Colors.white).copyWith(fontSize: 44),
                ),
                const SizedBox(height: 4),
                Text(
                  ContentData.founderSubtitle,
                  style: AppTypography.labelUppercase(color: Colors.white.withValues(alpha: 0.85)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FounderContentColumn extends StatelessWidget {
  final int activeTab;
  final Function(int) onTabChange;
  final Function(String) onNavigate;

  const _FounderContentColumn({
    required this.activeTab,
    required this.onTabChange,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: () => onTabChange(0),
              child: Column(
                children: [
                  Text('ESSAY & PHILOSOPHY',
                      style: AppTypography.labelUppercase(
                          color: activeTab == 0 ? DesignTokens.burntOrange : DesignTokens.textMuted)),
                  const SizedBox(height: 4),
                  Container(
                    height: 2,
                    width: 120,
                    color: activeTab == 0 ? DesignTokens.burntOrange : Colors.transparent,
                  ),
                ],
              ),
            ),
            const SizedBox(width: DesignTokens.xl),
            GestureDetector(
              onTap: () => onTabChange(1),
              child: Column(
                children: [
                  Text('STUDIO PROCESS FILM',
                      style: AppTypography.labelUppercase(
                          color: activeTab == 1 ? DesignTokens.burntOrange : DesignTokens.textMuted)),
                  const SizedBox(height: 4),
                  Container(
                    height: 2,
                    width: 120,
                    color: activeTab == 1 ? DesignTokens.burntOrange : Colors.transparent,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: DesignTokens.xxl),
        if (activeTab == 0) ...[
          Text(
            ContentData.founderEssay,
            style: AppTypography.bodyLarge(color: DesignTokens.textPrimary),
          ),
          const SizedBox(height: DesignTokens.xxl),
          SageButton(
            text: 'INITIATE A COMMISSION WITH BOSIBORI',
            style: SageButtonStyle.burntOrange,
            onTap: () => onNavigate('/contact'),
          ),
        ] else ...[
          Container(
            height: 320,
            color: Colors.black,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Image.network(
                  'https://images.unsplash.com/photo-1565193566173-7a0ee3dbe261?auto=format&fit=crop&w=1000&q=80',
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),
                Container(color: Colors.black.withValues(alpha: 0.4)),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(DesignTokens.md),
                      decoration: const BoxDecoration(
                        color: DesignTokens.burntOrange,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.play_arrow, color: Colors.white, size: 32),
                    ),
                    const SizedBox(height: DesignTokens.md),
                    Text('WATCH "TACTILE STILLNESS" (3:45)', style: AppTypography.labelUppercase(color: Colors.white)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

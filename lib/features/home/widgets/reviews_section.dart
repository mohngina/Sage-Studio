import 'package:flutter/material.dart';
import '../../../core/responsive/breakpoints.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/catalogue_lookup.dart';
import '../../../core/services/portal_repositories.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/sage_button.dart';
import '../../../core/widgets/thin_rule.dart';
import '../../../data/content_data.dart';
import '../../../models/portal_models.dart';
import '../../../models/testimonial_model.dart';

/// Homepage reviews section.
///
/// Loads approved customer reviews from Supabase (`moderation_status = 'approved'`).
/// When approved database reviews exist, displays them; otherwise falls back to
/// the existing curated testimonials in `ContentData.testimonials`.
class ReviewsSection extends StatefulWidget {
  final Function(String)? onNavigate;
  const ReviewsSection({super.key, this.onNavigate});

  @override
  State<ReviewsSection> createState() => _ReviewsSectionState();
}

class _ReviewsSectionState extends State<ReviewsSection> {
  final _repo = ReviewsRepository();
  List<ProductReview> _approved = const [];
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _fetchApproved();
  }

  Future<void> _fetchApproved() async {
    if (!AuthService.instance.isClientReady) {
      if (mounted) setState(() => _loaded = true);
      return;
    }
    try {
      final list = await _repo.latestApproved(limit: 3);
      if (!mounted) return;
      setState(() {
        _approved = list;
        _loaded = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loaded = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Breakpoints.isMobile(context);
    final List<Testimonial> displayItems = _approved.isNotEmpty
        ? _approved.map((r) {
            final product = CatalogueLookup.byId(r.productId);
            return Testimonial(
              id: r.id,
              name: r.reviewerName,
              role: product != null ? '${product.title} (${product.subtitle})' : 'Verified Sage Studio Client',
              rating: r.rating.toDouble(),
              quote: r.body,
              date: formatDate(r.createdAt),
            );
          }).toList()
        : ContentData.testimonials;

    final avgRating =
        displayItems.isEmpty ? 5.0 : displayItems.fold<double>(0.0, (s, t) => s + t.rating) / displayItems.length;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? DesignTokens.mobilePadding : DesignTokens.desktopPadding,
        vertical: isMobile ? DesignTokens.xxl : DesignTokens.xxxl,
      ),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: DesignTokens.maxContentWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: DesignTokens.lg,
                runSpacing: DesignTokens.xs,
                children: [
                  Text(
                    'REVIEWS',
                    style: AppTypography.sectionTitle().copyWith(fontSize: 36),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ...List.generate(
                        5,
                        (index) => Icon(
                          index < avgRating.round() ? Icons.star : Icons.star_border,
                          color: DesignTokens.oliveAccent,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: DesignTokens.sm),
                      Text(
                        avgRating.toStringAsFixed(1),
                        style: AppTypography.subTitle().copyWith(fontSize: 24),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: DesignTokens.sm),
              Text(
                _approved.isNotEmpty
                    ? 'Approved client reviews from commissioned Sage Studio pieces'
                    : (_loaded
                        ? 'Approved client reflections on our handcrafted Nairobi pieces'
                        : 'Loading approved client reviews…'),
                style: AppTypography.bodySmall(),
              ),
              const SizedBox(height: DesignTokens.xl),
              const ThinRule(),
              const SizedBox(height: DesignTokens.xxl),
              if (!isMobile)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: displayItems.map((t) {
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: DesignTokens.lg),
                        child: _TestimonialCard(testimonial: t),
                      ),
                    );
                  }).toList(),
                )
              else
                Column(
                  children: displayItems.map((t) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: DesignTokens.lg),
                      child: _TestimonialCard(testimonial: t),
                    );
                  }).toList(),
                ),
              const SizedBox(height: DesignTokens.xl),
              SageButton(
                text: 'EXPLORE CATALOGUE & REVIEWS',
                style: SageButtonStyle.primary,
                onTap: () => widget.onNavigate?.call('/shop'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TestimonialCard extends StatelessWidget {
  final Testimonial testimonial;
  const _TestimonialCard({required this.testimonial});

  @override
  Widget build(BuildContext context) {
    final stars = testimonial.rating.round().clamp(1, 5);
    return Container(
      padding: const EdgeInsets.all(DesignTokens.xl),
      decoration: BoxDecoration(
        color: DesignTokens.primaryBackground,
        border: Border.all(color: DesignTokens.borderLight, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: DesignTokens.sm,
            runSpacing: 4,
            children: [
              Text(testimonial.name, style: AppTypography.cardTitle()),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                  5,
                  (index) => Icon(
                    index < stars ? Icons.star : Icons.star_border,
                    color: DesignTokens.burntOrange,
                    size: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(testimonial.role, style: AppTypography.bodySmall()),
          const SizedBox(height: DesignTokens.md),
          Text('"${testimonial.quote}"', style: AppTypography.bodyMedium(color: DesignTokens.textPrimary)),
          const SizedBox(height: DesignTokens.md),
          Align(
            alignment: Alignment.centerRight,
            child: Text(testimonial.date, style: AppTypography.bodySmall()),
          ),
        ],
      ),
    );
  }
}

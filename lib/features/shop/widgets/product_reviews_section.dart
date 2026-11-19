import 'package:flutter/material.dart';

import '../../../core/services/auth_service.dart';
import '../../../core/services/backend_errors.dart';
import '../../../core/services/portal_repositories.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/typography.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/sage_button.dart';
import '../../../core/widgets/sage_text_field.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/widgets/thin_rule.dart';
import '../../../models/portal_models.dart';
import '../../../models/product_model.dart';

/// Displays approved customer reviews for a product and lets a signed-in
/// customer submit or update their 1–5 star rating and written review.
///
/// Newly submitted or edited reviews start with `pending` moderation status and
/// are visible publicly only after approval.
class ProductReviewsSection extends StatefulWidget {
  final Product product;
  final Function(String) onNavigate;

  const ProductReviewsSection({
    super.key,
    required this.product,
    required this.onNavigate,
  });

  @override
  State<ProductReviewsSection> createState() => _ProductReviewsSectionState();
}

class _ProductReviewsSectionState extends State<ProductReviewsSection> {
  final _repo = ReviewsRepository();
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();

  List<ProductReview> _approved = const [];
  ReviewStats _stats = ReviewStats.empty;
  ProductReview? _myReview;
  bool _loading = true;
  bool _submitting = false;
  bool _showForm = false;
  int _rating = 0;
  int _hoverRating = 0;
  int _headerHoverRating = 0;
  String? _loadError;
  String? _formError;
  String? _formSuccess;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant ProductReviewsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.product.id != widget.product.id) {
      _showForm = false;
      _formError = null;
      _formSuccess = null;
      _load();
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (!AuthService.instance.isClientReady) {
      setState(() {
        _loading = false;
        _approved = const [];
        _stats = ReviewStats.empty;
        _myReview = null;
      });
      return;
    }
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final productId = widget.product.id;
      final approvedFuture = _repo.approvedForProduct(productId);
      final statsFuture = _repo.statsForProduct(productId);
      final myFuture =
          AuthService.instance.isSignedIn ? _repo.mineForProduct(productId) : Future<ProductReview?>.value(null);

      final approved = await approvedFuture;
      final stats = await statsFuture;
      final mine = await myFuture;

      if (!mounted) return;
      setState(() {
        _approved = approved;
        _stats = stats;
        _myReview = mine;
        _loading = false;
        _prefillForm(mine);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = BackendErrors.message(e, fallback: 'Could not load reviews.');
      });
    }
  }

  void _prefillForm(ProductReview? review, {int? initialRating}) {
    if (review != null) {
      _rating = initialRating ?? review.rating;
      _nameCtrl.text = review.reviewerName;
      _titleCtrl.text = review.title ?? '';
      _bodyCtrl.text = review.body;
    } else {
      // Start with 0 stars (all 5 stars blank) until the customer clicks one.
      _rating = initialRating ?? 0;
      final defaultName = AuthService.instance.displayName;
      _nameCtrl.text = defaultName == 'Account' ? '' : defaultName;
      _titleCtrl.clear();
      _bodyCtrl.clear();
    }
    _hoverRating = 0;
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final fieldsValid = _formKey.currentState?.validate() ?? false;
    if (_rating < 1 || _rating > 5) {
      setState(() => _formError = 'Please click on the stars above to select a rating (1 to 5 stars).');
      return;
    }
    if (!fieldsValid) return;
    setState(() {
      _submitting = true;
      _formError = null;
      _formSuccess = null;
    });
    try {
      final saved = await _repo.submit(
        productId: widget.product.id,
        rating: _rating,
        title: _titleCtrl.text,
        body: _bodyCtrl.text,
        reviewerName: _nameCtrl.text,
        existingId: _myReview?.id,
      );
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _myReview = saved;
        _showForm = false;
        _formSuccess =
            'Thank you! Your review has been submitted and is awaiting studio moderation before appearing publicly.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _formError = BackendErrors.message(e, fallback: 'Could not submit your review.');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthService.instance;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: DesignTokens.xxl),
        const ThinRule(),
        const SizedBox(height: DesignTokens.xl),
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: DesignTokens.lg,
          runSpacing: DesignTokens.md,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CUSTOMER REVIEWS',
                  style: AppTypography.labelUppercase(color: DesignTokens.oliveAccent),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _stats.count > 0 ? '${_stats.average.toStringAsFixed(1)} / 5.0' : 'Reviews',
                      style: AppTypography.subTitle(),
                    ),
                    const SizedBox(width: DesignTokens.md),
                    _InteractiveStarBar(
                      rating: _showForm
                          ? _rating
                          : (_stats.count > 0 ? _stats.average.round() : 0),
                      hoverRating: _headerHoverRating,
                      size: 20,
                      onHoverChanged: (v) => setState(() => _headerHoverRating = v),
                      onSelect: (star) {
                        if (auth.isSignedIn && auth.isConfigured) {
                          setState(() {
                            if (!_showForm) {
                              _prefillForm(_myReview, initialRating: star);
                              _showForm = true;
                            } else {
                              _rating = star;
                            }
                            _formError = null;
                          });
                        } else if (auth.isConfigured) {
                          final ret = Uri.encodeComponent('/shop?product=${widget.product.id}');
                          widget.onNavigate('/sign-in?return=$ret');
                        }
                      },
                    ),
                    const SizedBox(width: DesignTokens.sm),
                    Text(
                      _stats.count > 0
                          ? '(${_stats.count} approved ${_stats.count == 1 ? 'review' : 'reviews'})'
                          : '(Click a star to rate)',
                      style: AppTypography.bodySmall(),
                    ),
                  ],
                ),
              ],
            ),
            if (auth.isSignedIn && auth.isConfigured)
              SageButton(
                text: _myReview == null
                    ? (_showForm ? 'CANCEL' : 'WRITE A REVIEW')
                    : (_showForm ? 'CANCEL EDIT' : 'EDIT YOUR REVIEW'),
                style: SageButtonStyle.primary,
                onTap: () => setState(() {
                  _prefillForm(_myReview);
                  _showForm = !_showForm;
                  _formError = null;
                }),
              )
            else if (auth.isConfigured)
              SageButton(
                text: 'SIGN IN TO REVIEW',
                style: SageButtonStyle.primary,
                onTap: () {
                  final ret = Uri.encodeComponent('/shop?product=${widget.product.id}');
                  widget.onNavigate('/sign-in?return=$ret');
                },
              ),
          ],
        ),
        const SizedBox(height: DesignTokens.lg),
        if (_formSuccess != null) ...[
          SageNotice(
            type: SageNoticeType.success,
            message: _formSuccess!,
            onDismiss: () => setState(() => _formSuccess = null),
          ),
          const SizedBox(height: DesignTokens.lg),
        ],
        if (_myReview != null && !_showForm) ...[
          _MyReviewBanner(
            review: _myReview!,
            onEdit: () => setState(() {
              _prefillForm(_myReview);
              _showForm = true;
            }),
          ),
          const SizedBox(height: DesignTokens.lg),
        ],
        if (_showForm) ...[
          _buildForm(),
          const SizedBox(height: DesignTokens.xl),
        ],
        if (_loading)
          const SageLoadingView(label: 'Loading reviews')
        else if (_loadError != null)
          SageErrorView(message: _loadError!, onRetry: _load)
        else if (_approved.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(DesignTokens.xl),
            decoration: BoxDecoration(
              color: const Color(0xFFF9F8F6),
              border: Border.all(color: DesignTokens.borderLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('No published reviews for this piece yet', style: AppTypography.cardTitle()),
                const SizedBox(height: DesignTokens.xs),
                Text(
                  'Have you commissioned or received ${widget.product.title}? Share your experience with future clients.',
                  style: AppTypography.bodyMedium(),
                ),
              ],
            ),
          )
        else
          Column(
            children: _approved
                .map((r) => Padding(
                      padding: const EdgeInsets.only(bottom: DesignTokens.md),
                      child: _ReviewCard(review: r),
                    ))
                .toList(),
          ),
      ],
    );
  }

  Widget _buildForm() {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.xl),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F8F6),
        border: Border.all(color: DesignTokens.borderLight),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _myReview == null ? 'SHARE YOUR EXPERIENCE' : 'UPDATE YOUR REVIEW',
              style: AppTypography.cardTitle(),
            ),
            const SizedBox(height: DesignTokens.xs),
            Text(
              'Reviews are moderated by Sage Studio before appearing publicly on the website.',
              style: AppTypography.bodySmall(),
            ),
            const SizedBox(height: DesignTokens.lg),
            Text('YOUR RATING *', style: AppTypography.labelUppercase()),
            const SizedBox(height: DesignTokens.xs),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: DesignTokens.md,
              runSpacing: DesignTokens.xs,
              children: [
                _InteractiveStarBar(
                  rating: _rating,
                  hoverRating: _hoverRating,
                  size: 30,
                  enabled: !_submitting,
                  onHoverChanged: (v) => setState(() => _hoverRating = v),
                  onSelect: (star) => setState(() {
                    _rating = star;
                    _formError = null;
                  }),
                ),
                Text(
                  (_hoverRating > 0 ? _hoverRating : _rating) == 0
                      ? 'Click a star to rate (1–5)'
                      : '${_hoverRating > 0 ? _hoverRating : _rating} of 5 stars selected',
                  style: AppTypography.bodySmall(
                    color: (_hoverRating > 0 || _rating > 0)
                        ? DesignTokens.burntOrange
                        : DesignTokens.textMuted,
                  ).copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: DesignTokens.md),
            SageTextField(
              label: 'YOUR DISPLAY NAME *',
              controller: _nameCtrl,
              hint: 'e.g. Amina W., Karen Nairobi',
              validator: Validators.fullName,
              enabled: !_submitting,
            ),
            const SizedBox(height: DesignTokens.lg),
            SageTextField(
              label: 'HEADLINE (OPTIONAL)',
              controller: _titleCtrl,
              hint: 'e.g. Exceptional proportion and comfort',
              validator: Validators.maxLength(120, field: 'Headline'),
              enabled: !_submitting,
            ),
            const SizedBox(height: DesignTokens.lg),
            SageTextField(
              label: 'YOUR REVIEW *',
              controller: _bodyCtrl,
              hint:
                  'Share details about craftsmanship, comfort, finish and how the piece fits your space (10–2000 characters)...',
              maxLines: 4,
              validator: (v) {
                final text = v?.trim() ?? '';
                if (text.isEmpty) return 'Please write a short review.';
                if (text.length < 10) return 'Please write at least 10 characters.';
                if (text.length > 2000) return 'Reviews must be 2000 characters or fewer.';
                return null;
              },
              enabled: !_submitting,
            ),
            if (_formError != null) ...[
              const SizedBox(height: DesignTokens.md),
              SageNotice(type: SageNoticeType.error, message: _formError!),
            ],
            const SizedBox(height: DesignTokens.lg),
            SageBusyButton(
              text: _myReview == null ? 'SUBMIT REVIEW' : 'UPDATE REVIEW',
              busyText: 'SUBMITTING…',
              busy: _submitting,
              onTap: _submit,
            ),
          ],
        ),
      ),
    );
  }
}

class _InteractiveStarBar extends StatelessWidget {
  final int rating;
  final int hoverRating;
  final double size;
  final bool enabled;
  final ValueChanged<int> onHoverChanged;
  final ValueChanged<int> onSelect;

  const _InteractiveStarBar({
    required this.rating,
    required this.hoverRating,
    required this.onHoverChanged,
    required this.onSelect,
    this.size = 24,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final activeRating = hoverRating > 0 ? hoverRating : rating;
    return MouseRegion(
      onExit: (_) {
        if (enabled) onHoverChanged(0);
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(5, (index) {
          final star = index + 1;
          final filled = star <= activeRating;
          return MouseRegion(
            cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
            onEnter: (_) {
              if (enabled) onHoverChanged(star);
            },
            child: GestureDetector(
              onTap: enabled ? () => onSelect(star) : null,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 4),
                child: Semantics(
                  button: true,
                  selected: star <= rating,
                  label: '$star ${star == 1 ? 'star' : 'stars'}',
                  child: Icon(
                    filled ? Icons.star : Icons.star_border,
                    color: filled ? DesignTokens.burntOrange : DesignTokens.oliveAccent,
                    size: size,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _StarRow extends StatelessWidget {
  final int rating;
  final double size;
  const _StarRow({required this.rating, this.size = 16});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        5,
        (i) => Icon(
          i < rating ? Icons.star : Icons.star_border,
          size: size,
          color: DesignTokens.burntOrange,
        ),
      ),
    );
  }
}

class _MyReviewBanner extends StatelessWidget {
  final ProductReview review;
  final VoidCallback onEdit;
  const _MyReviewBanner({required this.review, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final statusLabel = switch (review.status) {
      ModerationStatus.pending => 'PENDING STUDIO APPROVAL',
      ModerationStatus.approved => 'APPROVED & PUBLISHED',
      ModerationStatus.rejected => 'NOT PUBLISHED',
    };
    final statusColor = switch (review.status) {
      ModerationStatus.pending => DesignTokens.burntOrange,
      ModerationStatus.approved => DesignTokens.oliveAccent,
      ModerationStatus.rejected => DesignTokens.galleryAccent,
    };
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(DesignTokens.lg),
      decoration: BoxDecoration(
        color: DesignTokens.sageAccent.withValues(alpha: 0.18),
        border: Border.all(color: DesignTokens.oliveAccent.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: DesignTokens.md,
            runSpacing: 4,
            children: [
              Text(
                'YOUR REVIEW • $statusLabel',
                style: AppTypography.labelUppercase(color: statusColor).copyWith(fontSize: 10),
              ),
              TextButton(
                onPressed: onEdit,
                child: Text('Edit', style: AppTypography.bodySmall(color: DesignTokens.burntOrange)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          _StarRow(rating: review.rating, size: 15),
          if (review.title != null) ...[
            const SizedBox(height: 6),
            Text(review.title!,
                style: AppTypography.bodyMedium(color: DesignTokens.textPrimary).copyWith(fontWeight: FontWeight.w600)),
          ],
          const SizedBox(height: 4),
          Text(review.body, style: AppTypography.bodyMedium(color: DesignTokens.textPrimary)),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final ProductReview review;
  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(DesignTokens.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: DesignTokens.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: DesignTokens.md,
            runSpacing: 4,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(review.reviewerName, style: AppTypography.cardTitle().copyWith(fontSize: 18)),
                  ),
                  if (review.verifiedPurchase) ...[
                    const SizedBox(width: DesignTokens.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      color: DesignTokens.sageAccent.withValues(alpha: 0.35),
                      child: Text(
                        'VERIFIED CLIENT',
                        style: AppTypography.labelUppercase(color: DesignTokens.oliveAccent).copyWith(fontSize: 9),
                      ),
                    ),
                  ],
                ],
              ),
              _StarRow(rating: review.rating, size: 15),
            ],
          ),
          if (review.title != null) ...[
            const SizedBox(height: DesignTokens.sm),
            Text(
              review.title!,
              style: AppTypography.bodyLarge().copyWith(fontWeight: FontWeight.w600),
            ),
          ],
          const SizedBox(height: DesignTokens.sm),
          Text('"${review.body}"', style: AppTypography.bodyMedium(color: DesignTokens.textPrimary)),
          if (review.createdAt != null) ...[
            const SizedBox(height: DesignTokens.sm),
            Align(
              alignment: Alignment.centerRight,
              child: Text(formatDate(review.createdAt), style: AppTypography.bodySmall()),
            ),
          ],
        ],
      ),
    );
  }
}

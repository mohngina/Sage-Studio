import 'package:flutter/material.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/typography.dart';
import '../../../core/responsive/breakpoints.dart';

class NewsletterSection extends StatefulWidget {
  const NewsletterSection({super.key});

  @override
  State<NewsletterSection> createState() => _NewsletterSectionState();
}

class _NewsletterSectionState extends State<NewsletterSection> {
  final TextEditingController _emailController = TextEditingController();
  String? _feedbackMessage;
  bool _isSuccess = false;

  void _handleSubmit() {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() {
        _feedbackMessage = 'Please enter a valid email address.';
        _isSuccess = false;
      });
    } else {
      setState(() {
        _feedbackMessage = 'Thank you for subscribing to Sage Studio journal.';
        _isSuccess = true;
      });
      _emailController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Breakpoints.isMobile(context);

    return Container(
      color: DesignTokens.softBackground,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? DesignTokens.mobilePadding : DesignTokens.desktopPadding,
        vertical: isMobile ? DesignTokens.xxl : DesignTokens.xxxl,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: Column(
            children: [
              Text(
                'SUBSCRIBE OUR NEWSLETTER',
                textAlign: TextAlign.center,
                style: AppTypography.sectionTitle(),
              ),
              const SizedBox(height: DesignTokens.sm),
              Text(
                'Receive private previews of new studio collections, architectural stories, and event invitations.',
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium(),
              ),
              const SizedBox(height: DesignTokens.xxl),
              Container(
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: DesignTokens.textPrimary, width: 1.5)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.email_outlined, size: 20, color: DesignTokens.textMuted),
                    const SizedBox(width: DesignTokens.md),
                    Expanded(
                      child: TextField(
                        controller: _emailController,
                        style: AppTypography.bodyLarge(),
                        decoration: InputDecoration(
                          hintText: 'Enter your email address here',
                          hintStyle: AppTypography.bodyMedium(color: DesignTokens.textMuted),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _handleSubmit,
                      child: Text(
                        'SUBMIT',
                        style: AppTypography.labelUppercase(color: DesignTokens.burntOrange),
                      ),
                    ),
                  ],
                ),
              ),
              if (_feedbackMessage != null) ...[
                const SizedBox(height: DesignTokens.md),
                Text(
                  _feedbackMessage!,
                  style: AppTypography.bodySmall(
                    color: _isSuccess ? DesignTokens.oliveAccent : DesignTokens.burntOrange,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

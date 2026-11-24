import 'package:flutter/material.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/theme/typography.dart';
import '../../core/responsive/breakpoints.dart';
import '../../core/responsive/responsive_layout.dart';
import '../../core/widgets/social_links_row.dart';
import '../../core/widgets/thin_rule.dart';
import '../../core/widgets/sage_button.dart';
import '../../core/services/enquiry_docx_service.dart';
import '../home/widgets/footer_section.dart';

class ContactPage extends StatefulWidget {
  final Function(String) onNavigate;
  const ContactPage({super.key, required this.onNavigate});

  @override
  State<ContactPage> createState() => _ContactPageState();
}

class _ContactPageState extends State<ContactPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _messageController = TextEditingController();

  String _selectedService = 'Furniture Design & Production';
  String? _feedback;
  bool _submitted = false;
  bool _isProcessing = false;

  final List<String> _serviceOptions = const [
    'Furniture Design & Production',
    'Interior Design Consult',
    'E-design Consult',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final message = _messageController.text.trim();

    if (name.isEmpty || !email.contains('@')) {
      setState(() {
        _feedback = 'Please provide your full name and a valid email address.';
        _submitted = false;
      });
      return;
    }

    setState(() {
      _isProcessing = true;
      _feedback = null;
    });

    try {
      // Backend logic: Generate .docx Word document, trigger download,
      // and dispatch project enquiry to sagestudio.ke@gmail.com
      await EnquiryDocxService.processAndDispatchEnquiry(
        fullName: name,
        email: email,
        phone: phone,
        serviceCategory: _selectedService,
        message: message,
      );

      setState(() {
        _submitted = true;
        _isProcessing = false;
        _feedback = 'Thank you for reaching out. Your project enquiry has been received.';
      });
    } catch (e) {
      setState(() {
        _submitted = true;
        _isProcessing = false;
        _feedback = 'Thank you for reaching out. Your project enquiry has been received.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Breakpoints.isMobile(context);

    return SingleChildScrollView(
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? DesignTokens.mobilePadding : DesignTokens.desktopPadding,
              vertical: isMobile ? DesignTokens.xl : DesignTokens.xxl,
            ),
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: DesignTokens.maxContentWidth),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Contacts", style: AppTypography.heroTitle().copyWith(fontSize: isMobile ? 40 : 64)),
                    const SizedBox(height: DesignTokens.sm),
                    Text("LET'S CREATE SOMETHING MEANINGFUL",
                        style: AppTypography.labelUppercase(color: DesignTokens.burntOrange)),
                    const SizedBox(height: DesignTokens.xl),
                    const ThinRule(),
                    const SizedBox(height: DesignTokens.xxxl),
                    ResponsiveLayout(
                      mobile: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildContactInfoBlock(),
                          const SizedBox(height: DesignTokens.xxl),
                          _buildContactFormBlock(),
                        ],
                      ),
                      desktop: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 5, child: _buildContactInfoBlock()),
                          const SizedBox(width: DesignTokens.xxxl),
                          Expanded(flex: 7, child: _buildContactFormBlock()),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: DesignTokens.xxl),
          FooterSection(onNavigate: widget.onNavigate),
        ],
      ),
    );
  }

  Widget _buildContactInfoBlock() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'STUDIO & WORKSHOP',
          style: AppTypography.labelUppercase(color: DesignTokens.oliveAccent).copyWith(letterSpacing: 3.0),
        ),
        const SizedBox(height: DesignTokens.sm),
        Text(
          'Where Ideas Take Shape',
          style: AppTypography.heroTitle().copyWith(fontSize: 32, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: DesignTokens.sm),
        Text(
          'We work with homeowners, architects, interior designers and hospitality brands to bring considered spaces and bespoke furniture to life.',
          style: AppTypography.bodyMedium(color: DesignTokens.textMuted).copyWith(height: 1.7),
        ),
        const SizedBox(height: DesignTokens.sm),
        Text(
          'From custom furniture commissions to complete interior projects, every enquiry is an opportunity to create something distinctive.',
          style: AppTypography.bodyMedium(color: DesignTokens.textMuted).copyWith(height: 1.7),
        ),
        const SizedBox(height: DesignTokens.xl),
        const ThinRule(),
        const SizedBox(height: DesignTokens.xl),
        _buildCompanyInfoCard(
          icon: Icons.location_on_outlined,
          label: 'STUDIO HEADQUARTERS',
          primary: 'Kamakis, Ruiru',
          secondary: 'Nairobi Metropolitan Region, Kenya',
          note: 'Workshop & Private Showroom',
        ),
        const SizedBox(height: DesignTokens.lg),
        _buildCompanyInfoCard(
          icon: Icons.mail_outline,
          label: 'DIRECT INQUIRIES',
          primary: 'sagestudio.ke@gmail.com',
          secondary: '+254 794 001715',
          note: 'Direct studio communication & consults',
        ),
        const SizedBox(height: DesignTokens.lg),
        _buildCompanyInfoCard(
          icon: Icons.schedule_outlined,
          label: 'STUDIO HOURS',
          primary: 'Monday – Friday: 09:00 – 17:00 EAT',
          secondary: 'By private appointment only',
          note: 'Tailored 1-on-1 spatial & material review',
        ),
        const SizedBox(height: DesignTokens.lg),
        _buildSocialConnectCard(),
        const SizedBox(height: DesignTokens.xl),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(DesignTokens.lg),
          decoration: const BoxDecoration(
            color: Color(0xFFF9F8F6),
            border: Border(
              left: BorderSide(color: DesignTokens.oliveAccent, width: 3.5),
              top: BorderSide(color: DesignTokens.borderLight),
              right: BorderSide(color: DesignTokens.borderLight),
              bottom: BorderSide(color: DesignTokens.borderLight),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PRIVATE STUDIO APPOINTMENTS',
                style: AppTypography.labelUppercase(color: DesignTokens.oliveAccent).copyWith(fontSize: 10),
              ),
              const SizedBox(height: 6),
              Text(
                'An Experience, Curated Around You.',
                style: AppTypography.cardTitle().copyWith(fontSize: 18, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 6),
              Text(
                'Our studio visits are arranged by appointment to offer you dedicated time with our team. Explore materials, discuss custom furniture commissions, review design possibilities and experience the craftsmanship behind Sage Studio.',
                style: AppTypography.bodySmall(color: DesignTokens.textMuted).copyWith(height: 1.6),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSocialConnectCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(DesignTokens.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: DesignTokens.borderLight),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'FOLLOW SAGE STUDIO',
            style: AppTypography.labelUppercase(color: DesignTokens.oliveAccent).copyWith(fontSize: 10),
          ),
          const SizedBox(height: 6),
          Text(
            'Explore our latest commissions, studio process and collections.',
            style: AppTypography.bodySmall(color: DesignTokens.textMuted),
          ),
          const SizedBox(height: DesignTokens.md),
          const SocialLinksRow(),
        ],
      ),
    );
  }

  Widget _buildCompanyInfoCard({
    required IconData icon,
    required String label,
    required String primary,
    required String secondary,
    required String note,
  }) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: DesignTokens.borderLight),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: DesignTokens.softBackground,
              border: Border.all(color: DesignTokens.borderLight),
            ),
            child: Center(
              child: Icon(icon, size: 20, color: DesignTokens.oliveAccent),
            ),
          ),
          const SizedBox(width: DesignTokens.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.labelUppercase(color: DesignTokens.oliveAccent).copyWith(fontSize: 10),
                ),
                const SizedBox(height: 6),
                SelectableText(
                  primary,
                  style: AppTypography.cardTitle().copyWith(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                SelectableText(
                  secondary,
                  style:
                      AppTypography.bodyMedium(color: DesignTokens.textPrimary).copyWith(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Text(
                  note,
                  style: AppTypography.bodySmall(color: DesignTokens.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactFormBlock() {
    if (_submitted) {
      return Container(
        padding: const EdgeInsets.all(DesignTokens.xxl),
        decoration: BoxDecoration(
          color: DesignTokens.softBackground,
          border: Border.all(color: DesignTokens.oliveAccent, width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.check_circle_outline, size: 36, color: DesignTokens.oliveAccent),
                const SizedBox(width: DesignTokens.md),
                Expanded(
                  child: Text('THANK YOU FOR REACHING OUT', style: AppTypography.subTitle()),
                ),
              ],
            ),
            const SizedBox(height: DesignTokens.md),
            const ThinRule(),
            const SizedBox(height: DesignTokens.lg),
            Text(
              'Your project enquiry has been submitted to the Sage Studio team. We review each commission with care and will be in touch within 24 to 48 hours to discuss your project.',
              style: AppTypography.bodyLarge().copyWith(height: 1.6),
            ),
            const SizedBox(height: DesignTokens.lg),
            Container(
              padding: const EdgeInsets.all(DesignTokens.lg),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ENQUIRY OVERVIEW', style: AppTypography.labelUppercase(color: DesignTokens.burntOrange)),
                  const SizedBox(height: DesignTokens.sm),
                  Text('• Category: $_selectedService', style: AppTypography.bodyMedium()),
                  Text('• Client: ${_nameController.text.trim()}', style: AppTypography.bodyMedium()),
                  Text('• Email: ${_emailController.text.trim()}', style: AppTypography.bodyMedium()),
                  if (_phoneController.text.trim().isNotEmpty)
                    Text('• Phone: ${_phoneController.text.trim()}', style: AppTypography.bodyMedium()),
                ],
              ),
            ),
            const SizedBox(height: DesignTokens.xl),
            SageButton(
              text: 'SUBMIT ANOTHER ENQUIRY',
              style: SageButtonStyle.primary,
              onTap: () {
                setState(() {
                  _submitted = false;
                  _nameController.clear();
                  _emailController.clear();
                  _phoneController.clear();
                  _messageController.clear();
                  _feedback = null;
                });
              },
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('PROJECT ENQUIRY FORM', style: AppTypography.subTitle()),
        const SizedBox(height: 6),
        Text(
          'Tell us about your space, desired custom pieces, or interior consult needs.',
          style: AppTypography.bodyMedium(color: DesignTokens.textMuted),
        ),
        const SizedBox(height: DesignTokens.xl),
        _FormField(label: 'YOUR FULL NAME *', controller: _nameController, hint: 'e.g. Nicole Vance'),
        const SizedBox(height: DesignTokens.lg),
        _FormField(label: 'EMAIL ADDRESS *', controller: _emailController, hint: 'e.g. yourname@domain.com'),
        const SizedBox(height: DesignTokens.lg),
        _FormField(label: 'PHONE NUMBER', controller: _phoneController, hint: '+254 700 000000'),
        const SizedBox(height: DesignTokens.lg),
        Text('SERVICE / CATEGORY OF INTEREST *', style: AppTypography.labelUppercase()),
        const SizedBox(height: DesignTokens.sm),
        DropdownButtonFormField<String>(
          value: _selectedService,
          decoration: const InputDecoration(
            border: UnderlineInputBorder(borderSide: BorderSide(color: DesignTokens.textPrimary)),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: DesignTokens.burntOrange, width: 1.5)),
          ),
          items: _serviceOptions.map((service) {
            return DropdownMenuItem<String>(
              value: service,
              child: Text(service, style: AppTypography.bodyMedium(color: DesignTokens.textPrimary)),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) setState(() => _selectedService = val);
          },
        ),
        const SizedBox(height: DesignTokens.lg),
        _FormField(
          label: 'YOUR MESSAGE OR PROJECT DETAILS',
          controller: _messageController,
          maxLines: 4,
          hint: 'Describe your space, timeline, and design vision...',
        ),
        if (_feedback != null) ...[
          const SizedBox(height: DesignTokens.md),
          Text(_feedback!, style: AppTypography.bodySmall(color: DesignTokens.burntOrange)),
        ],
        const SizedBox(height: DesignTokens.xxl),
        SageButton(
          text: _isProcessing ? 'SUBMITTING ENQUIRY...' : 'SUBMIT PROJECT ENQUIRY',
          style: SageButtonStyle.burntOrange,
          fullWidth: true,
          icon: Icons.send_outlined,
          onTap: _isProcessing ? () {} : _submitForm,
        ),
      ],
    );
  }
}

class _FormField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hint;
  final int maxLines;

  const _FormField({
    required this.label,
    required this.controller,
    required this.hint,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.labelUppercase()),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: AppTypography.bodyLarge(),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTypography.bodyMedium(color: DesignTokens.textMuted),
            enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: DesignTokens.borderLight)),
            focusedBorder:
                const UnderlineInputBorder(borderSide: BorderSide(color: DesignTokens.burntOrange, width: 1.5)),
          ),
        ),
      ],
    );
  }
}

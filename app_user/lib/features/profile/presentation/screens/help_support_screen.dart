import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/theme/app_colors.dart';
import 'package:shared/theme/app_spacing.dart';
import 'package:shared/theme/app_typography.dart';
import 'package:shared/widgets/custom_button.dart';
import 'package:shared/widgets/custom_text_field.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  final _messageController = TextEditingController();
  final _subjectController = TextEditingController();

  final List<Map<String, String>> _faqs = [
    {
      'q': 'How do home measurement and sample fabric trials work?',
      'a': 'When viewing a participating boutique with the "Home Trial Avail" badge, tap "Call Store" or "WhatsApp" via our integrated O2O concierge bar to pick a time slot. A female style consultant from the boutique will visit your home with fabric swatches and take precise measurements.'
    },
    {
      'q': 'Are all vendors on HER AREA quality-verified and inspected?',
      'a': 'Yes! Every boutique, bridal studio, and maggam weaving house on HER AREA undergoes an exhaustive multi-point quality audit by our styling curators in Hyderabad to verify craftsmanship density, authenticity of zari silk, and staff hospitality.'
    },
    {
      'q': 'Is there any extra fee for booking consultations through HER AREA?',
      'a': 'No, HER AREA is completely free for customers. In fact, displaying your VIP digital card inside participating stores unlocks exclusive platform discounts and seasonal gifts.'
    },
    {
      'q': 'Can I request bespoke custom designs not listed on a store profile?',
      'a': 'Absolutely! Our platform specialize in bespoke creations. You can upload or share reference design photos directly over our integrated WhatsApp concierge interface when messaging any store.'
    },
  ];

  @override
  void dispose() {
    _messageController.dispose();
    _subjectController.dispose();
    super.dispose();
  }

  void _submitTicket() {
    if (_messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please describe your question or issue before submitting.')),
      );
      return;
    }
    _messageController.clear();
    _subjectController.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Your message has been dispatched to the HER AREA VIP Support team. Expect a reply within 2 hours!'),
        backgroundColor: AppColors.primaryRuby,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Concierge Support', style: TextStyle(fontFamily: AppTypography.displayFont, fontWeight: FontWeight.w700)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Concierge Hero Card
              Container(
                padding: const EdgeInsets.all(AppSpacing.xl),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: AppColors.primaryRuby.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 6)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), shape: BoxShape.circle),
                          child: const Icon(Icons.support_agent_rounded, color: AppColors.accentGoldLight, size: 32),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('VIP Personal Concierge', style: TextStyle(fontFamily: AppTypography.displayFont, fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
                              SizedBox(height: 4),
                              Text('24/7 Dedicated Styling & Booking Helpline', style: TextStyle(color: AppColors.blushPink, fontSize: 13)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    const Text(
                      'Need urgent assistance finding a custom saree designer for an upcoming wedding or managing a home measurement slot? Our live support consultants are ready on WhatsApp.',
                      style: TextStyle(color: Colors.white, height: 1.5, fontSize: 14),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Connecting to HER AREA Official WhatsApp Helpline...'), behavior: SnackBarBehavior.floating),
                        );
                      },
                      icon: const Icon(Icons.chat_bubble_rounded, size: 20),
                      label: const Text('Chat Live on WhatsApp', style: TextStyle(fontWeight: FontWeight.w800)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),

              // Frequently Asked Questions
              Text(
                'Frequently Asked Questions',
                style: theme.textTheme.titleLarge?.copyWith(fontFamily: AppTypography.displayFont, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: AppSpacing.md),
              ..._faqs.map((faq) => Card(
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                ),
                child: ExpansionTile(
                  iconColor: AppColors.primaryRuby,
                  collapsedIconColor: AppColors.primaryRuby,
                  title: Text(
                    faq['q']!,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: isDark ? AppColors.textHighDark : AppColors.textHighLight,
                    ),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Text(
                        faq['a']!,
                        style: TextStyle(
                          color: isDark ? AppColors.textMediumDark : AppColors.textMediumLight,
                          height: 1.5,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
              const SizedBox(height: AppSpacing.xxl),

              // Submit a Ticket Form
              Text(
                'Send a Direct Message',
                style: theme.textTheme.titleLarge?.copyWith(fontFamily: AppTypography.displayFont, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: AppSpacing.md),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    children: [
                      CustomTextField(
                        label: 'Subject / Topic',
                        controller: _subjectController,
                        prefixIcon: Icons.topic_outlined,
                        hintText: 'e.g. Vendor inquiry, feedback, app issue',
                      ),
                      const SizedBox(height: AppSpacing.md),
                      CustomTextField(
                        label: 'How can our styling team help you today?',
                        controller: _messageController,
                        prefixIcon: Icons.notes_rounded,
                        maxLines: 4,
                        hintText: 'Type your message here...',
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      CustomButton(
                        label: 'Dispatch Inquiry',
                        icon: Icons.send_rounded,
                        onPressed: _submitTicket,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }
}

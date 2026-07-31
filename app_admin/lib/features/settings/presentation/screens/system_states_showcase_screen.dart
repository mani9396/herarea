import 'package:flutter/material.dart';
import 'package:shared/theme/app_colors.dart';
import 'package:shared/theme/app_spacing.dart';
import 'package:shared/theme/app_typography.dart';
import 'package:shared/widgets/empty_state_widget.dart';
import 'package:shared/widgets/error_view.dart';
import 'package:shared/widgets/loading_indicator.dart';

class SystemStatesShowcaseScreen extends StatefulWidget {
  const SystemStatesShowcaseScreen({super.key});

  @override
  State<SystemStatesShowcaseScreen> createState() => _SystemStatesShowcaseScreenState();
}

class _SystemStatesShowcaseScreenState extends State<SystemStatesShowcaseScreen> {
  int _selectedStateIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('System UI States Showcase (Verification Demo)'),
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            color: Theme.of(context).cardColor,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildStateTab('Empty Queue State', 0),
                  const SizedBox(width: 12),
                  _buildStateTab('Offline / Network Error State', 1),
                  const SizedBox(width: 12),
                  _buildStateTab('403 Forbidden Access State', 2),
                  const SizedBox(width: 12),
                  _buildStateTab('Skeleton Shimmer Loader', 3),
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: _renderActiveState(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStateTab(String label, int index) {
    final isSelected = _selectedStateIndex == index;
    return ChoiceChip(
      label: Text(label, style: TextStyle(fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500)),
      selected: isSelected,
      onSelected: (_) => setState(() => _selectedStateIndex = index),
      selectedColor: AppColors.primaryRuby.withValues(alpha: 0.2),
      labelStyle: TextStyle(color: isSelected ? AppColors.primaryRuby : AppColors.neutralCharcoal),
    );
  }

  Widget _renderActiveState() {
    switch (_selectedStateIndex) {
      case 0:
        return const EmptyStateWidget(
          icon: Icons.assignment_turned_in_outlined,
          title: 'Moderation Queue Fully Processed',
          description: 'Congratulations! All partner studio product listings and KYC verification dossiers have been reviewed by executive moderators.',
        );
      case 1:
        return ErrorView(
          message: 'Unable to sync with HER AREA cloud replication nodes. Please verify your corporate hardware firewall and SSL tunnel connection.',
          onRetry: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Re-initializing cloud handshake... Connection Restored!'))),
        );
      case 2:
        return Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: const Icon(Icons.gavel_rounded, color: Colors.red, size: 64),
              ),
              const SizedBox(height: 20),
              const Text('403: Forbidden Architectural Access', style: TextStyle(fontFamily: AppTypography.displayFont, fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.neutralCharcoal)),
              const SizedBox(height: 8),
              const Text(
                'Your RBAC administrator privilege token does not permit modifications to this financial ledger repository. Please contact the Founder Superadmin for tier ascension.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey, height: 1.4),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryRuby, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14)),
                icon: const Icon(Icons.security_rounded),
                label: const Text('Request Elevating Token'),
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Privilege escalation audit ticket submitted.'))),
              ),
            ],
          ),
        );
      case 3:
      default:
        return const LoadingIndicator(
          message: 'Fetching real-time cryptographic audit ledgers and studio KYC dossiers...',
          size: 50.0,
          color: AppColors.primaryRuby,
        );
    }
  }
}

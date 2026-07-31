import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:app_vendor/core/routing/vendor_route_paths.dart';
import 'package:shared/shared.dart';

class StoreTimingScreen extends StatefulWidget {
  const StoreTimingScreen({super.key});

  @override
  State<StoreTimingScreen> createState() => _StoreTimingScreenState();
}

class _StoreTimingScreenState extends State<StoreTimingScreen> {
  final Map<String, bool> _dayOpen = {
    'Monday': true,
    'Tuesday': true,
    'Wednesday': true,
    'Thursday': true,
    'Friday': true,
    'Saturday': true,
    'Sunday': false,
  };

  final Map<String, TimeOfDay> _openTime = {};
  final Map<String, TimeOfDay> _closeTime = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    for (var d in _dayOpen.keys) {
      _openTime[d] = const TimeOfDay(hour: 10, minute: 30);
      _closeTime[d] = const TimeOfDay(hour: 20, minute: 30);
    }
  }

  Future<void> _pickTime(String day, bool isOpen) async {
    final cur = isOpen ? _openTime[day]! : _closeTime[day]!;
    final res = await showTimePicker(context: context, initialTime: cur);
    if (res != null && mounted) {
      setState(() {
        if (isOpen) {
          _openTime[day] = res;
        } else {
          _closeTime[day] = res;
        }
      });
    }
  }

  void _onSaveTimings() {
    setState(() => _isLoading = true);
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      setState(() => _isLoading = false);
      context.push(VendorRoutePaths.verificationStatus);
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Step 3: Studio Operating Hours'), centerTitle: true, elevation: 0),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Configure Weekly Working Hours 🕒', style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: AppColors.primaryRuby)),
                const SizedBox(height: AppSpacing.xs),
                Text('Set when your atelier is open for in-person bridal consultations and Maggam measurement appointments.', style: textTheme.bodyMedium?.copyWith(color: Colors.grey[600])),
                const SizedBox(height: AppSpacing.lg),
                ..._dayOpen.keys.map((day) => _buildDayTile(day)),
                const SizedBox(height: AppSpacing.xxl),
                CustomButton(
                  label: 'Confirm Operating Timings & Proceed ✨',
                  isLoading: _isLoading,
                  onPressed: _onSaveTimings,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDayTile(String day) {
    final isOpen = _dayOpen[day]!;
    final op = _openTime[day]!.format(context);
    final cl = _closeTime[day]!.format(context);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: isOpen ? Theme.of(context).cardColor : Colors.grey.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isOpen ? AppColors.primaryRuby.withValues(alpha: 0.3) : Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Switch(
            value: isOpen,
            activeThumbColor: AppColors.primaryRuby,
            onChanged: (val) => setState(() => _dayOpen[day] = val),
          ),
          const SizedBox(width: AppSpacing.sm),
          SizedBox(
            width: 100,
            child: Text(day, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: isOpen ? null : Colors.grey)),
          ),
          const Spacer(),
          if (!isOpen)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(15)),
              child: const Text('CLOSED / HOLIDAY', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
            )
          else ...[
            GestureDetector(
              onTap: () => _pickTime(day, true),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: AppColors.primaryRuby.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
                child: Text(op, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryRuby)),
              ),
            ),
            const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('to', style: TextStyle(color: Colors.grey))),
            GestureDetector(
              onTap: () => _pickTime(day, false),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: AppColors.primaryRuby.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
                child: Text(cl, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryRuby)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

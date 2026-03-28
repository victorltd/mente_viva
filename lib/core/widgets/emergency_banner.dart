// lib/core/widgets/emergency_banner.dart

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_sizes.dart';
import '../../config/constants/legal_constants.dart';

class EmergencyBanner extends StatelessWidget {
  final bool isCompact;
  final VoidCallback? onDismiss;

  const EmergencyBanner({
    super.key,
    this.isCompact = false,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    if (isCompact) {
      return _buildCompact(context);
    }
    return _buildFull(context);
  }

  Widget _buildCompact(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.md,
        vertical: AppSizes.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.error,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.emergency,
            color: Colors.white,
            size: 18,
          ),
          const SizedBox(width: AppSizes.sm),
          Expanded(
            child: Text(
              LegalConstants.emergencyShort,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          GestureDetector(
            onTap: _callCVV,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.sm,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppSizes.radiusFull),
              ),
              child: const Text(
                'Ligar',
                style: TextStyle(
                  color: AppColors.error,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFull(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(AppSizes.md),
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: AppColors.errorLight,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: AppColors.error.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSizes.sm),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                ),
                child: const Icon(
                  Icons.emergency,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppSizes.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Precisa de ajuda?',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppColors.error,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      'O CVV está disponível 24 horas',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.error.withOpacity(0.8),
                          ),
                    ),
                  ],
                ),
              ),
              if (onDismiss != null)
                IconButton(
                  icon: Icon(
                    Icons.close,
                    color: AppColors.error.withOpacity(0.5),
                    size: 20,
                  ),
                  onPressed: onDismiss,
                ),
            ],
          ),
          const SizedBox(height: AppSizes.md),
          Text(
            LegalConstants.emergencyNotice,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.error.withOpacity(0.9),
                  height: 1.4,
                ),
          ),
          const SizedBox(height: AppSizes.md),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _callCVV,
                  icon: const Icon(Icons.phone),
                  label: const Text('Ligar 188'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: AppSizes.sm),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _openCVVChat,
                  icon: const Icon(Icons.chat),
                  label: const Text('Chat CVV'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _callCVV() async {
    final uri = Uri.parse('tel:188');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _openCVVChat() async {
    final uri = Uri.parse('https://www.cvv.org.br');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
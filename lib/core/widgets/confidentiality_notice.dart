// lib/core/widgets/confidentiality_notice.dart

import 'package:flutter/material.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_sizes.dart';
import '../../config/constants/legal_constants.dart';

class ConfidentialityNotice extends StatelessWidget {
  final bool showIcon;
  final bool isCompact;

  const ConfidentialityNotice({
    super.key,
    this.showIcon = true,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isCompact) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.lock_outline,
            size: 14,
            color: AppColors.textLight,
          ),
          const SizedBox(width: 4),
          Text(
            'Informações protegidas por sigilo',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textLight,
                  fontSize: 11,
                ),
          ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: AppColors.infoLight.withOpacity(0.5),
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: AppColors.info.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showIcon) ...[
            Icon(
              Icons.shield_outlined,
              color: AppColors.info,
              size: 20,
            ),
            const SizedBox(width: AppSizes.sm),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sigilo Garantido',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppColors.info,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  LegalConstants.confidentialityNotice,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.info.withOpacity(0.9),
                        height: 1.4,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
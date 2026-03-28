// lib/core/widgets/menteviva_logo.dart

import 'package:flutter/material.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_sizes.dart';
import '../../config/constants/app_constants.dart';

class MenteVivaLogo extends StatelessWidget {
  final double size;
  final bool showText;

  const MenteVivaLogo({
    super.key,
    this.size = 80,
    this.showText = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Ícone
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.primaryDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(size * 0.25),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Icon(
            Icons.psychology_rounded,
            size: size * 0.55,
            color: Colors.white,
          ),
        ),

        if (showText) ...[
          const SizedBox(height: AppSizes.md),
          Text(
            AppConstants.appName,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: AppSizes.xs),
          Text(
            AppConstants.appTagline,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}
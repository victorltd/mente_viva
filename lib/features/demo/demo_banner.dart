// lib/features/demo/demo_banner.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_sizes.dart';
import '../../config/constants/demo_constants.dart';
import '../../providers/auth_provider.dart';

class DemoBanner extends ConsumerWidget {
  const DemoBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: double.infinity,
      color: AppColors.primary,
      padding: const EdgeInsets.symmetric(
        vertical: AppSizes.sm,
        horizontal: AppSizes.md,
      ),
      child: Row(
        children: [
          const Icon(
            Icons.theaters_rounded,
            color: Colors.white,
            size: 16,
          ),
          const SizedBox(width: AppSizes.xs),
          Expanded(
            child: Text(
              DemoConstants.bannerText,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          TextButton(
            onPressed: () => _handleExit(context, ref),
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              DemoConstants.bannerCta,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white,
                    decoration: TextDecoration.underline,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleExit(BuildContext context, WidgetRef ref) {
    ref.read(authProvider.notifier).signOutDemo();
    context.go('/demo');
  }
}

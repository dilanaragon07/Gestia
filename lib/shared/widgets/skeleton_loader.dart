import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/theme/app_colors.dart';

class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8,
  });

  final double width;
  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.card,
      highlightColor: AppColors.cardElevated,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

class SkeletonStatCard extends StatelessWidget {
  const SkeletonStatCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Shimmer.fromColors(
        baseColor: AppColors.card,
        highlightColor: AppColors.cardElevated,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.cardElevated,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                Container(
                  width: 48,
                  height: 20,
                  decoration: BoxDecoration(
                    color: AppColors.cardElevated,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: 100,
              height: 28,
              decoration: BoxDecoration(
                color: AppColors.cardElevated,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: 80,
              height: 14,
              decoration: BoxDecoration(
                color: AppColors.cardElevated,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SkeletonInvoiceCard extends StatelessWidget {
  const SkeletonInvoiceCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Shimmer.fromColors(
        baseColor: AppColors.card,
        highlightColor: AppColors.cardElevated,
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.cardElevated,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 140,
                    height: 14,
                    decoration: BoxDecoration(
                      color: AppColors.cardElevated,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 90,
                    height: 12,
                    decoration: BoxDecoration(
                      color: AppColors.cardElevated,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  width: 80,
                  height: 16,
                  decoration: BoxDecoration(
                    color: AppColors.cardElevated,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 60,
                  height: 24,
                  decoration: BoxDecoration(
                    color: AppColors.cardElevated,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class SkeletonDashboard extends StatelessWidget {
  const SkeletonDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          const SkeletonBox(width: 200, height: 24, borderRadius: 6),
          const SizedBox(height: 8),
          const SkeletonBox(width: 140, height: 16, borderRadius: 4),
          const SizedBox(height: 24),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: const [
              SkeletonStatCard(),
              SkeletonStatCard(),
              SkeletonStatCard(),
              SkeletonStatCard(),
            ],
          ),
          const SizedBox(height: 24),
          const SkeletonBox(width: double.infinity, height: 180, borderRadius: 16),
          const SizedBox(height: 24),
          ...List.generate(3, (_) => const SkeletonInvoiceCard()),
        ],
      ),
    );
  }
}

class SkeletonCard extends StatelessWidget {
  const SkeletonCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.card,
      highlightColor: AppColors.cardElevated,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
      ),
    );
  }
}

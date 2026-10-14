import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Clinical Grade Shimmer & Skeleton Loader System
/// Provides GPU-accelerated placeholder loading states without external dependencies.
class Shimmer extends StatefulWidget {
  final Widget child;
  final Color baseColor;
  final Color highlightColor;
  final Duration duration;

  const Shimmer({
    super.key,
    required this.child,
    this.baseColor = const Color(0xFFE2E8F0), // Slate-200
    this.highlightColor = const Color(0xFFF8FAFC), // Slate-50
    this.duration = const Duration(milliseconds: 1500),
  });

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: const Alignment(-1.5, -0.3),
              end: const Alignment(1.5, 0.3),
              stops: const [0.0, 0.45, 0.55, 1.0],
              colors: [
                widget.baseColor,
                widget.highlightColor,
                widget.highlightColor,
                widget.baseColor,
              ],
              transform: _SlidingGradientTransform(slidePercent: _controller.value),
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  final double slidePercent;
  const _SlidingGradientTransform({required this.slidePercent});

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * (slidePercent * 2 - 1), 0.0, 0.0);
  }
}

/// Generic Skeleton Shape
class SkeletonBox extends StatelessWidget {
  final double? width;
  final double? height;
  final double borderRadius;
  final Color? color;

  const SkeletonBox({
    super.key,
    this.width,
    this.height,
    this.borderRadius = 8.0,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color ?? const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

/// Skeleton for text lines
class SkeletonText extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const SkeletonText({
    super.key,
    this.width = double.infinity,
    this.height = 14.0,
    this.borderRadius = 4.0,
  });

  @override
  Widget build(BuildContext context) {
    return SkeletonBox(
      width: width,
      height: height,
      borderRadius: borderRadius,
    );
  }
}

/// Skeleton for circular avatars
class SkeletonAvatar extends StatelessWidget {
  final double radius;

  const SkeletonAvatar({super.key, this.radius = 20.0});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: const BoxDecoration(
        color: Color(0xFFE2E8F0),
        shape: BoxShape.circle,
      ),
    );
  }
}

/// High-fidelity Skeleton for a Patient Card
class SkeletonPatientCard extends StatelessWidget {
  const SkeletonPatientCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.borderLight),
      ),
      child: const Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    SkeletonAvatar(radius: 20),
                    SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SkeletonText(width: 160, height: 16),
                        SizedBox(height: 6),
                        Row(
                          children: [
                            SkeletonBox(width: 80, height: 14, borderRadius: 4),
                            SizedBox(width: 8),
                            SkeletonBox(width: 110, height: 14, borderRadius: 4),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                SkeletonBox(width: 80, height: 24, borderRadius: 12),
              ],
            ),
            Divider(height: 24, color: AppColors.borderLight),
            Row(
              children: [
                SkeletonBox(width: 130, height: 14, borderRadius: 4),
                SizedBox(width: 24),
                SkeletonBox(width: 200, height: 14, borderRadius: 4),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Staggered List of Patient Skeleton Cards
class SkeletonPatientList extends StatelessWidget {
  final int count;

  const SkeletonPatientList({super.key, this.count = 5});

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: count,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, __) => const SkeletonPatientCard(),
      ),
    );
  }
}

/// Skeleton for Dashboard Metrics & Cards
class SkeletonDashboard extends StatelessWidget {
  const SkeletonDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 4 KPI Cards Grid
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 900;
              final count = isWide ? 4 : 2;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: count,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: isWide ? 2.1 : 1.7,
                ),
                itemCount: 4,
                itemBuilder: (_, __) => Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: AppColors.borderLight),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            SkeletonBox(width: 100, height: 14),
                            SkeletonAvatar(radius: 16),
                          ],
                        ),
                        SkeletonBox(width: 70, height: 28),
                        SkeletonBox(width: 120, height: 12),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),

          // Lower Section Cards
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: AppColors.borderLight),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SkeletonText(width: 180, height: 18),
                        SizedBox(height: 16),
                        SkeletonBox(width: double.infinity, height: 160, borderRadius: 8),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: AppColors.borderLight),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SkeletonText(width: 140, height: 18),
                        SizedBox(height: 16),
                        SkeletonBox(width: double.infinity, height: 40, borderRadius: 6),
                        SizedBox(height: 12),
                        SkeletonBox(width: double.infinity, height: 40, borderRadius: 6),
                        SizedBox(height: 12),
                        SkeletonBox(width: double.infinity, height: 40, borderRadius: 6),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

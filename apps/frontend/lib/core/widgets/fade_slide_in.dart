import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Minimal, high-performance entrance micro-animation.
/// Provides a gentle vertical slide and opacity fade-in.
class FadeSlideIn extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;
  final double offset;
  final Curve curve;

  const FadeSlideIn({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 380),
    this.delay = Duration.zero,
    this.offset = 12.0,
    this.curve = Curves.easeOutCubic,
  });

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);

    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: widget.curve),
    );

    _slide = Tween<Offset>(
      begin: Offset(0, widget.offset / 100),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: widget.curve),
    );

    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _slide,
        child: widget.child,
      ),
    );
  }
}

/// Interactive Card Hover Micro-Interaction
/// Elevates the card with smooth border transition and soft clinical shadow on mouse hover.
class CardHover extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double borderRadius;
  final Color? baseColor;

  const CardHover({
    super.key,
    required this.child,
    this.onTap,
    this.borderRadius = 12.0,
    this.baseColor,
  });

  @override
  State<CardHover> createState() => _CardHoverState();
}

class _CardHoverState extends State<CardHover> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: widget.onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          transform: Matrix4.translationValues(0, _isHovered ? -2.0 : 0.0, 0),
          decoration: BoxDecoration(
            color: widget.baseColor ?? AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            border: Border.all(
              color: _isHovered
                  ? AppColors.primaryLight.withValues(alpha: 0.6)
                  : AppColors.borderLight,
              width: _isHovered ? 1.2 : 1.0,
            ),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

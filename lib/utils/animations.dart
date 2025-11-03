import 'package:flutter/material.dart';

/// 动画工具类，统一管理应用中的动画配置和过渡效果
class AppAnimations {
  static const Duration _fastDuration = Duration(milliseconds: 200);
  static const Duration _normalDuration = Duration(milliseconds: 300);
  static const Duration _slowDuration = Duration(milliseconds: 500);

  /// 标准缓动曲线
  static const Curve _defaultCurve = Curves.easeInOut;
  static const Curve _fastCurve = Curves.easeOut;
  static const Curve _elasticCurve = Curves.elasticOut;

  /// 页面过渡动画 - 滑动过渡
  static Widget slideTransition({
    required Widget child,
    required Animation<double> animation,
    SlideDirection direction = SlideDirection.fromRight,
  }) {
    late Offset begin;
    
    switch (direction) {
      case SlideDirection.fromRight:
        begin = const Offset(1.0, 0.0);
        break;
      case SlideDirection.fromLeft:
        begin = const Offset(-1.0, 0.0);
        break;
      case SlideDirection.fromTop:
        begin = const Offset(0.0, -1.0);
        break;
      case SlideDirection.fromBottom:
        begin = const Offset(0.0, 1.0);
        break;
    }

    return SlideTransition(
      position: animation.drive(
        Tween(begin: begin, end: Offset.zero).chain(
          CurveTween(curve: _defaultCurve),
        ),
      ),
      child: child,
    );
  }

  /// 渐入渐出过渡
  static Widget fadeTransition({
    required Widget child,
    required Animation<double> animation,
  }) {
    return FadeTransition(
      opacity: animation.drive(
        Tween(begin: 0.0, end: 1.0).chain(
          CurveTween(curve: _defaultCurve),
        ),
      ),
      child: child,
    );
  }

  /// 缩放过渡
  static Widget scaleTransition({
    required Widget child,
    required Animation<double> animation,
    double beginScale = 0.8,
  }) {
    return ScaleTransition(
      scale: animation.drive(
        Tween(begin: beginScale, end: 1.0).chain(
          CurveTween(curve: _elasticCurve),
        ),
      ),
      child: child,
    );
  }

  /// 组合过渡（滑动 + 渐入）
  static Widget slideAndFadeTransition({
    required Widget child,
    required Animation<double> animation,
    SlideDirection direction = SlideDirection.fromRight,
  }) {
    return slideTransition(
      direction: direction,
      animation: animation,
      child: fadeTransition(
        animation: animation,
        child: child,
      ),
    );
  }

  /// 路由过渡构建器
  static Route<T> createRoute<T>({
    required Widget page,
    RouteTransitionType type = RouteTransitionType.slideAndFade,
    SlideDirection direction = SlideDirection.fromRight,
    Duration? duration,
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration ?? _normalDuration,
      reverseTransitionDuration: duration ?? _normalDuration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        switch (type) {
          case RouteTransitionType.slide:
            return slideTransition(
              child: child,
              animation: animation,
              direction: direction,
            );
          case RouteTransitionType.fade:
            return fadeTransition(
              child: child,
              animation: animation,
            );
          case RouteTransitionType.scale:
            return scaleTransition(
              child: child,
              animation: animation,
            );
          case RouteTransitionType.slideAndFade:
            return slideAndFadeTransition(
              child: child,
              animation: animation,
              direction: direction,
            );
        }
      },
    );
  }

  /// 创建淡入淡出动画控制器
  static AnimationController createFadeController({
    required TickerProvider vsync,
    Duration? duration,
  }) {
    return AnimationController(
      duration: duration ?? _normalDuration,
      vsync: vsync,
    );
  }

  /// 创建缩放动画控制器
  static AnimationController createScaleController({
    required TickerProvider vsync,
    Duration? duration,
  }) {
    return AnimationController(
      duration: duration ?? _fastDuration,
      vsync: vsync,
    );
  }

  /// 连接状态动画
  static Widget buildConnectionStatusAnimation({
    required Widget child,
    required bool isConnected,
    required TickerProvider vsync,
  }) {
    return AnimatedContainer(
      duration: _normalDuration,
      curve: _defaultCurve,
      child: AnimatedOpacity(
        duration: _fastDuration,
        opacity: isConnected ? 1.0 : 0.7,
        child: child,
      ),
    );
  }

  /// 按钮点击反馈动画
  static Widget buildTapAnimation({
    required Widget child,
    required VoidCallback? onTap,
    Duration? duration,
  }) {
    return TapAnimationWrapper(
      onTap: onTap,
      duration: duration ?? _fastDuration,
      child: child,
    );
  }

  /// 加载动画
  static Widget buildLoadingAnimation({
    required bool isLoading,
    required Widget child,
    Widget? loadingWidget,
  }) {
    return AnimatedSwitcher(
      duration: _normalDuration,
      transitionBuilder: (child, animation) {
        return fadeTransition(
          child: child,
          animation: animation,
        );
      },
      child: isLoading 
          ? loadingWidget ?? const CircularProgressIndicator()
          : child,
    );
  }

  /// 列表项动画
  static Widget buildListItemAnimation({
    required Widget child,
    required int index,
    Duration? delay,
  }) {
    return AnimatedListItem(
      index: index,
      delay: delay ?? Duration(milliseconds: index * 50),
      child: child,
    );
  }
}

/// 滑动方向枚举
enum SlideDirection {
  fromLeft,
  fromRight,
  fromTop,
  fromBottom,
}

/// 路由过渡类型枚举
enum RouteTransitionType {
  slide,
  fade,
  scale,
  slideAndFade,
}

/// 点击动画包装器
class TapAnimationWrapper extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Duration duration;
  final double scaleDown;

  const TapAnimationWrapper({
    super.key,
    required this.child,
    required this.onTap,
    this.duration = const Duration(milliseconds: 100),
    this.scaleDown = 0.95,
  });

  @override
  State<TapAnimationWrapper> createState() => _TapAnimationWrapperState();
}

class _TapAnimationWrapperState extends State<TapAnimationWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.scaleDown,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    _controller.reverse();
  }

  void _handleTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onTap != null ? _handleTapDown : null,
      onTapUp: widget.onTap != null ? _handleTapUp : null,
      onTapCancel: widget.onTap != null ? _handleTapCancel : null,
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: widget.child,
          );
        },
      ),
    );
  }
}

/// 列表项动画组件
class AnimatedListItem extends StatefulWidget {
  final Widget child;
  final int index;
  final Duration delay;

  const AnimatedListItem({
    super.key,
    required this.child,
    required this.index,
    this.delay = Duration.zero,
  });

  @override
  State<AnimatedListItem> createState() => _AnimatedListItemState();
}

class _AnimatedListItemState extends State<AnimatedListItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
    ));

    // 延迟开始动画
    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.forward();
      }
    });
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
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: widget.child,
          ),
        );
      },
    );
  }
}

/// 脉冲动画组件
class PulseAnimation extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double minScale;
  final double maxScale;

  const PulseAnimation({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 1000),
    this.minScale = 1.0,
    this.maxScale = 1.1,
  });

  @override
  State<PulseAnimation> createState() => _PulseAnimationState();
}

class _PulseAnimationState extends State<PulseAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(
      begin: widget.minScale,
      end: widget.maxScale,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: widget.child,
        );
      },
    );
  }
}

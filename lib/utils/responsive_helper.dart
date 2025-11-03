import 'package:flutter/material.dart';

/// 响应式设计辅助工具
class ResponsiveHelper {
  // 屏幕断点
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 1024;
  static const double desktopBreakpoint = 1440;

  /// 获取屏幕类型
  static ScreenType getScreenType(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    
    if (width < mobileBreakpoint) {
      return ScreenType.mobile;
    } else if (width < tabletBreakpoint) {
      return ScreenType.tablet;
    } else {
      return ScreenType.desktop;
    }
  }

  /// 是否为移动设备
  static bool isMobile(BuildContext context) {
    return getScreenType(context) == ScreenType.mobile;
  }

  /// 是否为平板
  static bool isTablet(BuildContext context) {
    return getScreenType(context) == ScreenType.tablet;
  }

  /// 是否为桌面
  static bool isDesktop(BuildContext context) {
    return getScreenType(context) == ScreenType.desktop;
  }

  /// 获取响应式值
  static T responsive<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    final screenType = getScreenType(context);
    
    switch (screenType) {
      case ScreenType.mobile:
        return mobile;
      case ScreenType.tablet:
        return tablet ?? mobile;
      case ScreenType.desktop:
        return desktop ?? tablet ?? mobile;
    }
  }

  /// 获取响应式边距
  static EdgeInsets getResponsivePadding(BuildContext context) {
    return responsive(
      context,
      mobile: const EdgeInsets.all(16),
      tablet: const EdgeInsets.all(24),
      desktop: const EdgeInsets.all(32),
    );
  }

  /// 获取最大内容宽度
  static double getMaxContentWidth(BuildContext context) {
    return responsive(
      context,
      mobile: double.infinity,
      tablet: 800,
      desktop: 1200,
    );
  }

  /// 获取网格列数
  static int getGridColumns(BuildContext context) {
    return responsive(
      context,
      mobile: 1,
      tablet: 2,
      desktop: 3,
    );
  }

  /// 获取卡片间距
  static double getCardSpacing(BuildContext context) {
    return responsive(
      context,
      mobile: 12,
      tablet: 16,
      desktop: 20,
    );
  }

  /// 获取标题字体大小
  static double getTitleFontSize(BuildContext context) {
    return responsive(
      context,
      mobile: 24,
      tablet: 28,
      desktop: 32,
    );
  }

  /// 获取副标题字体大小
  static double getSubtitleFontSize(BuildContext context) {
    return responsive(
      context,
      mobile: 16,
      tablet: 18,
      desktop: 20,
    );
  }

  /// 获取按钮高度
  static double getButtonHeight(BuildContext context) {
    return responsive(
      context,
      mobile: 48,
      tablet: 52,
      desktop: 56,
    );
  }

  /// 获取图标大小
  static double getIconSize(BuildContext context) {
    return responsive(
      context,
      mobile: 64,
      tablet: 72,
      desktop: 80,
    );
  }

  /// 获取安全区域和状态栏高度
  static double getTopSafeArea(BuildContext context) {
    return MediaQuery.of(context).padding.top;
  }

  /// 获取底部安全区域高度
  static double getBottomSafeArea(BuildContext context) {
    return MediaQuery.of(context).padding.bottom;
  }

  /// 获取屏幕宽度
  static double getScreenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  /// 获取屏幕高度
  static double getScreenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  /// 判断是否为横屏
  static bool isLandscape(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.landscape;
  }

  /// 判断是否为竖屏
  static bool isPortrait(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.portrait;
  }
}

/// 屏幕类型枚举
enum ScreenType {
  mobile,
  tablet,
  desktop,
}

/// 响应式构建器组件
class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, ScreenType screenType) builder;
  final Widget? mobile;
  final Widget? tablet;
  final Widget? desktop;

  const ResponsiveBuilder({
    super.key,
    required this.builder,
  }) : mobile = null, tablet = null, desktop = null;

  const ResponsiveBuilder.widgets({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  }) : builder = _defaultBuilder;

  static Widget _defaultBuilder(BuildContext context, ScreenType screenType) {
    throw UnimplementedError();
  }

  @override
  Widget build(BuildContext context) {
    final screenType = ResponsiveHelper.getScreenType(context);
    
    if (mobile != null || tablet != null || desktop != null) {
      switch (screenType) {
        case ScreenType.mobile:
          return mobile!;
        case ScreenType.tablet:
          return tablet ?? mobile!;
        case ScreenType.desktop:
          return desktop ?? tablet ?? mobile!;
      }
    }
    
    return builder(context, screenType);
  }
}

/// 限制最大宽度的容器
class MaxWidthContainer extends StatelessWidget {
  final Widget child;
  final double? maxWidth;
  final EdgeInsetsGeometry? padding;

  const MaxWidthContainer({
    super.key,
    required this.child,
    this.maxWidth,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveMaxWidth = maxWidth ?? ResponsiveHelper.getMaxContentWidth(context);
    final effectivePadding = padding ?? ResponsiveHelper.getResponsivePadding(context);
    
    return Center(
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(maxWidth: effectiveMaxWidth),
        padding: effectivePadding,
        child: child,
      ),
    );
  }
}

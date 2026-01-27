import 'package:flutter/material.dart';

/// 반응형 디자인 유틸리티
class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget desktop;

  const ResponsiveLayout({
    Key? key,
    required this.mobile,
    this.tablet,
    required this.desktop,
  }) : super(key: key);

  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < 600;
  }

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= 600 && width < 1200;
  }

  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= 1200;
  }

  static double getWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 1200) {
          return desktop;
        } else if (constraints.maxWidth >= 600) {
          return tablet ?? desktop;
        } else {
          return mobile;
        }
      },
    );
  }
}

/// 반응형 그리드 컬럼 수 계산
class ResponsiveGrid {
  static int getColumns(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= 1200) return 4; // Desktop: 4열
    if (width >= 900) return 3;  // Tablet 가로: 3열
    if (width >= 600) return 2;  // Tablet 세로: 2열
    return 1;                     // Mobile: 1열
  }

  static double getSpacing(BuildContext context) {
    return ResponsiveLayout.isDesktop(context) ? 24.0 : 16.0;
  }

  static double getPadding(BuildContext context) {
    if (ResponsiveLayout.isDesktop(context)) return 32.0;
    if (ResponsiveLayout.isTablet(context)) return 24.0;
    return 16.0;
  }
}

/// 반응형 텍스트 스타일
class ResponsiveText {
  static TextStyle heading1(BuildContext context) {
    final size = ResponsiveLayout.isDesktop(context) ? 32.0 : 24.0;
    return TextStyle(fontSize: size, fontWeight: FontWeight.bold);
  }

  static TextStyle heading2(BuildContext context) {
    final size = ResponsiveLayout.isDesktop(context) ? 24.0 : 20.0;
    return TextStyle(fontSize: size, fontWeight: FontWeight.bold);
  }

  static TextStyle heading3(BuildContext context) {
    final size = ResponsiveLayout.isDesktop(context) ? 20.0 : 18.0;
    return TextStyle(fontSize: size, fontWeight: FontWeight.w600);
  }

  static TextStyle body(BuildContext context) {
    final size = ResponsiveLayout.isDesktop(context) ? 16.0 : 14.0;
    return TextStyle(fontSize: size);
  }
}

/// 반응형 카드 너비
class ResponsiveCard extends StatelessWidget {
  final Widget child;
  final double? maxWidth;

  const ResponsiveCard({
    Key? key,
    required this.child,
    this.maxWidth,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth ?? (ResponsiveLayout.isDesktop(context) ? 1200 : double.infinity),
        ),
        child: child,
      ),
    );
  }
}

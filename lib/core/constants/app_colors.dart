import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ============================================
  // 🌸 MindDrop 温暖治愈配色方案
  // ============================================

  // 主色调 - 珊瑚橙 (温暖、活力)
  static const Color primary = Color(0xFFFF9B7B);
  static const Color primaryLight = Color(0xFFFFBFA0);
  static const Color primaryDark = Color(0xFFE87B5C);
  static const Color primaryContainer = Color(0xFFFFF0EB);

  // 辅色调 - 天空蓝 (平静、安心)
  static const Color secondary = Color(0xFF7EC8E3);
  static const Color secondaryLight = Color(0xFFA8D8F0);
  static const Color secondaryDark = Color(0xFF4BA3C7);
  static const Color secondaryContainer = Color(0xFFE8F6FC);

  // 强调色 - 暖黄 (高亮、重点)
  static const Color accent = Color(0xFFFFD93D);
  static const Color accentLight = Color(0xFFFFE57A);
  static const Color accentContainer = Color(0xFFFFF9E0);

  // 柔和紫 (创意、灵感)
  static const Color purpleSoft = Color(0xFFB8A9C9);
  static const Color purpleSoftLight = Color(0xFFD4C9E2);
  static const Color purpleSoftContainer = Color(0xFFF5F1F9);

  // 背景色 - 暖白 (舒适阅读)
  static const Color background = Color(0xFFFFF8F0);
  static const Color surfaceBackground = Color(0xFFFFF8F0);
  static const Color surface = Color(0xFFFFF3E8);
  static const Color cardBackground = Colors.white;

  // 文字色
  static const Color textPrimary = Color(0xFF4A3728);
  static const Color textSecondary = Color(0xFF8B7355);
  static const Color textTertiary = Color(0xFFB8A590);
  static const Color textOnPrimary = Colors.white;

  // 分类标签色
  static const Color tagBackground = Color(0xFFFFF0E8);
  static const Color tagText = Color(0xFFB8734A);

  // 状态色
  static const Color success = Color(0xFF7BC88C);
  static const Color successContainer = Color(0xFFE8F8EC);
  static const Color warning = Color(0xFFFFC85C);
  static const Color warningContainer = Color(0xFFFFF8E0);
  static const Color error = Color(0xFFFF8A80);
  static const Color errorContainer = Color(0xFFFFF0EE);

  // 想法类型色
  static const Color thoughtColor = Color(0xFFFF9B7B);    // 珊瑚橙
  static const Color projectColor = Color(0xFF7EC8E3);      // 天空蓝
  static const Color questionColor = Color(0xFFFFD93D);     // 暖黄
  static const Color inspirationColor = Color(0xFFB8A9C9);  // 柔和紫

  // 心情色
  static const Color moodHappy = Color(0xFFFFD93D);    // 开心
  static const Color moodCalm = Color(0xFF7EC8E3);    // 平静
  static const Color moodSad = Color(0xFFB8A9C9);      // 伤感
  static const Color moodExcited = Color(0xFFFF9B7B); // 兴奋

  // 渐变色
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFFFF9B7B), Color(0xFFFFBFA0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient warmGradient = LinearGradient(
    colors: [Color(0xFFFFF8F0), Color(0xFFFFF0E8)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient sunsetGradient = LinearGradient(
    colors: [Color(0xFFFF9B7B), Color(0xFFFFD93D), Color(0xFF7EC8E3)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // 阴影色
  static const Color shadowLight = Color(0x1A000000);
  static const Color shadowMedium = Color(0x26000000);
  static const Color shadowWarm = Color(0x15FF9B7B);

  // 边框色
  static const Color border = Color(0xFFEDE4DC);
  static const Color borderLight = Color(0xFFF5EDE5);

  // 毛玻璃效果
  static Color frostedGlass = Colors.white.withOpacity(0.85);
  static Color frostedGlassDark = Color(0xFF4A3728).withOpacity(0.85);
}

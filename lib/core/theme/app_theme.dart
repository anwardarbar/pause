import 'package:flutter/cupertino.dart';

// ─── Colors ──────────────────────────────────────────────────────────────────

class AppColors {
  AppColors._();

  // Background gradient
  static const Color backgroundTop = Color(0xFF0A0F1E);
  static const Color backgroundMid = Color(0xFF0C1224);
  static const Color backgroundBot = Color(0xFF05070F);

  // Surfaces
  static const Color surfaceL1 = Color(0xFF111827);
  static const Color surfaceL2 = Color(0xFF151C2E);
  static const Color surfaceL3 = Color(0xFF1A2238);

  // Glass — rgba values converted to 8-bit alpha
  static const Color glassFill = Color(0x0AFFFFFF);   // rgba(255,255,255,0.04)
  static const Color glassBorder = Color(0x14FFFFFF); // rgba(255,255,255,0.08)
  static const Color surfaceBorder = Color(0x0FFFFFFF); // rgba(255,255,255,0.06)

  // Gold
  static const Color goldPrimary = Color(0xFFC6A969);
  static const Color goldHighlight = Color(0xFFE6C98A);
  static const Color goldGlow = Color(0x40C6A969); // rgba(198,169,105,0.25)

  // Semantic
  static const Color semanticExpense = Color(0xFFFF6B6B);
  static const Color semanticSaved = Color(0xFF3FB8A6);

  // Text
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFA0A6B8);
  static const Color textTertiary = Color(0xFF4A5568);
}

// ─── Typography ──────────────────────────────────────────────────────────────

class AppTypography {
  AppTypography._();

  static const String _font = 'SF Pro Display';

  static const TextStyle display = TextStyle(
    fontFamily: _font,
    fontSize: 34,
    fontWeight: FontWeight.w700,
    letterSpacing: -1.02, // -0.03em × 34
    color: AppColors.textPrimary,
  );

  static const TextStyle title = TextStyle(
    fontFamily: _font,
    fontSize: 22,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.44, // -0.02em × 22
    color: AppColors.textPrimary,
  );

  static const TextStyle headline = TextStyle(
    fontFamily: _font,
    fontSize: 17,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.17, // -0.01em × 17
    color: AppColors.textPrimary,
  );

  static const TextStyle body = TextStyle(
    fontFamily: _font,
    fontSize: 15,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    color: AppColors.textPrimary,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: _font,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.24, // +0.02em × 12
    color: AppColors.textSecondary,
  );

  // All-caps label — caller must apply .toUpperCase() on text
  static const TextStyle label = TextStyle(
    fontFamily: _font,
    fontSize: 10,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.0, // +0.10em × 10
    color: AppColors.textSecondary,
  );
}

// ─── Spacing (8pt grid) ──────────────────────────────────────────────────────

class AppSpacing {
  AppSpacing._();

  static const double sp1 = 4;
  static const double sp2 = 8;
  static const double sp3 = 12;
  static const double sp4 = 16;
  static const double sp5 = 20;
  static const double sp6 = 24;
  static const double sp8 = 32;
  static const double sp12 = 48;
}

// ─── Border Radius ───────────────────────────────────────────────────────────

class AppRadius {
  AppRadius._();

  static const BorderRadius card = BorderRadius.all(Radius.circular(16));
  static const BorderRadius chip = BorderRadius.all(Radius.circular(10));
  static const BorderRadius sheet = BorderRadius.all(Radius.circular(20));
  static const BorderRadius overlay = BorderRadius.all(Radius.circular(20));
  static const BorderRadius pill = BorderRadius.all(Radius.circular(100));
}

// ─── Motion ──────────────────────────────────────────────────────────────────

class AppMotion {
  AppMotion._();

  static const Duration cardFloat = Duration(milliseconds: 240);
  static const Duration sheetRise = Duration(milliseconds: 320);
  static const Duration swipeSnap = Duration(milliseconds: 280);
  static const Duration swipeDismiss = Duration(milliseconds: 220);
  static const Duration numberCount = Duration(milliseconds: 600);
  static const Duration screenNav = Duration(milliseconds: 380);
  static const Duration micBreathe = Duration(milliseconds: 4000);
  static const Duration micPulse = Duration(milliseconds: 800);

  // spring(0.4,0,0.2,1) approximation — will tune if needed after visual review
  static const Curve sheetRiseCurve = Curves.easeOutCubic;
  static const Curve swipeSnapCurve = Curves.easeOutBack;
  static const Curve swipeDismissCurve = Curves.easeIn;
  static const Curve cardFloatCurve = Curves.easeOut;
  static const Curve numberCountCurve = Curves.easeOut;
}

// ─── Theme ───────────────────────────────────────────────────────────────────

class AppTheme {
  AppTheme._();

  static CupertinoThemeData darkTheme() {
    return const CupertinoThemeData(
      brightness: Brightness.dark,
      primaryColor: AppColors.goldPrimary,
      primaryContrastingColor: AppColors.backgroundTop,
      scaffoldBackgroundColor: AppColors.backgroundBot,
      barBackgroundColor: AppColors.surfaceL1,
      textTheme: CupertinoTextThemeData(
        primaryColor: AppColors.textPrimary,
        textStyle: AppTypography.body,
        actionTextStyle: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: AppColors.goldPrimary,
        ),
        navTitleTextStyle: AppTypography.headline,
        navLargeTitleTextStyle: AppTypography.title,
        tabLabelTextStyle: AppTypography.caption,
      ),
    );
  }
}

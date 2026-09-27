import 'package:flutter/material.dart';

/// EmployScope design tokens.
///
/// Extracted directly from the existing Login / Signup / Dashboard / Drawer
/// screens so every new Week 5 widget stays visually identical to them.
/// If you already have a theme file in your project, merge these values
/// into it instead of keeping two sources of truth.
class AppColors {
  AppColors._();

  // Background gradient (top -> bottom), as seen on Login/Signup/Dashboard.
  static const Color bgTop = Color(0xFF0F1E33); // deep navy (status bar area)
  static const Color bgMid = Color(0xFF3E5578); // mid transition blue
  static const Color bgBottom = Color(0xFFA9B7E4); // pale periwinkle (bottom)

  static const LinearGradient screenGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [bgTop, bgMid, bgBottom],
    stops: [0.0, 0.45, 1.0],
  );

  // Card / panel surfaces (the rounded translucent boxes on every screen).
  static const Color cardFill = Color(0xCC1E2E45); // dark navy @ ~80% alpha
  static const Color cardBorder = Color(0x33FFFFFF); // hairline white 20%
  static const Color drawerFill = Color(0xFF14233A); // solid drawer navy

  // Text.
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFFC7CEDD); // muted grey-blue
  static const Color textPlaceholder = Color(0xFF8C96AC);
  static const Color textOnLight = Color(0xFF16243B); // navy text on white btn

  // Buttons.
  static const Color primaryButtonFill = Colors.white;
  static const Color secondaryButtonBorder = Colors.white;

  // Status accents (new for Week 5 — kept inside the same cool palette so
  // they read as "part of the app" rather than a foreign color system).
  static const Color accentGood = Color(0xFF7ED9A8); // match / success
  static const Color accentWarn = Color(0xFFE8C97A); // partial match
  static const Color accentGap = Color(0xFFE28C8C); // missing / gap
  static const Color accentInfo = Color(0xFF9AB6F2); // neutral info/chip
}

class AppRadii {
  AppRadii._();
  static const double card = 20;
  static const double pillButton = 30;
  static const double chip = 12;
  static const double smallCard = 14;
}

class AppTextStyles {
  AppTextStyles._();

  // Cursive brand wordmark ("EmployScope"). Swap FontFamily for whatever
  // script font you already load (e.g. GoogleFonts.dancingScript) — this
  // uses a generic cursive fallback so the file compiles standalone.
  static const TextStyle logo = TextStyle(
    fontFamily: 'cursive',
    fontSize: 26,
    color: AppColors.textPrimary,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle screenTitle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    letterSpacing: 0.3,
  );

  static const TextStyle sectionHeading = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static const TextStyle body = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.35,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textPlaceholder,
  );

  static const TextStyle buttonDark = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.bold,
    color: AppColors.textOnLight,
    letterSpacing: 0.5,
  );

  static const TextStyle buttonLight = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    letterSpacing: 0.5,
  );
}

/// The rounded translucent card decoration used by every panel in the app
/// (login box, signup box, drawer content, etc.). Reuse this everywhere in
/// Week 5 so new boxes look native.
class AppDecorations {
  AppDecorations._();

  static BoxDecoration card({double radius = AppRadii.card}) {
    return BoxDecoration(
      color: AppColors.cardFill,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: AppColors.cardBorder, width: 1),
      boxShadow: const [
        BoxShadow(
          color: Colors.black38,
          blurRadius: 16,
          offset: Offset(0, 8),
        ),
      ],
    );
  }

  static InputDecoration underlineInput(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.textPlaceholder),
      enabledBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: AppColors.cardBorder),
      ),
      focusedBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: Colors.white),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 10),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ============================================================
// AJF — SYSTÈME DE DESIGN
// ------------------------------------------------------------
// Toutes les couleurs, tailles d'arrondis et styles de
// composants (boutons, champs, cartes, boîtes de dialogue...)
// sont définis ICI, en un seul endroit. Modifier une valeur
// dans ce fichier met à jour toute l'application.
// ============================================================

class AppColors {
  AppColors._();

  // Marque
  static const Color primary = Color(0xFF176B4D);
  static const Color primaryDark = Color(0xFF0F5239);
  static const Color primarySoft = Color(0xFFEAF3EE);

  // Surfaces
  static const Color background = Color(0xFFF4F6F5);
  static const Color surface = Colors.white;
  static const Color border = Color(0xFFC9D3CE);
  static const Color borderStrong = Color(0xFFA9B7B0);
  static const Color divider = Color(0xFFE8EDEA);

  // Texte
  static const Color textPrimary = Color(0xFF1A2320);
  static const Color textSecondary = Color(0xFF55615C);
  static const Color textMuted = Color(0xFF7B8681);

  // États
  static const Color info = Color(0xFF2457A6);
  static const Color warning = Color(0xFFB7791F);
  static const Color warningSoft = Color(0xFFFFF7E6);
  static const Color error = Color(0xFFB3261E);
  static const Color errorSoft = Color(0xFFFDEDEC);
}

class AppRadius {
  AppRadius._();

  /// Badges, petites étiquettes.
  static const double small = 8;

  /// Cartes, boutons, champs de saisie.
  static const double medium = 12;

  /// Boîtes de dialogue, feuilles du bas, grands blocs.
  static const double large = 16;
}

class AppShadows {
  AppShadows._();

  /// Ombre très légère pour les éléments cliquables mis en avant.
  static const List<BoxShadow> soft = [
    BoxShadow(
      color: Color(0x1A101828),
      blurRadius: 12,
      offset: Offset(0, 3),
    ),
  ];
}

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
    ).copyWith(
      primary: AppColors.primary,
      onPrimary: Colors.white,
      onSurface: AppColors.textPrimary,
      outline: AppColors.border,
      outlineVariant: AppColors.divider,
      error: AppColors.error,
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: 'Arial',
    );

    final textTheme = base.textTheme
        .apply(
          bodyColor: AppColors.textPrimary,
          displayColor: AppColors.textPrimary,
        )
        .copyWith(
          headlineSmall: base.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
          titleLarge: base.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
          titleMedium: base.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        );

    final controlShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.medium),
    );

    OutlineInputBorder inputBorder(Color color, [double width = 1]) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.medium),
        borderSide: BorderSide(color: color, width: width),
      );
    }

    return base.copyWith(
      textTheme: textTheme,
      scaffoldBackgroundColor: AppColors.background,
      canvasColor: AppColors.surface,
      dividerColor: AppColors.divider,

      // ---------------- BARRE DU HAUT ----------------
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: TextStyle(
          fontFamily: 'Arial',
          fontSize: 19,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
        iconTheme: IconThemeData(color: Colors.white),
        actionsIconTheme: IconThemeData(color: Colors.white),
      ),

      // ---------------- CARTES ----------------
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 1.5,
        shadowColor: const Color(0x40101828),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.medium),
          side: const BorderSide(color: AppColors.border),
        ),
      ),

      // ---------------- BOUTONS ----------------
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFFCBD5D0),
          disabledForegroundColor: AppColors.textMuted,
          elevation: 0,
          minimumSize: const Size(64, 52),
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 12,
          ),
          shape: controlShape,
          textStyle: const TextStyle(
            fontFamily: 'Arial',
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFFCBD5D0),
          disabledForegroundColor: AppColors.textMuted,
          elevation: 0,
          minimumSize: const Size(64, 52),
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 12,
          ),
          shape: controlShape,
          textStyle: const TextStyle(
            fontFamily: 'Arial',
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          disabledForegroundColor: AppColors.textMuted,
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          minimumSize: const Size(64, 52),
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 12,
          ),
          shape: controlShape,
          textStyle: const TextStyle(
            fontFamily: 'Arial',
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          disabledForegroundColor: AppColors.textMuted,
          minimumSize: const Size(64, 44),
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 10,
          ),
          shape: controlShape,
          textStyle: const TextStyle(
            fontFamily: 'Arial',
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ---------------- CHAMPS DE SAISIE ----------------
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
        border: inputBorder(AppColors.border),
        enabledBorder: inputBorder(AppColors.border),
        focusedBorder: inputBorder(AppColors.primary, 2),
        errorBorder: inputBorder(AppColors.error),
        focusedErrorBorder: inputBorder(AppColors.error, 1.6),
        disabledBorder: inputBorder(AppColors.divider),
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        floatingLabelStyle: const TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
        ),
        hintStyle: const TextStyle(color: AppColors.textMuted),
        errorStyle: const TextStyle(
          color: AppColors.error,
          fontSize: 12,
        ),
      ),

      // ---------------- BOÎTES DE DIALOGUE ----------------
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.large),
        ),
        titleTextStyle: const TextStyle(
          fontFamily: 'Arial',
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        contentTextStyle: const TextStyle(
          fontFamily: 'Arial',
          fontSize: 14,
          height: 1.45,
          color: AppColors.textSecondary,
        ),
      ),

      // ---------------- FEUILLES DU BAS ----------------
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.large),
          ),
        ),
      ),

      // ---------------- MESSAGES (SNACKBAR) ----------------
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF26312D),
        contentTextStyle: const TextStyle(
          fontFamily: 'Arial',
          fontSize: 14,
          color: Colors.white,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.medium),
        ),
      ),

      // ---------------- DIVERS ----------------
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: AppColors.primary,
        textColor: AppColors.textPrimary,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        headerBackgroundColor: AppColors.primary,
        headerForegroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.large),
        ),
      ),
    );
  }
}

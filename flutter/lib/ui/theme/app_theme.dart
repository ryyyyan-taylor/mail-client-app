import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'colors.dart';
import 'text_styles.dart';

final ThemeData appTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  colorScheme: const ColorScheme.dark(
    primary: kAccent,
    onPrimary: kBlack,
    primaryContainer: kAccentDim,
    onPrimaryContainer: kTextPrimary,
    secondary: kTextSecondary,
    onSecondary: kBlack,
    surface: kSurfaceDark,
    onSurface: kTextPrimary,
    surfaceContainerHighest: kSurfaceVariant,
    onSurfaceVariant: kTextSecondary,
    outline: kDivider,
    error: kDanger,
    onError: kWhite,
    // Background slots map to Black
    surfaceContainerLowest: kBlack,
    surfaceContainer: kSurfaceDark,
  ),
  scaffoldBackgroundColor: kBlack,
  appBarTheme: const AppBarTheme(
    backgroundColor: kBlack,
    foregroundColor: kTextPrimary,
    elevation: 0,
    scrolledUnderElevation: 0,
    systemOverlayStyle: SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  ),
  dividerTheme: const DividerThemeData(
    color: kDivider,
    thickness: 1,
    space: 0,
  ),
  textTheme: const TextTheme(
    bodyLarge: kBodyLarge,
    bodyMedium: kBodyMedium,
    bodySmall: kBodySmall,
    titleMedium: kTitleMedium,
    labelSmall: kLabelSmall,
  ),
  bottomSheetTheme: const BottomSheetThemeData(
    backgroundColor: kSurfaceDark,
    surfaceTintColor: Colors.transparent,
  ),
  snackBarTheme: const SnackBarThemeData(
    backgroundColor: kSurfaceVariant,
    contentTextStyle: TextStyle(color: kTextPrimary),
    actionTextColor: kAccent,
  ),
  progressIndicatorTheme: const ProgressIndicatorThemeData(
    color: kAccent,
  ),
  iconTheme: const IconThemeData(
    color: kTextPrimary,
  ),
  listTileTheme: const ListTileThemeData(
    tileColor: kBlack,
    textColor: kTextPrimary,
    iconColor: kTextSecondary,
  ),
  switchTheme: SwitchThemeData(
    thumbColor: WidgetStateProperty.resolveWith((states) =>
        states.contains(WidgetState.selected) ? kAccent : kTextSecondary),
    trackColor: WidgetStateProperty.resolveWith((states) =>
        states.contains(WidgetState.selected) ? kAccentDim : kDivider),
  ),
);

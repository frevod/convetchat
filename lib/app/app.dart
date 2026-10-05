import 'package:convetchat/app/theme.dart';
import 'package:convetchat/core/di/locator.dart';
import 'package:convetchat/core/security/app_lock_gate.dart';
import 'package:convetchat/core/platform_style.dart';
import 'package:convetchat/core/theme/accent_color_store.dart';
import 'package:convetchat/core/theme/theme_mode_store.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:material_3_expressive/foundations/theme/m3e_dynamic_color_host.dart';
import 'package:material_3_expressive/foundations/theme/m3e_theme.dart';
import 'package:material_ui/material_ui.dart';

class const ConvetChatApp({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const _AppView();
  }
}

class const _AppView() extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final GoRouter router = getIt<GoRouter>();
    if (getIt<PlatformStyle>().isCupertino) {
      return ValueListenableBuilder<ThemeMode>(
        valueListenable: getIt<ThemeModeStore>(),
        builder: (context, themeMode, _) {
          return CupertinoApp.router(
            title: 'ConvetChat',
            theme: AppTheme.cupertinoTheme(
              _resolveBrightness(context, themeMode),
            ),
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            routerConfig: router,
            // ignore: deprecated_member_use
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                platformBrightness: _resolveBrightness(context, themeMode),
              ),
              // ignore: deprecated_member_use
              child: MaterialUiCompatibilityBridge(
                child: AppLockGate(child: child!),
              ),
            ),
          );
        },
      );
    }
    return M3EDynamicColorHost(
      builder: (lightDynamic, darkDynamic) {
        return ValueListenableBuilder<ThemeMode>(
          valueListenable: getIt<ThemeModeStore>(),
          builder: (context, themeMode, _) {
            return ValueListenableBuilder<Color>(
              valueListenable: getIt<AccentColorStore>(),
              builder: (context, _, _) {
                final accent = getIt<AccentColorStore>();
                final useDynamic = accent.useDynamicColor;
                return MaterialApp.router(
                  title: 'ConvetChat',
                  theme: AppTheme.materialTheme(
                    .light,
                    useDynamic ? lightDynamic : null,
                    seed: accent.value,
                  ),
                  darkTheme: AppTheme.materialTheme(
                    .dark,
                    useDynamic ? darkDynamic : null,
                    seed: accent.value,
                  ),
                  themeMode: themeMode,
                  localizationsDelegates: GlobalMaterialLocalizations.delegates,
                  routerConfig: router,

                  builder: (context, child) {
                    final m3eTheme = AppTheme.expressiveTheme(
                      Theme.of(context),
                    );
                    // ignore: deprecated_member_use
                    return MaterialUiCompatibilityBridge(
                      child: M3ETheme(
                        data: m3eTheme,
                        child: AppLockGate(
                          child: child ?? const SizedBox.shrink(),
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}

Brightness _resolveBrightness(BuildContext context, ThemeMode mode) {
  return switch (mode) {
    .light => .light,
    .dark => .dark,
    .system => MediaQuery.platformBrightnessOf(context),
  };
}

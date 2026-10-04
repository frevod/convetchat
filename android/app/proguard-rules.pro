# ConvetChat ProGuard rules.
# Сейчас minify выключен (см. build.gradle.kts), файл — задел на будущее
# и страховка, если Flutter Gradle Plugin включит R8 по умолчанию.

# Flutter embedding — не трогать.
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugins.** { *; }

# Наш код.
-keep class com.convet.convetchat.** { *; }

# Firebase (core, analytics, crashlytics, messaging).
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# UnifiedPush + tink (дубли классов уже форсятся в build.gradle.kts).
-keep class com.unifiedpush.** { *; }
-keep class com.google.crypto.tink.** { *; }
-dontwarn com.unifiedpush.**
-dontwarn com.google.crypto.tink.**

# flutter_secure_storage (Android Keystore).
-keep class com.it_nomads.fluttersecurestorage.** { *; }

# sqflite.
-keep class com.tekartik.sqflite.** { *; }

# flutter_local_notifications.
-keep class com.dexterous.flutterlocalnotifications.** { *; }

# flutter_web_auth_2 / Custom Tabs (SSO callback).
-keep class com.linusu.flutter_web_auth_2.** { *; }
-keep class androidx.browser.** { *; }

# just_audio / media_kit (десктоп, но keep безвреден).
-keep class com.ryanheise.** { *; }

# vodozemac идёт через dart:ffi (не JNI), Java-правила ему не нужны,
# но нативный .so нельзя стрипать агрессивным shrinkResources —
# поэтому isShrinkResources=false в build.gradle.kts.

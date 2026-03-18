# Keep Flutter and plugin generated classes used via reflection.
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.plugins.firebase.** { *; }

# Keep Gson type adapters if present.
-keep class com.google.gson.** { *; }
-keepattributes Signature


# --- Flutter embedding ---
-keep class io.flutter.embedding.** { *; }
-dontwarn io.flutter.embedding.**

# --- Google Play Core (REQUIRED for Flutter release builds) ---
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**

# --- Google Tasks ---
-keep class com.google.android.gms.tasks.** { *; }
-dontwarn com.google.android.gms.tasks.**

# --- Firebase ---
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**
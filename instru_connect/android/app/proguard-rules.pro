# Keep Flutter and plugin generated classes used via reflection.
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.plugins.firebase.** { *; }

# Keep Gson type adapters if present.
-keep class com.google.gson.** { *; }
-keepattributes Signature

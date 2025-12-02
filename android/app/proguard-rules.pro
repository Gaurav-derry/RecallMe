# Flutter specific rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Hive database
-keep class * extends com.google.protobuf.GeneratedMessageLite { *; }

# TFLite - Keep all tensorflow classes and ignore missing GPU delegate
-keep class org.tensorflow.** { *; }
-keepclassmembers class org.tensorflow.** { *; }
-dontwarn org.tensorflow.lite.gpu.**

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# RecallMe specific
-keep class com.example.recallme.** { *; }

# Gson (if used)
-keepattributes Signature
-keepattributes *Annotation*

# OkHttp (if used)
-dontwarn okhttp3.**
-dontwarn okio.**

# Prevent stripping of TTS
-keep class android.speech.tts.** { *; }

# Google Play Core - Ignore missing split install classes (not used)
-dontwarn com.google.android.play.core.splitcompat.**
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**

# ML Kit Face Detection
-keep class com.google.mlkit.** { *; }
-dontwarn com.google.mlkit.**

# Camera X
-keep class androidx.camera.** { *; }
-dontwarn androidx.camera.**

# Suppress warnings for missing optional dependencies
-dontwarn javax.annotation.**
-dontwarn org.codehaus.mojo.animal_sniffer.**

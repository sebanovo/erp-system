# MediaPipe y Protocol Buffers
-keep class com.google.mediapipe.** { *; }
-dontwarn com.google.mediapipe.**

-keep class com.google.protobuf.** { *; }
-dontwarn com.google.protobuf.**

# LiteRT y TensorFlow
-keep class org.tensorflow.** { *; }
-dontwarn org.tensorflow.**

-keep class com.google.ai.edge.** { *; }
-dontwarn com.google.ai.edge.**

# Gemma y LiteRT-LM
-keep class com.google.litertlm.** { *; }
-dontwarn com.google.litertlm.**

# Mantener todas las clases nativas
-keepclasseswithmembernames class * {
    native <methods>;
}

# Mantener todas las clases de servicios
-keep class * extends android.app.Service { *; }
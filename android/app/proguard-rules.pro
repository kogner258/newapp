# Stripe SDK
-keep class com.stripe.** { *; }
-dontwarn com.stripe.**
-keepattributes *Annotation*
-dontwarn android.support.v4.**
-keep class kotlin.** { *; }
-dontwarn kotlin.**

# For R8 optimization (if using R8)
-keepclassmembers class * {
    @androidx.annotation.Keep *;
}

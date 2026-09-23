# =====================================================================
# বাংলা পঞ্জিকা — R8/ProGuard নিয়ম
#
# কোড সংকোচন (isMinifyEnabled = true) চালু করলে এই নিয়মগুলো লাগবে।
# এগুলো ছাড়া R8 এমন ক্লাস ছেঁটে ফেলে যেগুলো কোড থেকে সরাসরি ডাকা হয়
# না, কিন্তু চলার সময় reflection দিয়ে খোঁজা হয় — তখন release APK
# খুললেই বন্ধ হয়ে যায় (debug-এ সমস্যা হয় না বলে আগে ধরা পড়ে না)।
# =====================================================================

# ---- Razorpay: পুরোটাই reflection-নির্ভর, না রাখলে পেমেন্ট ক্র্যাশ করে
-keep class com.razorpay.** { *; }
-keepclassmembers class com.razorpay.** { *; }
-dontwarn com.razorpay.**
-optimizations !method/inlining/*
-keepattributes JavascriptInterface
-keepattributes *Annotation*

# ---- Google Pay / UPI (Razorpay এগুলো খোঁজে)
-dontwarn com.google.android.apps.nbu.paisa.inapp.client.api.**
-keep class com.google.android.apps.nbu.paisa.inapp.client.api.** { *; }

# ---- flutter_local_notifications: শিডিউল করা রিমাইন্ডার Gson দিয়ে
#      সেভ/পড়া হয়, ক্লাসের নাম বদলে গেলে পুরনো রিমাইন্ডার হারায়
-keep class com.dexterous.** { *; }
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn com.google.gson.**

# ---- AdMob
-keep class com.google.android.gms.ads.** { *; }
-dontwarn com.google.android.gms.**

# ---- speech_to_text (ভয়েস রিমাইন্ডার)
-keep class com.csdcorp.speech_to_text.** { *; }
-dontwarn com.csdcorp.speech_to_text.**

# ---- home_widget (হোম স্ক্রিন উইজেট)
-keep class es.antonborri.home_widget.** { *; }

# ---- Flutter নিজে
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

# ---- Play Core (deferred components — Flutter খোঁজে)
-dontwarn com.google.android.play.core.**

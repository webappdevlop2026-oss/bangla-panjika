import java.io.FileInputStream
import java.util.Properties

// রিলিজ সই করার চাবি। android/key.properties ফাইলটা থাকলে সেটা দিয়ে
// সই হবে, না থাকলে আগের মতোই debug key দিয়ে — তাই এই ফাইল ছাড়াও
// `flutter run --release` আর `flutter build apk` আগের মতোই চলবে।
// ⚠️ key.properties আর .jks ফাইল কখনো git-এ বা কাউকে পাঠাবেন না।
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}
val hasReleaseKey = keystorePropertiesFile.exists()

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.bangla_panjika_native"
    // Google Play: নতুন অ্যাপ ও আপডেট Android 16 (API 36) লক্ষ্য করতে হবে
    // (৩১ অগাস্ট ২০২৬ থেকে বাধ্যতামূলক)। তাই Flutter-এর ডিফল্টের উপর
    // নির্ভর না করে সরাসরি বসানো হলো।
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // flutter_local_notifications-এর জন্য দরকার: পুরনো Android ভার্সনেও
        // নতুন Java তারিখ/সময়ের API চালানোর ব্যবস্থা (core library desugaring)
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // ⚠️ এটা ক্লায়েন্টের পুরনো অ্যাপের প্যাকেজ নাম। Play Store এই নাম
        // দেখেই বোঝে কোন অ্যাপের আপডেট — এক অক্ষর এদিক-ওদিক হলে আপলোড
        // আটকে যাবে ("package name does not match")। কখনো বদলাবেন না।
        //
        // নিচের namespace ("com.example...") ইচ্ছে করেই বদলানো হয়নি —
        // ওটা শুধু Kotlin/Java কোডের ভেতরের নাম, Play Store ওটা দেখে না।
        applicationId = "com.shripanchang.calendar"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            if (hasReleaseKey) {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            // key.properties থাকলে আসল চাবি দিয়ে সই, নাহলে আগের মতোই
            // debug key (তখন Play Store-এ আপলোড করা যাবে না, কিন্তু
            // ফোনে টেস্ট করা যাবে)।
            signingConfig = if (hasReleaseKey) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }

            // ⚠️ কোড সংকোচন (R8) বন্ধ রাখা হয়েছে।
            // চালু থাকলে release APK খুললেই বন্ধ হয়ে যাচ্ছিল — R8
            // Razorpay ও নোটিফিকেশন প্লাগিনের reflection-নির্ভর ক্লাসগুলো
            // "অব্যবহৃত" ভেবে ছেঁটে ফেলছিল, debug-এ এটা হয় না বলে ধরা
            // পড়েনি। APK সামান্য বড় হবে (~৫ MB), কিন্তু চলবে।
            //
            // পরে আবার চালু করতে চাইলে: নিচের দুটো true করে
            // proguard-rules.pro যোগ করুন (ফাইলটা তৈরি করাই আছে) —
            //   isMinifyEnabled = true
            //   isShrinkResources = true
            //   proguardFiles(
            //       getDefaultProguardFile("proguard-android-optimize.txt"),
            //       "proguard-rules.pro",
            //   )
            // তারপর release APK ফোনে ইনস্টল করে খুলে দেখে নেবেন।
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

dependencies {
    // উপরের desugaring চালু রাখতে এই লাইব্রেরিটি লাগে
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

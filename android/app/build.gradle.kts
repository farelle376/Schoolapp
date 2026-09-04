plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.school_app"
    // ⚠️ AGP/Kotlin sont déjà déclarés (versions modernes) dans
    // settings.gradle.kts via le bloc `plugins {}`. La ligne
    // `compileSdkVersion 34` (syntaxe Groovy) et le bloc `kotlinOptions {
    // jvmTarget = '11' }` (littéral char invalide en Kotlin, '11' fait 2
    // caractères) qui étaient ici en double faisaient planter la
    // compilation du script Kotlin lui-même — supprimés, redondants avec
    // compileSdk ci-dessous et le bloc compilerOptions plus bas.
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.school_app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}
tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
    // Utilisation de la nouvelle DSL compilerOptions
    compilerOptions {
        jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_11)
        languageVersion.set(org.jetbrains.kotlin.gradle.dsl.KotlinVersion.KOTLIN_1_8)
        apiVersion.set(org.jetbrains.kotlin.gradle.dsl.KotlinVersion.KOTLIN_1_8)
    }
}
// ⚠️ L'ancien bloc `buildscript { ... classpath 'com.android.tools.build:gradle:7.4.2' ... }`
// qui était ici redéclarait AGP 7.4.2 / Kotlin 1.9.22 en syntaxe Groovy
// invalide dans ce fichier .kts (chaînes entre apostrophes simples,
// `ext.kotlin_version` non défini) — en plus d'être en conflit direct
// avec AGP 8.11.1 / Kotlin 2.2.20 déjà déclarés proprement dans
// settings.gradle.kts (bloc `plugins {}`, méthode moderne recommandée
// par Flutter). Supprimé : une seule déclaration doit exister.
flutter {
    source = "../.."
}

import java.util.Properties

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics")
    // END: FlutterFire Configuration
    id("org.jetbrains.kotlin.android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = project.layout.projectDirectory.file("../key.properties").asFile
if (keystorePropertiesFile.exists()) {
    keystorePropertiesFile.inputStream().use { keystoreProperties.load(it) }
}

fun signingProperty(name: String): String? {
    val placeholderValues = setOf("your_store_password", "your_key_password")
    return keystoreProperties.getProperty(name)
        ?.trim()
        ?.takeIf { it.isNotEmpty() && it !in placeholderValues }
}

fun requiredSigningProperty(name: String): String {
    return signingProperty(name)
        ?: error(
            "Missing or placeholder release signing property '$name' in ${keystorePropertiesFile.absolutePath}. " +
                "Replace template values like your_store_password with your real keystore password. " +
                "Loaded keys: ${keystoreProperties.stringPropertyNames().sorted()}. " +
                "Raw value length: ${keystoreProperties.getProperty(name)?.trim()?.length ?: "null"}. " +
                "Is template: ${keystoreProperties.getProperty(name)?.trim() in setOf("your_store_password", "your_key_password")}"
        )
}

val releaseKeyAlias = requiredSigningProperty("keyAlias")
val releaseStoreFile = requiredSigningProperty("storeFile")
val releaseStorePassword = requiredSigningProperty("storePassword")
val releaseKeyPassword = signingProperty("keyPassword") ?: releaseStorePassword
val releaseStoreType = signingProperty("storeType") ?: "pkcs12"

android {
    namespace = "com.example.instru_connect"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        applicationId = "com.example.instru_connect"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        resourceConfigurations += listOf("en")
        manifestPlaceholders["appAuthRedirectScheme"] = "com.example.instru_connect"
    }

    packaging {
        resources {
            excludes += "/META-INF/{AL2.0,LGPL2.1}"
        }
    }

    signingConfigs {
        create("release") {
            keyAlias = releaseKeyAlias
            storeFile = file(releaseStoreFile)
            storePassword = releaseStorePassword
            keyPassword = releaseKeyPassword
            storeType = releaseStoreType
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
    }
}

flutter {
    source = "../.."
}

kotlin {
    compilerOptions {
        jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_11)
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

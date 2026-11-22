import java.util.Properties
import java.io.FileInputStream
import org.jetbrains.kotlin.gradle.dsl.JvmTarget

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    // Required while android.builtInKotlin=false (unmigrated plugins still use KGP).
    id("org.jetbrains.kotlin.android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com5vnetwork.umi"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "29.0.14206865"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // Flag to enable support for the new language APIs
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
            applicationId = "com5vnetwork.umi"
            // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 26
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = keystoreProperties["storeFile"]?.let { file(it) }
            storePassword = keystoreProperties["storePassword"] as String
        }
    }

    buildTypes {
        release  {
            signingConfig = signingConfigs.getByName("release")
        }
    }

    // AGP 9 disables resValues by default; flavors use resValue for app_name.
    buildFeatures {
        resValues = true
    }

    flavorDimensions += "default"
    productFlavors {
        create("dev") {
            dimension = "default"
            resValue(
                type = "string",
                name = "app_name",
                value = "V")
            applicationIdSuffix = ".dev"
        }
        create("staging") {
            dimension = "default"
            resValue(
                type = "string",
                name = "app_name",
                value = "X")
            applicationIdSuffix = ".staging"
        }
        create("production") {
            dimension = "default"
            resValue(
                type = "string",
                name = "app_name",
                value = "UmiVPN")
            applicationIdSuffix = ""
        }
        create("apk") {
            dimension = "default"
            resValue(
                type = "string",
                name = "app_name",
                value = "UmiVPN")
            applicationIdSuffix = ""
        }
    }

    lint {
        disable += "NullSafeMutableLiveData"
    }
}

kotlin {
    compilerOptions {
        jvmTarget.set(JvmTarget.JVM_17)
    }
}

flutter {
    source = "../.."
}

repositories {
    flatDir {
        dirs("../../../umivpn-plugin/tm_android/android/libs")
    }
}

dependencies {
    implementation(files("../../../umivpn-plugin/tm_android/android/libs/x.aar"))
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    // implementation("com.google.android.play:integrity:1.4.0")
    // implementation(name: "x", ext: "aar")
}
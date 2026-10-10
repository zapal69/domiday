import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release signing comes from android/key.properties — a local file ignored by
// Git (see android/key.properties.example and README, «Подпись»). It must
// never fall back to the debug key: a release signed by a random debug
// certificate cannot be installed over the owner's existing app.
val keyPropertiesFile: File = rootProject.file("key.properties")
val keyProperties = Properties().apply {
    if (keyPropertiesFile.exists()) {
        FileInputStream(keyPropertiesFile).use { load(it) }
    }
}
val missingSigningKeys = listOf("storeFile", "keyAlias", "storePassword", "keyPassword")
    .filter { keyProperties.getProperty(it).isNullOrBlank() }
val signingStoreFile: File? = keyProperties.getProperty("storeFile")
    ?.takeIf { it.isNotBlank() }
    ?.let { rootProject.file(it) }
val releaseSigningReady =
    keyPropertiesFile.exists() && missingSigningKeys.isEmpty() && signingStoreFile?.exists() == true

fun releaseSigningError(): String = when {
    !keyPropertiesFile.exists() ->
        "Release signing is not configured: ${keyPropertiesFile.path} not found. " +
            "Copy android/key.properties.example to android/key.properties and fill it in."
    missingSigningKeys.isNotEmpty() ->
        "Release signing is incomplete: ${keyPropertiesFile.path} lacks " +
            missingSigningKeys.joinToString(", ") + "."
    else ->
        "Release signing keystore not found: ${signingStoreFile?.path} " +
            "(storeFile in ${keyPropertiesFile.path})."
}

android {
    namespace = "com.domiday.domiday"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // flutter_local_notifications требует desugaring java.time.
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.domiday.domiday"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        // Один универсальный APK только для 64-битного ARM: все телефоны
        // после 2015 года. 32-битный ARM и x86_64 (эмуляторы) не включаем —
        // они утраивали размер (58,7 → ~21 МБ). Решение владельца, 0.12.2.
        ndk {
            abiFilters.clear()
            abiFilters.add("arm64-v8a")
        }
    }

    signingConfigs {
        if (releaseSigningReady) {
            create("release") {
                storeFile = signingStoreFile
                storeType = keyProperties.getProperty("storeType")?.takeIf { it.isNotBlank() } ?: "PKCS12"
                keyAlias = keyProperties.getProperty("keyAlias")
                storePassword = keyProperties.getProperty("storePassword")
                keyPassword = keyProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            // No debug fallback: without key.properties the release package
            // task fails with a clear message (see below). Analysis, tests and
            // debug builds do not need release signing.
            signingConfig = if (releaseSigningReady) signingConfigs.getByName("release") else null
        }
    }
}

// Fail fast on any release packaging instead of silently producing an
// unsigned APK/bundle.
tasks.configureEach {
    if (name.contains("Release") && name.startsWith("package")) {
        doFirst {
            if (!releaseSigningReady) throw GradleException(releaseSigningError())
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
    // FileProvider для «Поделиться итогами года» (уже есть транзитивно
    // через плагины; явно — чтобы сборка не зависела от их версий).
    implementation("androidx.core:core:1.16.0")
}

import java.util.Base64
import java.util.Properties

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// `--dart-define` values reach Gradle as comma-separated base64 KEY=VALUE pairs.
val dartDefines: Map<String, String> =
    (project.findProperty("dart-defines") as String?)
        .orEmpty()
        .split(",")
        .filter { it.isNotBlank() }
        .mapNotNull { encoded ->
            val pair = String(Base64.getDecoder().decode(encoded), Charsets.UTF_8)
            val split = pair.indexOf('=')
            if (split <= 0) null else pair.substring(0, split) to pair.substring(split + 1)
        }
        .toMap()

// Ads: see docs/setup/ads.md. Off unless ADS_ENABLED=true.
val adsEnabled = dartDefines["ADS_ENABLED"] == "true"
val adsMode = dartDefines["ADS_MODE"].orEmpty()
val googleSamplePublisher = "ca-app-pub-3940256099942544"
val googleSampleAndroidAppId = "$googleSamplePublisher~3347511713"
val admobAppId: String =
    when {
        !adsEnabled -> ""
        adsMode == "test" -> googleSampleAndroidAppId
        else -> dartDefines["ADMOB_ANDROID_APP_ID"].orEmpty().trim()
    }
val admobConfigProblem: String? =
    when {
        !adsEnabled -> null
        adsMode != "test" && adsMode != "live" ->
            "ADS_MODE must be test or live when ADS_ENABLED=true."
        !Regex("""^ca-app-pub-\d{16}~\d{10}$""").matches(admobAppId) ->
            "ADMOB_ANDROID_APP_ID must be an Android AdMob App ID " +
                "(ca-app-pub-<16 digits>~<10 digits>), not a banner ad unit ID."
        else -> null
    }
val admobReleaseProblem: String? =
    when {
        admobConfigProblem != null -> admobConfigProblem
        !adsEnabled -> null
        adsMode == "test" -> "ADS_MODE=test uses Google sample IDs and cannot be released."
        admobAppId.startsWith(googleSamplePublisher) ->
            "ADMOB_ANDROID_APP_ID is Google's sample App ID and cannot be released."
        else -> null
    }

// Release signing: loads from key.properties (Play Console upload key) or
// falls back to environment variables (CI / QA builds).
val keyPropertiesFile = rootProject.file("key.properties")
val keyProperties = Properties()
if (keyPropertiesFile.exists()) {
    keyProperties.load(keyPropertiesFile.inputStream())
}

val releaseKeystore = keyProperties.getProperty("storeFile")
    ?: providers.environmentVariable("REGIDAY_KEYSTORE").orNull
val releaseKeyAlias = keyProperties.getProperty("keyAlias")
    ?: providers.environmentVariable("REGIDAY_KEY_ALIAS").orNull
val releaseKeystorePassword = keyProperties.getProperty("storePassword")
    ?: providers.environmentVariable("REGIDAY_KEYSTORE_PASSWORD").orNull
val releaseKeyPassword = keyProperties.getProperty("keyPassword")
    ?: releaseKeystorePassword
val hasReleaseSigning =
    !releaseKeystore.isNullOrBlank() &&
        !releaseKeyAlias.isNullOrBlank() &&
        !releaseKeystorePassword.isNullOrBlank()

android {
    namespace = "com.registry.vault"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.registry.vault"
        multiDexEnabled = true
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
        manifestPlaceholders["admobAppId"] = admobAppId
    }

    signingConfigs {
        if (hasReleaseSigning) {
            create("release") {
                storeFile = file(releaseKeystore!!)
                storePassword = releaseKeystorePassword
                keyAlias = releaseKeyAlias
                keyPassword = releaseKeyPassword
            }
        }
    }

    buildTypes {
        release {
            signingConfig =
                if (hasReleaseSigning) {
                    signingConfigs.getByName("release")
                } else {
                    // Keeps `flutter run --release` working locally. Such an
                    // APK carries the debug certificate and is not a QA or
                    // store build.
                    logger.warn(
                        "WARNING: REGIDAY_KEYSTORE is not set. The release build is signed " +
                            "with the DEBUG key. Use tool/android/build_release_qa_apk.sh " +
                            "for a release-signed APK.",
                    )
                    signingConfigs.getByName("debug")
                }
        }
    }
}

androidComponents {
    onVariants { variant ->
        variant.sources.manifests.addStaticManifestFile(
            if (adsEnabled) "src/adsOn/AndroidManifest.xml" else "src/adsOff/AndroidManifest.xml",
        )
    }
}

val validateAdmobConfig by tasks.registering {
    val problem = admobConfigProblem
    doLast {
        if (problem != null) {
            throw GradleException(problem)
        }
    }
}

val validateAdmobReleaseConfig by tasks.registering {
    val problem = admobReleaseProblem
    doLast {
        if (problem != null) {
            throw GradleException(problem)
        }
    }
}

tasks.matching { it.name == "preBuild" }.configureEach {
    dependsOn(validateAdmobConfig)
}

tasks.matching { it.name == "preReleaseBuild" }.configureEach {
    dependsOn(validateAdmobReleaseConfig)
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
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    // play-services-ads 25.4.0 (google_mobile_ads) pulls work-runtime 2.7.0,
    // whose WorkDatabase R8 breaks in release: the app crashes at startup even
    // with ads off. See googleads/googleads-mobile-flutter#1444.
    implementation("androidx.work:work-runtime:2.11.2")
    testImplementation("junit:junit:4.13.2")
}

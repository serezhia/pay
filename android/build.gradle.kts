import java.util.Properties

group = "com.yandex.pay.quickpay.flutter"
version = "1.0.0"

val localProperties = Properties()
val localPropertiesFile = rootProject.file("local.properties")
if (localPropertiesFile.exists()) {
    localPropertiesFile.inputStream().use { localProperties.load(it) }
}
val useLocalMaven = localProperties.getProperty("useLocalMaven")?.toBoolean() ?: false

val yandexRepoPath = file("repo").absolutePath

rootProject.allprojects {
    repositories {
        maven {
            url = uri(yandexRepoPath)
            content {
                includeGroup("com.yandex.pay")
                includeGroup("com.yandex.fintechsdk")
            }
        }
        if (useLocalMaven) {
            mavenLocal()
        }
        google()
        mavenCentral()
    }
}

plugins {
    id("com.android.library")
    id("org.jetbrains.kotlin.android")
}

android {
    lint {
       disable += "NullSafeMutableLiveData"
    }
    namespace = "com.yandex.pay.quickpay.flutter"
    compileSdk = 35

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_1_8.toString()
    }

    defaultConfig {
        minSdk = 24
        consumerProguardFiles("proguard-rules.pro")
    }
}

dependencies {
    implementation("org.jetbrains.kotlin:kotlin-stdlib-jdk7:1.7.10")
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.7.3")
    implementation("com.google.android.material:material:1.11.0")
    implementation("com.yandex.pay:quickpay:1.0.0")
}

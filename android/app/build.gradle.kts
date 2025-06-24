plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

import java.util.Properties
import java.io.FileInputStream

// Define las propiedades del keystore.
// Estas propiedades solo se cargarán si el archivo key.properties existe.
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
var hasSigningConfig = false // Bandera para saber si el archivo de propiedades existe y se cargó

if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
    hasSigningConfig = true // Establece la bandera a true
}


android {
    // Solo crea la configuración de firma 'release' si las propiedades del keystore están disponibles.
    if (hasSigningConfig) {
        signingConfigs {
            create("release") {
                // Asegúrate de que las claves existen antes de intentar usarlas,
                // usando el operador elvis para proporcionar un valor predeterminado si son null
                // aunque hasSigningConfig ya lo valida, esto es una doble seguridad.
                storeFile = file(keystoreProperties["storeFile"] as String? ?: "")
                storePassword = keystoreProperties["storePassword"] as String? ?: ""
                keyAlias = keystoreProperties["keyAlias"] as String? ?: ""
                keyPassword = keystoreProperties["keyPassword"] as String? ?: ""
            }
        }
    }

    namespace = "com.marceloemmott.novacalc"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973" // <--- ¡ÚLTIMA CORRECCIÓN AQUÍ! Fija la versión NDK
    
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
    applicationId = "com.marceloemmott.novacalc"
    minSdk = flutter.minSdkVersion
    targetSdk = flutter.targetSdkVersion
    versionCode = 4
    versionName = "1.0.4"
}


    buildTypes {
        getByName("release") {
            // Aplica la configuración de firma 'release' SOLO si se pudo crear
            if (hasSigningConfig) {
                signingConfig = signingConfigs.getByName("release")
            } else {
                // Opcional: imprimir una advertencia si la configuración de firma no se encontró
                // Esto es útil en CI/CD donde las variables de entorno podrían faltar
                println("ADVERTENCIA: key.properties no encontrado. La configuración de firma de RELEASE no se aplicará. Esto es normal para builds DEBUG.")
            }
            isMinifyEnabled = false // Considera cambiar a true para builds de producción
            isShrinkResources = false // Considera cambiar a true para builds de producción
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
        getByName("debug") {
            // No necesitas un signingConfig explícito aquí.
            // Gradle/Flutter ya usa la clave de depuración por defecto.
        }
    }
}

flutter {
    source = "../.."
}
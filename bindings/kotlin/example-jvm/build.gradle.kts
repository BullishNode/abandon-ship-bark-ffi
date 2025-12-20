plugins {
    kotlin("jvm") version "1.9.24"
    application
    id("org.jlleitschuh.gradle.ktlint") version "12.1.0" apply false
}

repositories {
    mavenCentral()
}

dependencies {
    // Bark JVM library (local module from parent directory)
    implementation(project(":bark-jvm"))

    // Kotlin standard library
    implementation("org.jetbrains.kotlin:kotlin-stdlib:1.9.24")
}

application {
    mainClass.set("MainKt")
}

kotlin {
    jvmToolchain(17)
}

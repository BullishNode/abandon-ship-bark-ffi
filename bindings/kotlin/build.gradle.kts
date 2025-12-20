// Top-level build file for Bark Kotlin bindings
plugins {
    id("com.android.library") version "8.5.2" apply false
    id("org.jetbrains.kotlin.android") version "1.9.24" apply false
    kotlin("jvm") version "1.9.24" apply false
    id("org.jlleitschuh.gradle.ktlint") version "12.1.0" apply false
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        google()
        mavenCentral()
    }
}

rootProject.name = "BarkExample"
include(":app")
include(":bark-android")

// Point to the bark-android module from parent directory
project(":bark-android").projectDir = File("../bark-android")

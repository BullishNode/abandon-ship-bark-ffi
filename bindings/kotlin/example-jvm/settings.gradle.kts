dependencyResolutionManagement {
    repositories {
        mavenCentral()
    }
}

rootProject.name = "bark-jvm-example"
include(":bark-jvm")

// Point to the bark-jvm module from parent directory
project(":bark-jvm").projectDir = File("../bark-jvm")

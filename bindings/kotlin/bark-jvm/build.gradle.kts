plugins {
    kotlin("jvm")
    `java-library`
    id("org.jlleitschuh.gradle.ktlint")
    `maven-publish`
    signing
}

java {
    sourceCompatibility = JavaVersion.VERSION_17
    targetCompatibility = JavaVersion.VERSION_17

    withSourcesJar()
    withJavadocJar()
}

kotlin {
    jvmToolchain(17)
}

dependencies {
    // JNA for native library loading
    implementation("net.java.dev.jna:jna:5.14.0")

    // Kotlin standard library
    implementation("org.jetbrains.kotlin:kotlin-stdlib:1.9.24")

    // Coroutines for async operations
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-core:1.8.1")

    // Testing
    testImplementation("org.junit.jupiter:junit-jupiter:5.10.2")
}

tasks.test {
    useJUnitPlatform()
    testLogging {
        events("passed", "skipped", "failed")
        showStandardStreams = false
    }
}

// Copy Kotlin source files to src/main/kotlin
sourceSets {
    main {
        kotlin.srcDirs("src/main/kotlin")
        resources.srcDirs("src/main/resources")
    }
}

// Handle duplicate resources
tasks.processResources {
    duplicatesStrategy = DuplicatesStrategy.INCLUDE
}

// ktlint configuration
ktlint {
    filter {
        exclude("**/uniffi/**") // Don't lint generated code
    }
}

publishing {
    publications {
        create<MavenPublication>("maven") {
            from(components["java"])

            groupId = "tech.second.bark"
            artifactId = "bark-jvm"
            version = project.findProperty("VERSION_NAME") as String? ?: "0.1.0-beta.4"

            pom {
                name.set("Bark JVM")
                description.set("Bark - Ark Wallet for Bitcoin (Kotlin/JVM Bindings)")
                url.set("https://gitlab.com/ark-bitcoin/bark-ffi")

                licenses {
                    license {
                        name.set("CC0-1.0")
                        url.set("https://creativecommons.org/publicdomain/zero/1.0/")
                    }
                }

                developers {
                    developer {
                        id.set("second-tech")
                        name.set("Team Second")
                        email.set("hello@second.tech")
                    }
                }

                scm {
                    url.set("https://gitlab.com/ark-bitcoin/bark-ffi")
                    connection.set("scm:git:git://gitlab.com/ark-bitcoin/bark-ffi.git")
                    developerConnection.set("scm:git:ssh://git@gitlab.com/ark-bitcoin/bark-ffi.git")
                }
            }
        }
    }
}

// Signing configuration (optional, for Maven Central)
// signing {
//     val signingKey = findProperty("SIGNING_KEY") as String?
//     val signingPassword = findProperty("SIGNING_PASSWORD") as String?
//     if (signingKey != null && signingPassword != null) {
//         useInMemoryPgpKeys(signingKey, signingPassword)
//         sign(publishing.publications["maven"])
//     }
// }

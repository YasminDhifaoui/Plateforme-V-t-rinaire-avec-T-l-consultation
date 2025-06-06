buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        // These are the dependencies you need to add
        classpath("com.android.tools.build:gradle:7.3.0") // Use your current Android Gradle Plugin version
        classpath("com.google.gms:google-services:4.3.15") // Use latest version from Firebase docs
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

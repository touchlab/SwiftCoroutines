buildscript {
    repositories {
        mavenCentral()
    }
    dependencies {
        classpath("co.touchlab:kotlinnativecocoapods:0.10")
        classpath(kotlin("gradle-plugin", "1.3.72"))
    }
}

allprojects {
    repositories {
        mavenCentral()
    }
}

tasks.register("clean", Delete::class) {
    delete(rootProject.buildDir)
}

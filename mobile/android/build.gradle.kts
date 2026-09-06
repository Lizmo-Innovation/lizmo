allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
// Every plugin module compiles against the same API level as the app.
//
// file_picker pins compileSdk 34 while the flutter_plugin_android_lifecycle it
// depends on now demands 36, so the build fails inside the plugin rather than
// on anything written here. Raising it for the app alone does not help: a
// module's own compileSdk is its own.
//
// Set from plugins.withId rather than afterEvaluate, because the
// evaluationDependsOn below has already evaluated these projects by then --
// which is a hard error, not a silent no-op.
//
// compileSdk only decides which APIs may be referenced at build time. minSdk
// and targetSdk are untouched, so which phones can install the app and which
// runtime behaviours it opts into are both unchanged.
subprojects {
    // Registered before evaluationDependsOn below, which forces every
    // subproject to evaluate -- an afterEvaluate added after that point throws
    // "project is already evaluated" rather than quietly doing nothing.
    afterEvaluate {
        extensions.findByName("android")?.let { android ->
            if (android is com.android.build.gradle.LibraryExtension) {
                android.compileSdk = 36
            }
        }
    }

    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

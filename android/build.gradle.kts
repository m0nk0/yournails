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

    // --- ИСПРАВЛЕНИЕ ОШИБКИ compileSdk ---
    // Умный блок: находим любой Android-плагин и принудительно ставим SDK 36
    project.afterEvaluate {
        val androidExt = extensions.findByName("android") ?: return@afterEvaluate
        
        try {
            // Для новых версий AGP (8.0+)
            val method = androidExt.javaClass.getMethod("setCompileSdk", Int::class.java)
            method.invoke(androidExt, 36)
        } catch (e: NoSuchMethodException) {
            try {
                // Для старых версий (до 8.0)
                val method = androidExt.javaClass.getMethod("setCompileSdkVersion", Int::class.java)
                method.invoke(androidExt, 36)
            } catch (e: NoSuchMethodException) {
                val method = androidExt.javaClass.getMethod("setCompileSdkVersion", String::class.java)
                method.invoke(androidExt, "36")
            }
        }
    }
    // -------------------------------------

    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
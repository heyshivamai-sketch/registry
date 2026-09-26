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
subprojects {
    project.evaluationDependsOn(":app")
}

// file_picker 8.3.7 still declares compileSdk 34. flutter_plugin_android_lifecycle
// now requires API 36. finalizeDsl runs after that plugin's android block.
subprojects {
    pluginManager.withPlugin("com.android.library") {
        val components = extensions.findByName("androidComponents") ?: return@withPlugin
        val finalize = components.javaClass.methods.firstOrNull { method ->
            method.name == "finalizeDsl" &&
                method.parameterCount == 1 &&
                Action::class.java.isAssignableFrom(method.parameterTypes[0])
        } ?: return@withPlugin
        val callback = object : Action<Any> {
            override fun execute(extension: Any) {
                val current = extension.javaClass
                    .getMethod("getCompileSdk")
                    .invoke(extension) as? Int
                if (current == null || current < 36) {
                    extension.javaClass
                        .getMethod("setCompileSdk", Integer::class.java)
                        .invoke(extension, 36)
                }
            }
        }
        finalize.invoke(components, callback)
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

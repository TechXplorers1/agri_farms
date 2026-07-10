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

subprojects {
    val configureNdk = Action<Project> {
        val androidExtension = extensions.findByName("android")
        if (androidExtension != null) {
            try {
                val method = androidExtension.javaClass.getMethod("setNdkVersion", String::class.java)
                method.invoke(androidExtension, "28.2.13676358")
                println("Successfully set ndkVersion to 28.2.13676358 on project ${project.name}")
            } catch (e: Exception) {
                try {
                    val setter = androidExtension.javaClass.getMethods().firstOrNull { it.name == "setNdkVersion" }
                    setter?.invoke(androidExtension, "28.2.13676358")
                    println("Successfully set ndkVersion to 28.2.13676358 on project ${project.name} via matching name")
                } catch (e2: Exception) {
                    println("Failed to set ndkVersion on project ${project.name}: ${e2.message}")
                }
            }
            try {
                val method = androidExtension.javaClass.getMethods().firstOrNull { it.name == "compileSdkVersion" || it.name == "setCompileSdkVersion" }
                if (method != null) {
                    if (method.parameterTypes[0] == Int::class.javaPrimitiveType || method.parameterTypes[0] == java.lang.Integer::class.java) {
                        method.invoke(androidExtension, 36)
                    } else if (method.parameterTypes[0] == String::class.java) {
                        method.invoke(androidExtension, "android-36")
                    }
                    println("Successfully set compileSdkVersion to 36 on project ${project.name}")
                }
            } catch (e: Exception) {
                println("Failed to set compileSdkVersion on project ${project.name}: ${e.message}")
            }
            try {
                val method = androidExtension.javaClass.getMethods().firstOrNull { it.name == "buildToolsVersion" || it.name == "setBuildToolsVersion" }
                if (method != null && method.parameterTypes[0] == String::class.java) {
                    method.invoke(androidExtension, "36.1.0")
                    println("Successfully set buildToolsVersion to 36.1.0 on project ${project.name}")
                }
            } catch (e: Exception) {
                println("Failed to set buildToolsVersion on project ${project.name}: ${e.message}")
            }
        }
    }
    if (state.executed) {
        configureNdk.execute(this)
    } else {
        afterEvaluate {
            configureNdk.execute(this)
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

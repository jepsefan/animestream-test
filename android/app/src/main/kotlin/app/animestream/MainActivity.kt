package app.animestream

import dalvik.system.PathClassLoader
import dalvik.system.DexClassLoader
import dalvik.system.DexFile
import android.widget.Toast
import android.content.pm.PackageManager
import android.content.pm.FeatureInfo
import android.os.Build
import android.os.Looper
import android.os.Handler
import androidx.annotation.NonNull

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel


class MainActivity: FlutterActivity() {

    private lateinit var channel: MethodChannel
    private lateinit var extensionChannel: MethodChannel
    private lateinit var assRenderChannel: MethodChannel
    private val externalAssRenderer = ExternalAssRenderer()

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        externalAssRenderer.attach(flutterEngine.renderer)
        assRenderChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "animestream.app/assrender")
        assRenderChannel.setMethodCallHandler(externalAssRenderer)
        extensionChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "animestream.app/aniyomi_extensions")
        extensionChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "inspectExtensionClass" -> {
                    val packageName = call.argument<String>("packageName")
                    if (packageName.isNullOrBlank()) {
                        result.error("INVALID_PACKAGE", "Missing packageName", null)
                    } else {
                        try {
                            result.success(inspectExtensionClass(packageName))
                        } catch (e: Exception) {
                            result.error("CLASS_INSPECTION_FAILED", e.toString(), null)
                        }
                    }
                }
                "testExtensionInstantiation" -> {
                    val packageName = call.argument<String>("packageName")
                    if (packageName.isNullOrBlank()) {
                        result.error("INVALID_PACKAGE", "Missing packageName", null)
                    } else {
                        try {
                            result.success(inspectExtensionClass(packageName, true))
                        } catch (e: Throwable) {
                            result.error("INSTANTIATION_TEST_FAILED", e.toString(), null)
                        }
                    }
                }
                "testExtensionSearch" -> {
                    val pkg = call.argument<String>("packageName")
                    val query = call.argument<String>("query")
                    if (pkg.isNullOrBlank() || query.isNullOrBlank()) {
                        result.error("INVALID_SEARCH", "Missing packageName or query", null)
                    } else {
                        Thread {
                            val data = ExtensionSearchProbe(this).search(pkg, query)
                            runOnUiThread { result.success(data) }
                        }.start()
                    }
                }
                "testExtensionEpisodes" -> {
                    val pkg = call.argument<String>("packageName")
                    val url = call.argument<String>("sourceUrl")
                    val title = call.argument<String>("sourceTitle")
                    if (pkg.isNullOrBlank() || url.isNullOrBlank() || title.isNullOrBlank()) {
                        result.error("INVALID_SELECTION", "Missing package name, URL or title", null)
                    } else {
                        Thread {
                            val response = ExtensionEpisodeProbe(this).load(pkg, url, title)
                            runOnUiThread { result.success(response) }
                        }.start()
                    }
                }
                "listInstalledExtensions" -> {
                    try {
                        result.success(listInstalledAnimeExtensions())
                    } catch (e: Exception) {
                        result.error("EXTENSION_SCAN_FAILED", e.message, null)
                    }
                }
                else -> result.notImplemented()
            }
        }
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "animestream.app/utils")
        channel.setMethodCallHandler {
                call, result ->
            when (call.method) {
                "showToast" -> {
                val message = call.argument<String>("message")
                if(message == null || message.length == 0) {
                    result.error("MESSAGE_NOT_PROVIDED", "MESSAGE IS NULL OR EMPTY", null)
                }
                showToast(message ?: "")
                }
                else -> result.notImplemented()
            }
        }
    }

    // Metadata-only discovery. No third-party APK code is executed here.
    // Android 11+ package visibility is declared in AndroidManifest.xml.
    private fun listInstalledAnimeExtensions(): List<Map<String, Any?>> {
        val pm = packageManager
        val flags = (PackageManager.GET_META_DATA or PackageManager.GET_CONFIGURATIONS).toLong()
        val packages = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            pm.getInstalledPackages(PackageManager.PackageInfoFlags.of(flags))
        } else {
            @Suppress("DEPRECATION")
            pm.getInstalledPackages(PackageManager.GET_META_DATA or PackageManager.GET_CONFIGURATIONS)
        }
        return packages.mapNotNull { pkg ->
            val info = pkg.applicationInfo ?: return@mapNotNull null
            val metadata = info.metaData
            val sourceClass = metadata?.getString("tachiyomi.animeextension.class")
            val sourceFactory = metadata?.getString("tachiyomi.animeextension.factory")
            val hasExtensionFeature = pkg.reqFeatures?.any {
                it.name == "tachiyomi.animeextension"
            } == true
            if (!hasExtensionFeature && sourceClass.isNullOrBlank() && sourceFactory.isNullOrBlank()) return@mapNotNull null
            mapOf(
                "packageName" to pkg.packageName,
                "name" to pm.getApplicationLabel(info).toString(),
                "version" to (pkg.versionName ?: ""),
                "sourceClass" to sourceClass,
                "sourceFactory" to sourceFactory,
                "hasExtensionFeature" to hasExtensionFeature,
                "status" to "detected_not_loaded"
            )
        }
    }

    // Diagnostic only: enumerate APK DEX classes and resolve without initialization.
    // This does not instantiate or execute extension source classes.
    private fun inspectExtensionClass(packageName: String, attemptInstantiation: Boolean = false): Map<String, Any?> {
        val pm = packageManager
        val info = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            pm.getApplicationInfo(packageName, PackageManager.ApplicationInfoFlags.of(PackageManager.GET_META_DATA.toLong()))
        } else {
            @Suppress("DEPRECATION")
            pm.getApplicationInfo(packageName, PackageManager.GET_META_DATA)
        }
        val rawClass = info.metaData?.getString("tachiyomi.animeextension.class")
        val rawFactory = info.metaData?.getString("tachiyomi.animeextension.factory")
        if (rawClass.isNullOrBlank() && rawFactory.isNullOrBlank()) return mapOf("status" to "no_source_class")
        val declaredEntries = listOfNotNull(rawClass, rawFactory)
            .flatMap { it.split(';', ',').map { name -> name.trim() }.filter { name -> name.isNotEmpty() } }
            .map { name -> if (name.startsWith(".")) packageName + name else name }.distinct()
        val expected = declaredEntries.first()
        val apkPaths = listOfNotNull(info.sourceDir) + (info.splitSourceDirs?.toList() ?: emptyList())
        val classes = mutableListOf<String>()
        val scanErrors = mutableListOf<String>()
        val dexInventory = mutableListOf<String>()
        for (apk in apkPaths) {
            try {
                val dex = DexFile(apk)
                try {
                    val names = dex.entries()
                    var count = 0
                    var exactFound = false
                    while (names.hasMoreElements()) {
                        val name = names.nextElement()
                        classes.add(name)
                        count++
                        if (name == expected) exactFound = true
                    }
                    dexInventory.add("${apk.substringAfterLast('/')}: $count classes, declaredClassPresent=$exactFound")
                } finally {
                    dex.close()
                }
            } catch (e: Throwable) {
                scanErrors.add("${apk.substringAfterLast('/')}: ${e.javaClass.simpleName}: ${e.message}")
            }
        }
        val candidates = classes.filter { name -> declaredEntries.any { entry -> name == entry || name.substringAfterLast('.') == entry.substringAfterLast('.') } }.take(25)
        val target = declaredEntries.firstOrNull { it in classes } ?: candidates.firstOrNull()
        val (dexClassInfo, dependencyScanErrors) = ExtensionDexInspector.inspect(apkPaths, expected)
        val availableClasses = classes.toSet()
        val base = mutableMapOf<String, Any?>(
            "dexInspectionStatus" to if (dexClassInfo != null) "class_definition_found" else "class_definition_not_found",
            "dexSuperclass" to (dexClassInfo?.superClass ?: "(not available)"),
            "dexInterfaces" to (dexClassInfo?.interfaces?.joinToString(", ")?.ifEmpty { "(none)" } ?: "(not available)"),
            "dexClassLocation" to (dexClassInfo?.source ?: "(not available)"),
            "dexMissingDirectDependencies" to listOfNotNull(dexClassInfo?.superClass)
                .plus(dexClassInfo?.interfaces ?: emptyList())
                .filter { it !in availableClasses && !it.startsWith("java.") &&
                    !it.startsWith("javax.") && !it.startsWith("android.") &&
                    !it.startsWith("kotlin.") }.joinToString(", "),
            "dexDependencyScanErrors" to dependencyScanErrors.joinToString("\n").ifEmpty { "(none)" },

            "className" to expected,
            "dexClassCount" to classes.size,
            "declaredClassInDex" to (expected in classes),
            "dexInventory" to dexInventory.joinToString("\\n"),
            "declaredClass" to rawClass,
            "declaredFactory" to rawFactory,
            "declaredEntryPoints" to declaredEntries.joinToString(", "),
            "entryPointsInDex" to declaredEntries.filter { it in classes }.joinToString(", "),
            "extensionPackageClasses" to classes.filter { it.startsWith(packageName) }.take(30).joinToString(", "),
            "apkCount" to apkPaths.size,
            "apkFiles" to apkPaths.map { it.substringAfterLast('/') }.joinToString(", "),
            "dexScanErrors" to scanErrors.joinToString("\\n"),
            "candidates" to candidates.joinToString(", "),
            "classInDex" to (expected in classes),
            "hostApiPresent" to try {
                Class.forName("eu.kanade.tachiyomi.animesource.AnimeSource", false, javaClass.classLoader)
                true
            } catch (_: Throwable) { false }
        )
        // Walk the in-APK superclass chain (including obfuscated names such as
        // "i") and its declared interfaces. Metadata-only: no class execution.
        val hierarchy = mutableListOf<String>()
        val hierarchyErrors = mutableListOf<String>()
        val transitiveMissing = linkedSetOf<String>()
        val visited = mutableSetOf<String>()
        val pending = ArrayDeque<String>()
        if (dexClassInfo != null) pending.add(expected)
        while (pending.isNotEmpty() && visited.size < 64) {
            val name = pending.removeFirst()
            if (!visited.add(name)) continue
            if (name !in availableClasses) {
                if (!name.startsWith("java.") && !name.startsWith("javax.") &&
                    !name.startsWith("android.") && !name.startsWith("kotlin.")) {
                    transitiveMissing.add(name)
                }
                continue
            }
            val (definition, errors) = ExtensionDexInspector.inspect(apkPaths, name)
            if (definition == null) {
                hierarchyErrors.add("$name: ${errors.joinToString("; ")}")
                continue
            }
            val parents = listOfNotNull(definition.superClass) + definition.interfaces
            hierarchy.add("$name -> ${parents.joinToString(", ").ifEmpty { "(no parents)" }}")
            for (parent in parents) if (parent !in visited) pending.add(parent)
        }
        if (pending.isNotEmpty()) hierarchyErrors.add("Hierarchy scan capped at 64 classes")
        base["dexHierarchy"] = hierarchy.joinToString("\\n")
        base["dexTransitiveMissingDependencies"] = transitiveMissing.joinToString(", ")
            .ifEmpty { "(none found in superclass/interface chain)" }
        base["dexHierarchyScanErrors"] = hierarchyErrors.joinToString("\\n").ifEmpty { "(none)" }
        // DEX access flags are authoritative even when ART rejects a class.
        val dexFinalChain = hierarchy.mapNotNull { line ->
            val className = line.substringBefore(" -> ")
            val definition = ExtensionDexInspector.inspect(apkPaths, className).first
            definition?.let {
                "$className: final=${(it.accessFlags and 0x10) != 0}, accessFlags=0x${it.accessFlags.toString(16)}"
            }
        }
        base["dexHierarchyAccessFlags"] = dexFinalChain.joinToString("\n")
        base["dexObfuscatedSuperclassResolved"] = if (dexClassInfo?.superClass != null &&
            dexClassInfo.superClass in availableClasses)
            hierarchy.any { it.startsWith("${dexClassInfo.superClass} ->") } else false
        // Diagnose host API requirements from DEX metadata without executing the extension.
        // A class can be listed in DEX but remain unloadable when its host interfaces
        // are absent from AnimeStream's classpath.
        val directDependencies = listOfNotNull(dexClassInfo?.superClass)
            .plus(dexClassInfo?.interfaces ?: emptyList())
            .filter { it !in availableClasses && !it.startsWith("java.") &&
                !it.startsWith("javax.") && !it.startsWith("android.") &&
                !it.startsWith("kotlin.") }
        val missingHostInterfaces = directDependencies.filter {
            it.startsWith("eu.kanade.tachiyomi.animesource.") ||
                it.startsWith("eu.kanade.tachiyomi.source.")
        }
        // Resolve every discovered host API type against the actual parent loader.
        // This is a safe compatibility probe: it does not initialize extension classes.
        val hostApiProbe = (directDependencies + transitiveMissing)
            .filter { it.startsWith("eu.kanade.tachiyomi.") }
            .distinct()
            .associateWith { type ->
                try {
                    Class.forName(type, false, javaClass.classLoader)
                    "available"
                } catch (e: ClassNotFoundException) {
                    "missing"
                } catch (e: LinkageError) {
                    "linkage_error: ${e.javaClass.simpleName}: ${e.message}"
                }
            }
        // Probe the complete first-level Aniyomi source ABI surface rather than
        // only the two types discovered in the DEX inheritance chain.
        // These are runtime class checks, not substitutes for the real API.
        val requiredHostTypes = listOf(
            "eu.kanade.tachiyomi.animesource.AnimeSource",
            "eu.kanade.tachiyomi.animesource.AnimeCatalogueSource",
            "eu.kanade.tachiyomi.animesource.ConfigurableAnimeSource",
            "eu.kanade.tachiyomi.animesource.online.AnimeHttpSource",
            "eu.kanade.tachiyomi.animesource.model.AnimeFilterList",
            "eu.kanade.tachiyomi.animesource.model.AnimesPage",
            "eu.kanade.tachiyomi.animesource.model.SAnime",
            "eu.kanade.tachiyomi.animesource.model.SEpisode",
            "eu.kanade.tachiyomi.animesource.model.Hoster",
            "eu.kanade.tachiyomi.animesource.model.Video",
            "eu.kanade.tachiyomi.network.NetworkHelper",
            "rx.Observable",
            "okhttp3.OkHttpClient",
            "uy.kohesive.injekt.Injekt"
        )
        val requiredProbe = requiredHostTypes.associateWith { type ->
            try {
                Class.forName(type, false, javaClass.classLoader)
                "available"
            } catch (e: ClassNotFoundException) {
                "missing"
            } catch (e: LinkageError) {
                "linkage_error: ${e.javaClass.simpleName}"
            }
        }
        base["requiredHostApiProbe"] = requiredProbe.entries.joinToString("; ") {
            "${it.key}=${it.value}"
        }
        base["requiredHostApiMissingCount"] = requiredProbe.values.count { it != "available" }
        base["hostApiRuntimeReady"] = requiredProbe.values.all { it == "available" }
        // Report linkage against the actual parent loader. A source class being
        // discoverable in DEX is insufficient if its API signatures are absent.
        // Inspect the JVM method descriptors actually exposed by the host.
        // This does not execute any third-party extension code.
        val abiChecks = listOf(
            Triple("eu.kanade.tachiyomi.animesource.model.SAnime", "create", "companion_factory"),
            Triple("eu.kanade.tachiyomi.animesource.model.SEpisode", "create", "companion_factory"),
            Triple("eu.kanade.tachiyomi.animesource.online.AnimeHttpSource", "fetchPopularAnime", "http_rx"),
            Triple("eu.kanade.tachiyomi.animesource.online.AnimeHttpSource", "fetchEpisodeList", "http_rx")
        )
        base["hostApiMethodProbe"] = abiChecks.joinToString("; ") { (className, methodName, label) ->
            try {
                val cls = Class.forName(className, false, javaClass.classLoader)
                val signatures = cls.declaredMethods.filter { it.name == methodName }
                    .joinToString(" | ") { method ->
                        "(${method.parameterTypes.joinToString(",") { it.name }}):${method.returnType.name}"
                    }
                "$label.$methodName=${signatures.ifEmpty { "not_declared" }}"
            } catch (e: Throwable) {
                "$label.$methodName=unavailable:${e.javaClass.simpleName}"
            }
        }
        base["hostApiReadinessStatus"] = if (requiredProbe.values.all { it == "available" })
            "required_class_probe_passed_not_abi_verified"
        else "missing_runtime_or_host_api_classes"
        base["hostApiMissingClassNames"] = requiredProbe.filterValues { it != "available" }
            .keys.joinToString(", ")

        base["hostApiClassProbe"] = hostApiProbe.entries.joinToString("; ") {
            "${it.key}=${it.value}"
        }.ifEmpty { "(no host API classes discovered)" }
        base["missingHostApiClassCount"] = hostApiProbe.values.count { it != "available" }
        base["missingAniyomiHostApiTypes"] = missingHostInterfaces.filter { hostApiProbe[it] != "available" }.joinToString(", ")
            .ifEmpty { "(none detected in direct dependencies)" }
        base["hostApiDependencyStatus"] = if (hostApiProbe.values.any { it != "available" })
            "host_api_runtime_resolution_failed" else "host_api_dependencies_resolved_or_not_required"
        if (target == null) {
            base["status"] = "class_not_in_dex"
            base["diagnosis"] = "Declared entry point absent from scanned base/split APK DEX files"
            return base
        }
        // Diagnostic only: do not initialize or instantiate untrusted extension classes.
        // Compare two loaders against the same installed base/split APK paths.
        val dexPath = apkPaths.joinToString(java.io.File.pathSeparator)
        val loaders = listOf(
            "DexClassLoader" to DexClassLoader(dexPath, codeCacheDir.absolutePath,
                info.nativeLibraryDir, javaClass.classLoader),
            "PathClassLoader" to PathClassLoader(dexPath, info.nativeLibraryDir,
                javaClass.classLoader)
        )
        val isolatedLoader = ExtensionIsolatedClassLoader(
            dexPath, codeCacheDir.absolutePath, info.nativeLibraryDir,
            javaClass.classLoader, availableClasses
        )
        val diagnosticLoaders = loaders + ("IsolatedChildFirst" to isolatedLoader)
        base["loaderTopology"] = diagnosticLoaders.joinToString("; ") { (name, loader) ->
            "$name parent=${loader.parent?.javaClass?.name ?: "bootstrap"}"
        }
        val outcomes = mutableMapOf<String, String>()
        var resolvedBy: String? = null
        var firstError: Throwable? = null
        for ((name, loader) in diagnosticLoaders) {
            try {
                val clazz = Class.forName(target, false, loader)
                outcomes[name] = "class_found: ${clazz.name}"
                if (resolvedBy == null) resolvedBy = name
            } catch (e: Throwable) {
                if (firstError == null) firstError = e
                val causes = generateSequence(e) { it.cause }.take(8).toList()
                outcomes[name] = causes.joinToString(" -> ") {
                    it.javaClass.simpleName + ": " + (it.message ?: "")
                }
            }
        }
        // A package-context loader can resolve dependencies packaged as split APKs
        // using Android's own installed-package class path. This is still
        // metadata-only: Class.forName(..., false, ...) does not initialize code.
        try {
            val packageContext = createPackageContext(
                packageName, android.content.Context.CONTEXT_INCLUDE_CODE or
                    android.content.Context.CONTEXT_IGNORE_SECURITY
            )
            val clazz = Class.forName(target, false, packageContext.classLoader)
            outcomes["PackageContextClassLoader"] = "class_found: ${clazz.name}"
            if (resolvedBy == null) resolvedBy = "PackageContextClassLoader"
        } catch (e: Throwable) {
            val causes = generateSequence(e) { it.cause }.take(8).toList()
            outcomes["PackageContextClassLoader"] = causes.joinToString(" -> ") {
                it.javaClass.simpleName + ": " + (it.message ?: "")
            }
        }
        // Beta 32: distinguish a real missing host type from a DEX-only dependency.
        // Inspect the actual class selected by each loader, including its origin
        // and final modifier. Never initialize extension code in this diagnostic.
        val superName = dexClassInfo?.superClass
        if (!superName.isNullOrBlank()) {
            val superDiagnostics = mutableListOf<String>()
            for ((loaderName, loader) in loaders) {
                try {
                    val superClass = Class.forName(superName, false, loader)
                    val origin = superClass.protectionDomain?.codeSource?.location?.toString()
                        ?: "(code source unavailable on Android)"
                    superDiagnostics.add(
                        "$loaderName: name=${superClass.name}, final=${java.lang.reflect.Modifier.isFinal(superClass.modifiers)}, " +
                        "loader=${superClass.classLoader?.javaClass?.name ?: "bootstrap"}, origin=$origin"
                    )
                } catch (error: Throwable) {
                    superDiagnostics.add("$loaderName: ${error.javaClass.simpleName}: ${error.message}")
                }
            }
            base["runtimeSuperclassResolution"] = superDiagnostics.joinToString("\\n")
            base["runtimeSuperclassName"] = superName
            try {
                val contextLoader = createPackageContext(
                    packageName, android.content.Context.CONTEXT_INCLUDE_CODE or
                        android.content.Context.CONTEXT_IGNORE_SECURITY
                ).classLoader
                val resolved = Class.forName(superName, false, contextLoader)
                base["packageContextSuperclassResolution"] =
                    "name=${resolved.name}, final=${java.lang.reflect.Modifier.isFinal(resolved.modifiers)}, " +
                    "loader=${resolved.classLoader?.javaClass?.name ?: "bootstrap"}"
            } catch (error: Throwable) {
                base["packageContextSuperclassResolution"] =
                    "${error.javaClass.simpleName}: ${error.message}"
            }
        }
        base["loaderSuperclassComparison"] = diagnosticLoaders.joinToString("\n") { (name, loader) ->
            if (superName == null) "$name: no superclass"
            else try {
                val loaded = Class.forName(superName, false, loader)
                val dexDefinition = ExtensionDexInspector.inspect(apkPaths, superName).first
                "$name: dexFinal=${dexDefinition?.let { (it.accessFlags and 0x10) != 0 }}, " +
                    "runtimeFinal=${java.lang.reflect.Modifier.isFinal(loaded.modifiers)}, " +
                    "sameLoader=${loaded.classLoader === loader}, " +
                    "actualLoader=${loaded.classLoader?.javaClass?.name ?: "bootstrap"}"
            } catch (error: Throwable) {
                "$name: ${error.javaClass.simpleName}: ${error.message}"
            }
        }
        base["dexDependencyInterpretation"] =
            "DEX-only missing means not packaged inside extension APK; it does not imply missing from host runtime."
        // Existing Flutter diagnostics already displays "diagnosis". Surface the
        // new DEX findings there as well, without requiring a UI migration.
        val dexSuperDefinition = superName?.let {
            ExtensionDexInspector.inspect(apkPaths, it).first
        }
        val superclassSummary = if (dexSuperDefinition == null) {
            "Superclass DEX definition unavailable"
        } else {
            "Superclass $superName DEX final=${(dexSuperDefinition.accessFlags and 0x10) != 0} " +
                "(flags=0x${dexSuperDefinition.accessFlags.toString(16)})"
        }
        base["superclassDiagnosticSummary"] = superclassSummary
        // Beta 33.1: reflection-only ABI probe. No initialization or constructor invocation.
        base["extensionInstantiationStatus"] = "not_attempted"
        try {
            val entry = Class.forName(target, false, isolatedLoader)
            val source = Class.forName("eu.kanade.tachiyomi.animesource.AnimeSource", false, javaClass.classLoader)
            val ctors = entry.declaredConstructors
            base["extensionConstructorProbe"] = ctors.joinToString("; ") { ctor ->
                "(${ctor.parameterTypes.joinToString(",") { it.name }})"
            }
            base["extensionImplementsHostAnimeSource"] = source.isAssignableFrom(entry)
            base["extensionNoArgConstructorAvailable"] = ctors.any { it.parameterTypes.isEmpty() }
            base["extensionInstantiationStatus"] = "not_attempted"
            base["extensionAbiReadiness"] = when {
                !source.isAssignableFrom(entry) -> "host_source_type_mismatch"
                java.lang.reflect.Modifier.isAbstract(entry.modifiers) -> "abstract_entry_point"
                ctors.none { it.parameterTypes.isEmpty() } -> "requires_constructor_arguments"
                else -> "constructor_present_not_executed"
            }
        } catch (error: Throwable) {
            base["extensionAbiReadiness"] = "reflection_failed"
            base["extensionConstructorProbe"] = "${error.javaClass.simpleName}: ${error.message}"
        }
        // Beta 33.3: identify Kotlin runtime visibility before invoking extension code.
        val kotlinRuntimeTypes = listOf(
            "kotlin.jvm.functions.Function0",
            "kotlin.jvm.internal.Intrinsics",
            "kotlin.Unit",
            "kotlin.coroutines.Continuation"
        )
        base["kotlinRuntimeProbe"] = kotlinRuntimeTypes.joinToString("; ") { type ->
            listOf("host" to javaClass.classLoader, "isolated" to isolatedLoader)
                .joinToString(", ") { (label, loader) ->
                    try {
                        val cls = Class.forName(type, false, loader)
                        "$label:$type=available via ${cls.classLoader?.javaClass?.name ?: "bootstrap"}"
                    } catch (error: Throwable) {
                        "$label:$type=${error.javaClass.simpleName}: ${error.message}"
                    }
                }
        }
        if (attemptInstantiation && base["extensionAbiReadiness"] == "constructor_present_not_executed") {
            try {
                val entry = Class.forName(target, false, isolatedLoader)
                val instance = entry.getDeclaredConstructor().newInstance()
                base["extensionInstantiationStatus"] = "instance_created"
                base["extensionInstanceClass"] = instance.javaClass.name
            } catch (error: Throwable) {
                val cause = (error as? java.lang.reflect.InvocationTargetException)
                    ?.targetException ?: error
                base["extensionInstantiationStatus"] = "failed"
                base["extensionInstantiationError"] =
                    cause.javaClass.simpleName + ": " + cause.message
            }
        } else if (attemptInstantiation) {
            base["extensionInstantiationStatus"] = "skipped_abi_not_ready"
        }
        base["diagnosticDetails"] = listOf(
            superclassSummary,
            "PackageContext: ${base["packageContextSuperclassResolution"] ?: "(unavailable)"}",
            "DEX hierarchy flags: ${base["dexHierarchyAccessFlags"] ?: "(unavailable)"}",
            "Loader topology: ${base["loaderTopology"] ?: "(unavailable)"}",
            "Superclass comparison: ${base["loaderSuperclassComparison"] ?: "(unavailable)"}",
            "Isolated child-first: ${outcomes["IsolatedChildFirst"] ?: "(unavailable)"}",
            "Extension ABI: ${base["extensionAbiReadiness"] ?: "(unavailable)"}",
            "Constructors: ${base["extensionConstructorProbe"] ?: "(unavailable)"}",
            "Implements host AnimeSource: ${base["extensionImplementsHostAnimeSource"] ?: "(unavailable)"}",
            "No-arg constructor: ${base["extensionNoArgConstructorAvailable"] ?: "(unavailable)"}",
            "Instantiation: ${base["extensionInstantiationStatus"] ?: "not_attempted"}",
            "Instantiation error: ${base["extensionInstantiationError"] ?: "(none)"}",
            "Kotlin runtime: ${base["kotlinRuntimeProbe"] ?: "(unavailable)"}"
        ).joinToString("\n")
        base["packageContextClassLoaderResult"] = outcomes["PackageContextClassLoader"]
        base["isolatedChildFirstResult"] = outcomes["IsolatedChildFirst"]
        base["dexClassLoaderResult"] = outcomes["DexClassLoader"]
        base["pathClassLoaderResult"] = outcomes["PathClassLoader"]
        base["resolvedByLoader"] = resolvedBy
        if (resolvedBy != null) {
            base["status"] = "class_found"
            base["className"] = target
            base["diagnosis"] = "Class resolved without initialization by $resolvedBy. This does not establish executable extension support.\\n" + base["diagnosticDetails"]
            return base
        }
        val e = firstError ?: IllegalStateException("Both class loaders failed without a reported cause")
        val causes = generateSequence(e) { it.cause }.take(8).toList()
        val chain = causes.joinToString(" -> ") {
            it.javaClass.simpleName + ": " + (it.message ?: "")
        }
        val missing = causes.firstOrNull {
            it is ClassNotFoundException || it is NoClassDefFoundError
        }?.message
        val missingHostApi = missing?.contains("eu.kanade.tachiyomi.animesource.") == true ||
            missing?.contains("eu/kanade/tachiyomi/animesource/") == true ||
            missing?.contains("eu.kanade.tachiyomi.source.") == true ||
            missing?.contains("eu/kanade/tachiyomi/source/") == true
        base["status"] = if (missingHostApi) "missing_host_api" else "class_load_failed"
        base["className"] = target
        base["error"] = chain
        base["missingDependency"] = missing?.takeUnless { it == target || it == target.replace('.', '/') }
        base["targetClassInDex"] = target in classes
        base["dependencyClassInDex"] = missing?.replace('/', '.')?.let { it in classes }
        base["entryPointResolutionFailed"] = missing == target || missing == target.replace('.', '/')
        base["exceptionTypes"] = causes.joinToString(" -> ") { it.javaClass.name }
        base["rootCause"] = causes.lastOrNull()?.let {
            it.javaClass.name + ": " + (it.message ?: "")
        }
        base["diagnosis"] = (if (causes.any { it is VerifyError })
            "ART VerifyError: compare DEX and runtime superclass flags and class loader identity."
            else if (missingHostInterfaces.any { hostApiProbe[it] != "available" })
            "Required Aniyomi host API type unavailable from app parent loader."
            else if (missingHostApi)
            "A known Aniyomi/Tachiyomi host API class could not be resolved"
            else "Both loaders failed. Compare dexClassLoaderResult and pathClassLoaderResult; a DEX inventory hit alone does not guarantee a loadable class.") + "\\n" + base["diagnosticDetails"]
        return base
    }

    override fun onUserLeaveHint() {
         super.onUserLeaveHint()
         channel.invokeMethod("onUserLeaveHint", null);
    }

    fun showToast(message: String) {
        Handler(Looper.getMainLooper()).post {
            Toast.makeText(this, message, Toast.LENGTH_SHORT).show();
        }
    }
}

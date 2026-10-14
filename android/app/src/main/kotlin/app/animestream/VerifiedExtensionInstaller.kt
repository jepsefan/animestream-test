package app.animestream

import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.core.content.FileProvider
import com.android.apksig.ApkVerifier
import java.io.File
import java.net.HttpURLConnection
import java.net.URI
import java.security.MessageDigest
import javax.net.ssl.HttpsURLConnection

/** Verifies downloaded APK bytes against the locally pinned repository
 * certificate and opens Android's user-controlled installer. Never silent.
 */
internal class VerifiedExtensionInstaller(private val context: Context) {
    private val maxApkBytes = 100L * 1024 * 1024
    private val sha256Pattern = Regex("^[a-f0-9]{64}$")
    private val packagePattern = Regex("^[a-zA-Z0-9_]+(\\.[a-zA-Z0-9_]+)+$")

    private fun fingerprint(bytes: ByteArray): String =
        MessageDigest.getInstance("SHA-256").digest(bytes)
            .joinToString("") { "%02x".format(it.toInt() and 255) }

    private fun validatedUrls(index: String, apk: String): URI {
        val indexUri = URI(index)
        val apkUri = URI(apk)
        require(indexUri.scheme == "https" && apkUri.scheme == "https")
        require(indexUri.rawQuery == null && indexUri.rawFragment == null)
        require(apkUri.rawQuery == null && apkUri.rawFragment == null)
        require(indexUri.userInfo == null && apkUri.userInfo == null)
        require(indexUri.host != null && indexUri.host == apkUri.host)
        require(indexUri.port == -1 && apkUri.port == -1)
        require(indexUri.path.endsWith("/index.min.json"))
        val directory = indexUri.path.removeSuffix("index.min.json")
        require(apkUri.path.startsWith(directory + "apk/") &&
            apkUri.path.endsWith(".apk")) { "APK must belong to selected catalog" }
        require(!apkUri.path.contains("/../") && !apkUri.path.contains("/./"))
        return apkUri
    }

    fun prepare(
        indexUrl: String,
        apkUrl: String,
        packageName: String,
        expectedFingerprint: String,
        expectedVersionCode: Long,
        expectedVersion: String
    ): Map<String, Any?> {
        val approved = expectedFingerprint.lowercase()
        require(sha256Pattern.matches(approved)) { "Invalid trusted fingerprint" }
        require(packagePattern.matches(packageName)) { "Invalid package name" }
        require(expectedVersionCode > 0 && expectedVersion.isNotBlank()) {
            "Missing extension version in catalog"
        }
        val url = validatedUrls(indexUrl, apkUrl)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O &&
            !context.packageManager.canRequestPackageInstalls()) {
            val settings = Intent(Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES,
                Uri.parse("package:" + context.packageName))
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            context.startActivity(settings)
            return mapOf("status" to "permission_required")
        }

        val directory = File(context.cacheDir, "extension_installs")
        require(directory.isDirectory || directory.mkdirs()) { "Cannot create download folder" }
        val file = File.createTempFile("verified_", ".apk", directory)
        var handedOff = false
        try {
            val connection = url.toURL().openConnection() as HttpsURLConnection
            connection.connectTimeout = 15000
            connection.readTimeout = 30000
            connection.instanceFollowRedirects = false
            try {
                connection.connect()
                require(connection.responseCode == HttpURLConnection.HTTP_OK) {
                    "APK HTTP " + connection.responseCode
                }
                val length = connection.contentLengthLong
                require(length <= maxApkBytes || length < 0) { "APK too large" }
                connection.inputStream.use { input ->
                    file.outputStream().use { output ->
                        val buffer = ByteArray(65536)
                        var total = 0L
                        while (true) {
                            val count = input.read(buffer)
                            if (count < 0) break
                            total += count
                            require(total <= maxApkBytes) { "APK too large" }
                            output.write(buffer, 0, count)
                        }
                    }
                }
            } finally {
                connection.disconnect()
            }
            require(file.length() > 0) { "Empty APK" }

            // apk-signature verification validates the cryptographic APK
            // signatures, rather than just trusting reported certificate bytes.
            val verification = ApkVerifier.Builder(file).build().verify()
            require(verification.isVerified) { "Invalid APK signature" }
            val certificates = verification.signerCertificates
            require(certificates.size == 1) { "Multi-signer APK cannot match pinned key" }
            require(fingerprint(certificates.single().encoded) == approved) {
                "APK signer differs from approved repository"
            }

            val pm = context.packageManager
            val flags = PackageManager.GET_META_DATA or PackageManager.GET_CONFIGURATIONS
            val parsed = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                pm.getPackageArchiveInfo(file.absolutePath,
                    PackageManager.PackageInfoFlags.of(flags.toLong()))
            } else {
                @Suppress("DEPRECATION")
                pm.getPackageArchiveInfo(file.absolutePath, flags)
            } ?: error("Android cannot parse APK")
            require(parsed.packageName == packageName) { "APK package mismatch" }
            val versionCode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                parsed.longVersionCode
            } else {
                @Suppress("DEPRECATION")
                parsed.versionCode.toLong()
            }
            require(versionCode == expectedVersionCode) { "APK version code mismatch" }
            require(parsed.versionName == expectedVersion) { "APK version name mismatch" }
            val isSource = parsed.applicationInfo?.metaData
                ?.getString("tachiyomi.animeextension.class")?.isNotBlank() == true ||
                parsed.reqFeatures.orEmpty().any { it.name == "tachiyomi.animeextension" }
            require(isSource) { "APK is not an anime extension" }

            val installed = try {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                    pm.getPackageInfo(packageName,
                        PackageManager.PackageInfoFlags.of(
                            PackageManager.GET_SIGNING_CERTIFICATES.toLong()))
                } else {
                    @Suppress("DEPRECATION")
                    pm.getPackageInfo(packageName,
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P)
                            PackageManager.GET_SIGNING_CERTIFICATES
                        else PackageManager.GET_SIGNATURES)
                }
            } catch (_: PackageManager.NameNotFoundException) {
                null
            }
            if (installed != null) {
                val code = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                    installed.longVersionCode
                } else {
                    @Suppress("DEPRECATION")
                    installed.versionCode.toLong()
                }
                require(code <= versionCode) { "APK downgrade blocked" }
                val signers = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                    installed.signingInfo?.apkContentsSigners.orEmpty()
                } else {
                    @Suppress("DEPRECATION")
                    installed.signatures.orEmpty()
                }
                require(signers.size == 1 &&
                    fingerprint(signers.single().toByteArray()) == approved) {
                    "Existing installation uses a different signing key"
                }
            }

            val uri = FileProvider.getUriForFile(
                context, context.packageName + ".extensionfileprovider", file)
            val install = Intent(Intent.ACTION_VIEW)
                .setDataAndType(uri, "application/vnd.android.package-archive")
                .addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_ACTIVITY_NEW_TASK)
            require(install.resolveActivity(pm) != null) { "No system installer available" }
            context.startActivity(install)
            handedOff = true
            return mapOf("status" to "installer_opened", "packageName" to packageName)
        } finally {
            // Installer reads the content URI asynchronously.
            if (!handedOff) file.delete()
        }
    }
}

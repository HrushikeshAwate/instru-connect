package com.instru.instruConnect

import android.content.pm.PackageManager
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.security.MessageDigest

class MainActivity : FlutterActivity() {
    private val channelName = "app_cert_info"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getSigningSha256" -> result.success(signingHash("SHA-256"))
                    "getSigningSha1" -> result.success(signingHash("SHA-1"))
                    else -> result.notImplemented()
                }
            }
    }

    private fun signingHash(algorithm: String): String {
        return try {
            val signatures = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                @Suppress("PackageManagerGetSignatures")
                val info = packageManager.getPackageInfo(
                    packageName,
                    PackageManager.GET_SIGNING_CERTIFICATES,
                )
                val signingInfo = info.signingInfo
                when {
                    signingInfo == null -> emptyArray()
                    signingInfo.hasMultipleSigners() -> signingInfo.apkContentsSigners
                    else -> signingInfo.signingCertificateHistory
                }
            } else {
                @Suppress("DEPRECATION", "PackageManagerGetSignatures")
                val info = packageManager.getPackageInfo(
                    packageName,
                    PackageManager.GET_SIGNATURES,
                )
                @Suppress("DEPRECATION")
                info.signatures ?: emptyArray()
            }

            if (signatures.isEmpty()) {
                "no-signature"
            } else {
                val digest = MessageDigest.getInstance(algorithm)
                    .digest(signatures[0].toByteArray())
                digest.joinToString(":") { String.format("%02X", it) }
            }
        } catch (e: Exception) {
            "error: ${e.message}"
        }
    }
}

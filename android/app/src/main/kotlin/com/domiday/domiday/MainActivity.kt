package com.domiday.domiday

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import androidx.core.content.FileProvider
import java.io.File
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Только чтение: ограничивает ли система фон приложения (Doze /
        // «оптимизация батареи»). Никаких запросов и новых разрешений —
        // отключение ограничений владелец делает сам в настройках.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "domiday/battery")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isIgnoring" -> {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                            val pm = getSystemService(POWER_SERVICE) as PowerManager
                            result.success(pm.isIgnoringBatteryOptimizations(packageName))
                        } else {
                            result.success(true)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
        // «Поделиться итогами года»: PNG из кэша приложения уходит в
        // системное меню через FileProvider. Без сети и без разрешений.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "domiday/share")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "shareImage" -> {
                        val path = call.argument<String>("path")
                        val title = call.argument<String>("title") ?: ""
                        if (path == null) {
                            result.error("args", "path required", null)
                            return@setMethodCallHandler
                        }
                        try {
                            val uri = FileProvider.getUriForFile(
                                this, "$packageName.fileprovider", File(path)
                            )
                            val send = Intent(Intent.ACTION_SEND).apply {
                                type = "image/png"
                                putExtra(Intent.EXTRA_STREAM, uri)
                                putExtra(Intent.EXTRA_SUBJECT, title)
                                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                            }
                            startActivity(Intent.createChooser(send, title))
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("share", e.message, null)
                        }
                    }
                    // «О приложении»: почта и сайт открываются в другом
                    // приложении. Само приложение в сеть не ходит.
                    "openUrl" -> {
                        val url = call.argument<String>("url")
                        if (url == null || !(url.startsWith("mailto:") || url.startsWith("https://"))) {
                            result.error("args", "mailto: or https: url required", null)
                            return@setMethodCallHandler
                        }
                        try {
                            startActivity(Intent(Intent.ACTION_VIEW, Uri.parse(url)))
                            result.success(true)
                        } catch (e: Exception) {
                            result.success(false)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }
}

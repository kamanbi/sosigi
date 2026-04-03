package com.kaman.sosigi

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            BACKGROUND_SYNC_CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "schedule" -> {
                    val intervalMinutes = call.argument<Number>("intervalMinutes")
                        ?.toLong()
                        ?: DEFAULT_INTERVAL_MINUTES
                    val wifiOnly = call.argument<Boolean>("wifiOnly") ?: false
                    BackgroundSyncScheduler.schedule(
                        applicationContext,
                        intervalMinutes,
                        wifiOnly,
                    )
                    result.success(null)
                }

                "cancel" -> {
                    BackgroundSyncScheduler.cancel(applicationContext)
                    result.success(null)
                }

                "isBatteryOptimized" -> {
                    val pm = getSystemService(POWER_SERVICE) as PowerManager
                    val optimized = !pm.isIgnoringBatteryOptimizations(packageName)
                    result.success(optimized)
                }

                "requestIgnoreBatteryOptimization" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        val launched = tryStartActivity(
                            Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS).apply {
                                data = Uri.parse("package:$packageName")
                                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            },
                        )
                        if (!launched) {
                            tryStartActivity(
                                Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS).apply {
                                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                                },
                            )
                        }
                    }
                    result.success(null)
                }

                else -> result.notImplemented()
            }
        }

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            NOTIFICATION_SETTINGS_CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "open" -> {
                    openNotificationSettings()
                    result.success(null)
                }

                else -> result.notImplemented()
            }
        }
    }

    private fun tryStartActivity(intent: Intent): Boolean {
        return try {
            startActivity(intent)
            true
        } catch (e: Exception) {
            false
        }
    }

    private fun openNotificationSettings() {
        val settingsIntent =
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS).apply {
                    putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                }
            } else {
                Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                    data = Uri.parse("package:$packageName")
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                }
            }

        startActivity(settingsIntent)
    }

    companion object {
        private const val BACKGROUND_SYNC_CHANNEL = "sosigi/background_sync"
        private const val NOTIFICATION_SETTINGS_CHANNEL =
            "sosigi/notification_settings"
        private const val DEFAULT_INTERVAL_MINUTES = 60L
    }
}

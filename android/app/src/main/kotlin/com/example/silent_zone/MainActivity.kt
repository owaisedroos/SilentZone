package com.example.silent_zone

import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.media.AudioManager
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "silent_zone/audio"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {

                    "hasDndPermission" -> {
                        val nm = getSystemService(Context.NOTIFICATION_SERVICE)
                                as NotificationManager
                        result.success(nm.isNotificationPolicyAccessGranted)
                    }

                    "openDndSettings" -> {
                        val intent = Intent(
                            Settings.ACTION_NOTIFICATION_POLICY_ACCESS_SETTINGS
                        )
                        intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
                        startActivity(intent)
                        result.success(null)
                    }

                    "setSilentMode" -> {
                        val silent = call.argument<Boolean>("silent") ?: false
                        val nm = getSystemService(Context.NOTIFICATION_SERVICE)
                                as NotificationManager

                        if (!nm.isNotificationPolicyAccessGranted) {
                            result.error(
                                "NO_DND_PERMISSION",
                                "Do Not Disturb access not granted",
                                null
                            )
                            return@setMethodCallHandler
                        }

                        val audioManager =
                            getSystemService(Context.AUDIO_SERVICE) as AudioManager
                        audioManager.ringerMode = if (silent) {
                            AudioManager.RINGER_MODE_SILENT
                        } else {
                            AudioManager.RINGER_MODE_NORMAL
                        }
                        result.success(null)
                    }

                    else -> result.notImplemented()
                }
            }
    }
}
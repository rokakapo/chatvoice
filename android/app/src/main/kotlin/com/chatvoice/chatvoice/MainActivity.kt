package com.chatvoice.chatvoice

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.EventChannel
import android.os.Bundle
import android.content.Intent
import android.content.Context
import android.telecom.TelecomManager
import android.app.role.RoleManager
import android.os.Build
import android.media.AudioManager
import android.media.MediaRecorder
import android.media.MediaPlayer
import android.media.AudioRecord
import android.media.AudioFormat
import android.media.AudioTrack
import android.util.Log
import java.io.File
import java.io.FileOutputStream

class MainActivity : FlutterActivity() {
    companion object {
        const val METHOD_CHANNEL = "com.chatvoice/call_control"
        const val EVENT_CHANNEL = "com.chatvoice/call_events"
        const val TAG = "ChatVoice"
        const val REQUEST_CODE_SET_DEFAULT_DIALER = 1001
        const val REQUEST_CODE_CALL_SCREENING = 1002

        var methodChannelInstance: MethodChannel? = null
        var eventSink: EventChannel.EventSink? = null
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Method Channel for call control
        methodChannelInstance = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL)
        methodChannelInstance?.setMethodCallHandler { call, result ->
            when (call.method) {
                "requestCallPermissions" -> {
                    requestCallPermissions(result)
                }
                "setDefaultDialer" -> {
                    requestDefaultDialer(result)
                }
                "requestCallScreeningRole" -> {
                    requestCallScreeningRole(result)
                }
                "isDefaultDialer" -> {
                    result.success(isDefaultDialer())
                }
                "answerCall" -> {
                    CallService.answerCurrentCall()
                    result.success(true)
                }
                "rejectCall" -> {
                    CallService.rejectCurrentCall()
                    result.success(true)
                }
                "endCall" -> {
                    CallService.endCurrentCall()
                    result.success(true)
                }
                "playAudioToCall" -> {
                    val audioPath = call.argument<String>("audioPath")
                    if (audioPath != null) {
                        CallService.playAudioToCall(audioPath, applicationContext)
                        result.success(true)
                    } else {
                        result.error("INVALID_PATH", "Audio path is null", null)
                    }
                }
                "startRecording" -> {
                    val outputPath = call.argument<String>("outputPath")
                    if (outputPath != null) {
                        CallService.startRecording(outputPath, applicationContext)
                        result.success(true)
                    } else {
                        result.error("INVALID_PATH", "Output path is null", null)
                    }
                }
                "stopRecording" -> {
                    val path = CallService.stopRecording()
                    result.success(path)
                }
                "getCallState" -> {
                    result.success(CallService.getCallState())
                }
                "setAutoAnswer" -> {
                    val enabled = call.argument<Boolean>("enabled") ?: false
                    CallService.autoAnswer = enabled
                    result.success(true)
                }
                "getRecordingPath" -> {
                    val dir = File(applicationContext.filesDir, "recordings")
                    if (!dir.exists()) dir.mkdirs()
                    result.success(dir.absolutePath)
                }
                else -> result.notImplemented()
            }
        }

        // Event Channel for call state updates
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    eventSink = events
                }

                override fun onCancel(arguments: Any?) {
                    eventSink = null
                }
            }
        )
    }

    private fun requestCallPermissions(result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            requestDefaultDialer(result)
        } else {
            result.success(false)
        }
    }

    private fun requestDefaultDialer(result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val roleManager = getSystemService(Context.ROLE_SERVICE) as RoleManager
            if (roleManager.isRoleAvailable(RoleManager.ROLE_DIALER)) {
                if (!roleManager.isRoleHeld(RoleManager.ROLE_DIALER)) {
                    val intent = roleManager.createRequestRoleIntent(RoleManager.ROLE_DIALER)
                    startActivityForResult(intent, REQUEST_CODE_SET_DEFAULT_DIALER)
                    result.success(true)
                } else {
                    result.success(true)
                }
            } else {
                result.success(false)
            }
        } else {
            val intent = Intent(TelecomManager.ACTION_CHANGE_DEFAULT_DIALER)
            intent.putExtra(TelecomManager.EXTRA_CHANGE_DEFAULT_DIALER_PACKAGE_NAME, packageName)
            startActivity(intent)
            result.success(true)
        }
    }

    private fun requestCallScreeningRole(result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val roleManager = getSystemService(Context.ROLE_SERVICE) as RoleManager
            if (roleManager.isRoleAvailable(RoleManager.ROLE_CALL_SCREENING)) {
                if (!roleManager.isRoleHeld(RoleManager.ROLE_CALL_SCREENING)) {
                    val intent = roleManager.createRequestRoleIntent(RoleManager.ROLE_CALL_SCREENING)
                    startActivityForResult(intent, REQUEST_CODE_CALL_SCREENING)
                    result.success(true)
                } else {
                    result.success(true)
                }
                return
            }
        }
        result.success(false)
    }

    private fun isDefaultDialer(): Boolean {
        val telecomManager = getSystemService(Context.TELECOM_SERVICE) as TelecomManager
        return packageName == telecomManager.defaultDialerPackage
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        when (requestCode) {
            REQUEST_CODE_SET_DEFAULT_DIALER -> {
                val isDefault = isDefaultDialer()
                eventSink?.success(mapOf(
                    "event" to "defaultDialerChanged",
                    "isDefault" to isDefault
                ))
            }
        }
    }
}

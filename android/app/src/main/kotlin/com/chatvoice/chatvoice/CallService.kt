package com.chatvoice.chatvoice

import android.telecom.Call
import android.telecom.InCallService
import android.telecom.VideoProfile
import android.media.AudioManager
import android.media.MediaRecorder
import android.media.MediaPlayer
import android.media.AudioRecord
import android.media.AudioFormat
import android.media.AudioTrack
import android.content.Context
import android.os.Build
import android.util.Log
import java.io.File

class CallService : InCallService() {

    companion object {
        const val TAG = "ChatVoiceCallService"
        var currentCall: Call? = null
        var autoAnswer: Boolean = false
        private var mediaRecorder: MediaRecorder? = null
        private var mediaPlayer: MediaPlayer? = null
        private var currentRecordingPath: String? = null
        private var isRecording = false

        fun answerCurrentCall() {
            try {
                currentCall?.answer(VideoProfile.STATE_AUDIO_ONLY)
                Log.d(TAG, "Call answered")
            } catch (e: Exception) {
                Log.e(TAG, "Error answering call: ${e.message}")
            }
        }

        fun rejectCurrentCall() {
            try {
                currentCall?.reject(false, null)
                Log.d(TAG, "Call rejected")
            } catch (e: Exception) {
                Log.e(TAG, "Error rejecting call: ${e.message}")
            }
        }

        fun endCurrentCall() {
            try {
                currentCall?.disconnect()
                Log.d(TAG, "Call ended")
            } catch (e: Exception) {
                Log.e(TAG, "Error ending call: ${e.message}")
            }
        }

        fun getCallState(): String {
            return when (currentCall?.state) {
                Call.STATE_RINGING -> "ringing"
                Call.STATE_ACTIVE -> "active"
                Call.STATE_DIALING -> "dialing"
                Call.STATE_HOLDING -> "holding"
                Call.STATE_DISCONNECTED -> "disconnected"
                Call.STATE_CONNECTING -> "connecting"
                else -> "idle"
            }
        }

        fun startRecording(outputPath: String, context: Context) {
            try {
                if (isRecording) stopRecording()

                currentRecordingPath = outputPath
                mediaRecorder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                    MediaRecorder(context)
                } else {
                    @Suppress("DEPRECATION")
                    MediaRecorder()
                }

                mediaRecorder?.apply {
                    setAudioSource(MediaRecorder.AudioSource.VOICE_COMMUNICATION)
                    setOutputFormat(MediaRecorder.OutputFormat.MPEG_4)
                    setAudioEncoder(MediaRecorder.AudioEncoder.AAC)
                    setAudioSamplingRate(44100)
                    setAudioEncodingBitRate(128000)
                    setOutputFile(outputPath)
                    prepare()
                    start()
                }
                isRecording = true
                Log.d(TAG, "Recording started: $outputPath")
            } catch (e: Exception) {
                Log.e(TAG, "Error starting recording: ${e.message}")
                isRecording = false
            }
        }

        fun stopRecording(): String? {
            try {
                if (isRecording) {
                    mediaRecorder?.apply {
                        stop()
                        release()
                    }
                    mediaRecorder = null
                    isRecording = false
                    Log.d(TAG, "Recording stopped: $currentRecordingPath")
                    return currentRecordingPath
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error stopping recording: ${e.message}")
            }
            return null
        }

        fun playAudioToCall(audioPath: String, context: Context) {
            try {
                // Set audio mode for call
                val audioManager = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
                audioManager.mode = AudioManager.MODE_IN_COMMUNICATION
                audioManager.isSpeakerphoneOn = false

                mediaPlayer?.release()
                mediaPlayer = MediaPlayer().apply {
                    setDataSource(audioPath)
                    setAudioStreamType(AudioManager.STREAM_VOICE_CALL)
                    prepare()
                    start()
                    setOnCompletionListener {
                        it.release()
                        mediaPlayer = null
                        // Notify Flutter that audio playback is complete
                        notifyFlutter("audioPlaybackComplete", mapOf("path" to audioPath))
                    }
                }
                Log.d(TAG, "Playing audio to call: $audioPath")
            } catch (e: Exception) {
                Log.e(TAG, "Error playing audio: ${e.message}")
            }
        }

        private fun notifyFlutter(event: String, data: Map<String, Any?> = emptyMap()) {
            try {
                val eventData = mutableMapOf<String, Any?>("event" to event)
                eventData.putAll(data)
                MainActivity.eventSink?.success(eventData)
            } catch (e: Exception) {
                Log.e(TAG, "Error notifying Flutter: ${e.message}")
            }
        }
    }

    private val callCallback = object : Call.Callback() {
        override fun onStateChanged(call: Call, state: Int) {
            super.onStateChanged(call, state)
            val stateStr = when (state) {
                Call.STATE_RINGING -> "ringing"
                Call.STATE_ACTIVE -> "active"
                Call.STATE_DIALING -> "dialing"
                Call.STATE_HOLDING -> "holding"
                Call.STATE_DISCONNECTED -> "disconnected"
                Call.STATE_CONNECTING -> "connecting"
                else -> "unknown"
            }

            Log.d(TAG, "Call state changed: $stateStr")

            // Get caller number
            val callerNumber = call.details?.handle?.schemeSpecificPart ?: "Unknown"

            // Notify Flutter
            notifyFlutter("callStateChanged", mapOf(
                "state" to stateStr,
                "number" to callerNumber
            ))

            when (state) {
                Call.STATE_DISCONNECTED -> {
                    stopRecording()
                    currentCall = null
                }
            }
        }
    }

    override fun onCallAdded(call: Call) {
        super.onCallAdded(call)
        currentCall = call
        call.registerCallback(callCallback)

        val callerNumber = call.details?.handle?.schemeSpecificPart ?: "Unknown"
        Log.d(TAG, "Incoming call from: $callerNumber")

        notifyFlutter("incomingCall", mapOf(
            "number" to callerNumber
        ))

        // Auto-answer if enabled
        if (autoAnswer && call.state == Call.STATE_RINGING) {
            Log.d(TAG, "Auto-answering call...")
            call.answer(VideoProfile.STATE_AUDIO_ONLY)
            notifyFlutter("callAutoAnswered", mapOf(
                "number" to callerNumber
            ))
        }
    }

    override fun onCallRemoved(call: Call) {
        super.onCallRemoved(call)
        call.unregisterCallback(callCallback)
        currentCall = null

        notifyFlutter("callRemoved", mapOf(
            "number" to (call.details?.handle?.schemeSpecificPart ?: "Unknown")
        ))

        Log.d(TAG, "Call removed")
    }
}

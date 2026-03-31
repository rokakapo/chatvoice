package com.chatvoice.chatvoice

import android.telecom.Call
import android.telecom.CallScreeningService as AndroidCallScreeningService
import android.util.Log

class CallScreeningService : AndroidCallScreeningService() {

    companion object {
        const val TAG = "ChatVoiceScreening"
    }

    override fun onScreenCall(callDetails: Call.Details) {
        val number = callDetails.handle?.schemeSpecificPart ?: "Unknown"
        Log.d(TAG, "Screening call from: $number")

        // Allow all calls through - the InCallService will handle them
        val response = CallResponse.Builder()
            .setDisallowCall(false)
            .setRejectCall(false)
            .setSilenceCall(false)
            .setSkipCallLog(false)
            .setSkipNotification(false)
            .build()

        respondToCall(callDetails, response)
    }
}

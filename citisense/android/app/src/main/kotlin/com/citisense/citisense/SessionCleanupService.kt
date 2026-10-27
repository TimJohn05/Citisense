package com.citisense.citisense

import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.IBinder
import android.util.Log

class SessionCleanupService : Service() {
    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        return START_NOT_STICKY
    }

    override fun onTaskRemoved(rootIntent: Intent?) {
        Log.i(TAG, "onTaskRemoved: clearing session from SharedPreferences")
        val prefs = getSharedPreferences(PREFERENCES_NAME, Context.MODE_PRIVATE)
        prefs.edit()
            .remove("flutter.session.user")
            .remove("flutter.session.saved_at")
            .putBoolean("flutter.session.clear_on_launch", true)
            .commit()
        stopSelf()
        super.onTaskRemoved(rootIntent)
    }

    companion object {
        private const val TAG = "SessionCleanup"
        private const val PREFERENCES_NAME = "FlutterSharedPreferences"
    }
}

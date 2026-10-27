package com.citisense.citisense

import android.content.Context
import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        try {
            startService(Intent(this, SessionCleanupService::class.java))
        } catch (_: Exception) {}
    }

    override fun onDestroy() {
        if (isFinishing && !isChangingConfigurations) {
            getSharedPreferences(PREFERENCES_NAME, Context.MODE_PRIVATE)
                .edit()
                .remove("flutter.session.user")
                .remove("flutter.session.saved_at")
                .putBoolean(CLEAR_SESSION_KEY, true)
                .commit()
        }
        super.onDestroy()
    }

    private companion object {
        const val PREFERENCES_NAME = "FlutterSharedPreferences"
        const val CLEAR_SESSION_KEY = "flutter.session.clear_on_launch"
    }
}

package com.citisense.citisense

import android.content.Context
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onDestroy() {
        if (isFinishing && !isChangingConfigurations) {
            getSharedPreferences(PREFERENCES_NAME, Context.MODE_PRIVATE)
                .edit()
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

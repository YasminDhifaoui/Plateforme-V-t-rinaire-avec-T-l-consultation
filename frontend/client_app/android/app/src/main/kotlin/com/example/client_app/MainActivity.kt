package com.example.client_app

import io.flutter.embedding.android.FlutterActivity

import android.content.Intent
import android.net.Uri

class MainActivity : FlutterActivity() {

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        val data: Uri? = intent.data
        if (data != null && data.path?.contains("reset-password") == true) {
            val email = data.getQueryParameter("email")
            val token = data.getQueryParameter("token")
            // TODO: Open your ResetPassword screen with these values
        }
    }
}

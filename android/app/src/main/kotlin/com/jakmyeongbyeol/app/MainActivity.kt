package com.jakmyeongbyeol.app

import android.content.Intent
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "jakmyeongbyeol/app_links"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            channelName
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "openUrl" -> {
                    val url = call.argument<String>("url")
                    if (url.isNullOrBlank()) {
                        result.error("ARG", "url missing", null)
                    } else {
                        startActivity(Intent(Intent.ACTION_VIEW, Uri.parse(url)))
                        result.success(true)
                    }
                }
                "sendEmail" -> {
                    val email = call.argument<String>("email")
                    val subject = call.argument<String>("subject") ?: ""
                    if (email.isNullOrBlank()) {
                        result.error("ARG", "email missing", null)
                    } else {
                        val intent = Intent(Intent.ACTION_SENDTO).apply {
                            data = Uri.parse("mailto:$email")
                            putExtra(Intent.EXTRA_SUBJECT, subject)
                        }
                        // 메일 앱이 없는 기기에서 startActivity가
                        // ActivityNotFoundException으로 크래시 나는 것을 방지.
                        if (intent.resolveActivity(packageManager) == null) {
                            result.error(
                                "NO_MAIL_APP",
                                "메일 앱이 설치되어 있지 않습니다",
                                null
                            )
                        } else {
                            try {
                                startActivity(
                                    Intent.createChooser(intent, "문의하기")
                                )
                                result.success(true)
                            } catch (e: Exception) {
                                result.error("LAUNCH_FAILED", e.message, null)
                            }
                        }
                    }
                }
                "shareText" -> {
                    val text = call.argument<String>("text")
                    if (text.isNullOrBlank()) {
                        result.error("ARG", "text missing", null)
                    } else {
                        val intent = Intent(Intent.ACTION_SEND).apply {
                            type = "text/plain"
                            putExtra(Intent.EXTRA_TEXT, text)
                        }
                        startActivity(Intent.createChooser(intent, "공유하기"))
                        result.success(true)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }
}

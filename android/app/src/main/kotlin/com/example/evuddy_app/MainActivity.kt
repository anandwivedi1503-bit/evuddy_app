package com.example.evuddy_app

import android.content.Intent
import androidx.activity.result.contract.ActivityResultContracts
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    private var payResult: MethodChannel.Result? = null

    private val payLauncher =
        registerForActivityResult(ActivityResultContracts.StartActivityForResult()) { res ->
            val payload = res.data?.getStringExtra(RazorpayWebActivity.EXTRA_PAYLOAD)
            payResult?.success(payload)
            payResult = null
        }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method != "open") {
                result.notImplemented()
                return@setMethodCallHandler
            }
            if (payResult != null) {
                result.error("busy", "Checkout already open.", null)
                return@setMethodCallHandler
            }
            val html = call.argument<String>("html")
            val options = call.argument<String>("options")
            if (html.isNullOrEmpty() || options.isNullOrEmpty()) {
                result.error("args", "html and options are required.", null)
                return@setMethodCallHandler
            }
            payResult = result
            val intent = Intent(this, RazorpayWebActivity::class.java)
            intent.putExtra(RazorpayWebActivity.EXTRA_HTML, html)
            intent.putExtra(RazorpayWebActivity.EXTRA_OPTIONS, options)
            payLauncher.launch(intent)
        }
    }

    companion object {
        private const val CHANNEL = "evuddy/razorpay"
    }
}

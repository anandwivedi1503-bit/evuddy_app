package com.example.evuddy_app

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.os.Message
import android.view.ViewGroup
import android.webkit.CookieManager
import android.webkit.JavascriptInterface
import android.webkit.WebChromeClient
import android.webkit.WebResourceRequest
import android.webkit.WebSettings
import android.webkit.WebView
import android.webkit.WebViewClient
import android.widget.FrameLayout
import org.json.JSONObject

class RazorpayWebActivity : Activity() {
    private lateinit var root: FrameLayout
    private lateinit var webView: WebView
    private lateinit var optionsJson: String
    private var opened = false

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        optionsJson = intent.getStringExtra(EXTRA_OPTIONS) ?: "{}"
        val html = intent.getStringExtra(EXTRA_HTML) ?: ""
        root = FrameLayout(this)
        setContentView(root)
        webView = newWebView(primary = true)
        root.addView(
            webView,
            FrameLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.MATCH_PARENT,
            ),
        )
        CookieManager.getInstance().setAcceptCookie(true)
        CookieManager.getInstance().setAcceptThirdPartyCookies(webView, true)
        webView.loadDataWithBaseURL(
            "https://www.evuddy.com",
            html,
            "text/html",
            "UTF-8",
            null,
        )
    }

    private fun newWebView(primary: Boolean): WebView {
        val view = WebView(this)
        view.settings.javaScriptEnabled = true
        view.settings.javaScriptCanOpenWindowsAutomatically = true
        view.settings.setSupportMultipleWindows(true)
        view.settings.domStorageEnabled = true
        view.settings.databaseEnabled = true
        view.settings.mixedContentMode = WebSettings.MIXED_CONTENT_ALWAYS_ALLOW
        view.settings.javaScriptEnabled = true
        if (primary) {
            view.addJavascriptInterface(PayBridge(), "PayBridge")
        }
        view.webViewClient =
            object : WebViewClient() {
                override fun shouldOverrideUrlLoading(
                    view: WebView,
                    request: WebResourceRequest,
                ): Boolean = handleUri(request.url)

                @Deprecated("Deprecated in Java")
                override fun shouldOverrideUrlLoading(view: WebView, url: String): Boolean =
                    handleUri(Uri.parse(url))
            }
        view.webChromeClient =
            object : WebChromeClient() {
                override fun onCreateWindow(
                    view: WebView,
                    isDialog: Boolean,
                    isUserGesture: Boolean,
                    resultMsg: Message,
                ): Boolean {
                    val child = newWebView(primary = false)
                    root.addView(
                        child,
                        FrameLayout.LayoutParams(
                            ViewGroup.LayoutParams.MATCH_PARENT,
                            ViewGroup.LayoutParams.MATCH_PARENT,
                        ),
                    )
                    val transport = resultMsg.obj as WebView.WebViewTransport
                    transport.webView = child
                    resultMsg.sendToTarget()
                    return true
                }

                override fun onCloseWindow(window: WebView) {
                    if (window != webView) {
                        root.removeView(window)
                        window.destroy()
                    }
                }
            }
        return view
    }

    private fun handleUri(uri: Uri): Boolean {
        val scheme = uri.scheme?.lowercase() ?: return false
        if (scheme == "http" || scheme == "https" || scheme == "about") return false
        return try {
            startActivity(Intent(Intent.ACTION_VIEW, uri))
            true
        } catch (_: Exception) {
            false
        }
    }

    private fun finishWith(payload: String?) {
        val data = Intent()
        if (payload != null) data.putExtra(EXTRA_PAYLOAD, payload)
        setResult(if (payload != null) RESULT_OK else RESULT_CANCELED, data)
        finish()
    }

    @Deprecated("Deprecated in Java")
    override fun onBackPressed() {
        if (root.childCount > 1) {
            val top = root.getChildAt(root.childCount - 1)
            root.removeView(top)
            if (top is WebView) top.destroy()
            return
        }
        finishWith(null)
    }

    inner class PayBridge {
        @JavascriptInterface
        fun postMessage(message: String) {
            runOnUiThread {
                val json =
                    try {
                        JSONObject(message)
                    } catch (_: Exception) {
                        return@runOnUiThread
                    }
                when (json.optString("type")) {
                    "ready" -> {
                        if (opened) return@runOnUiThread
                        opened = true
                        val js = "openPay($optionsJson)"
                        webView.evaluateJavascript(js, null)
                    }
                    "success", "failed", "dismiss" -> finishWith(message)
                }
            }
        }
    }

    companion object {
        const val EXTRA_HTML = "html"
        const val EXTRA_OPTIONS = "options"
        const val EXTRA_PAYLOAD = "payload"
    }
}

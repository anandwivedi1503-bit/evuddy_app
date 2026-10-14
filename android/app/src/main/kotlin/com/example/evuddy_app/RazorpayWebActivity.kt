package com.example.evuddy_app

import android.app.Activity
import android.content.Intent
import android.graphics.Color
import android.os.Bundle
import android.os.Message
import android.view.ViewGroup
import android.webkit.CookieManager
import android.webkit.JavascriptInterface
import android.webkit.PermissionRequest
import android.webkit.WebChromeClient
import android.webkit.WebResourceRequest
import android.webkit.WebSettings
import android.webkit.WebView
import android.webkit.WebViewClient
import android.widget.FrameLayout
import org.json.JSONObject

/**
 * Full-screen checkout.js host — same Razorpay Standard Checkout as evuddy.com/book-bike.
 * Extra windows are required so Razorpay's Continue / 3DS / UPI sheet can proceed.
 */
class RazorpayWebActivity : Activity() {
    private lateinit var container: FrameLayout
    private lateinit var main: WebView
    private var popup: WebView? = null
    private var finished = false
    private var opened = false
    private var optionsJson = "{}"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        container = FrameLayout(this)
        container.setBackgroundColor(Color.WHITE)
        setContentView(
            container,
            ViewGroup.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.MATCH_PARENT,
            ),
        )

        CookieManager.getInstance().setAcceptCookie(true)
        optionsJson = intent.getStringExtra(EXTRA_OPTIONS) ?: "{}"
        val html = intent.getStringExtra(EXTRA_HTML) ?: ""

        main = newWebView()
        main.addJavascriptInterface(Bridge(), "PayBridge")
        main.webChromeClient = chrome()
        main.webViewClient = client()
        container.addView(
            main,
            FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.MATCH_PARENT,
            ),
        )
        main.loadDataWithBaseURL(
            "https://www.evuddy.com/",
            html,
            "text/html",
            "UTF-8",
            null,
        )
    }

    private fun chrome(): WebChromeClient {
        return object : WebChromeClient() {
            override fun onCreateWindow(
                view: WebView?,
                isDialog: Boolean,
                isUserGesture: Boolean,
                resultMsg: Message?,
            ): Boolean {
                val extra = newWebView()
                extra.webChromeClient = this
                extra.webViewClient = client()
                dropPopup()
                popup = extra
                container.addView(
                    extra,
                    FrameLayout.LayoutParams(
                        FrameLayout.LayoutParams.MATCH_PARENT,
                        FrameLayout.LayoutParams.MATCH_PARENT,
                    ),
                )
                val transport = resultMsg?.obj as? WebView.WebViewTransport
                transport?.webView = extra
                resultMsg?.sendToTarget()
                return true
            }

            override fun onCloseWindow(window: WebView) {
                if (window != main) {
                    container.removeView(window)
                    window.destroy()
                    if (popup === window) popup = null
                }
            }

            override fun onPermissionRequest(request: PermissionRequest?) {
                request?.grant(request.resources)
            }
        }
    }

    private fun client(): WebViewClient {
        return object : WebViewClient() {
            override fun shouldOverrideUrlLoading(
                view: WebView,
                request: WebResourceRequest,
            ): Boolean = handleUrl(request.url.toString())
        }
    }

    private fun handleUrl(url: String): Boolean {
        val lower = url.lowercase()
        if (
            lower.startsWith("http://") ||
            lower.startsWith("https://") ||
            lower.startsWith("about:") ||
            lower.startsWith("javascript:") ||
            lower.startsWith("blob:") ||
            lower.startsWith("data:")
        ) {
            return false
        }
        // Stay on Razorpay (UPI QR / UPI ID / card). Do not jump to GPay / PhonePe.
        return true
    }

    private fun newWebView(): WebView {
        val web = WebView(this)
        val settings = web.settings
        settings.javaScriptEnabled = true
        settings.domStorageEnabled = true
        settings.databaseEnabled = true
        settings.javaScriptCanOpenWindowsAutomatically = true
        settings.setSupportMultipleWindows(true)
        settings.mixedContentMode = WebSettings.MIXED_CONTENT_ALWAYS_ALLOW
        settings.cacheMode = WebSettings.LOAD_DEFAULT
        settings.useWideViewPort = true
        settings.loadWithOverviewMode = true
        settings.builtInZoomControls = false
        settings.displayZoomControls = false
        settings.mediaPlaybackRequiresUserGesture = false
        settings.allowContentAccess = true
        CookieManager.getInstance().setAcceptThirdPartyCookies(web, true)
        web.setBackgroundColor(Color.WHITE)
        return web
    }

    private fun dropPopup() {
        val extra = popup ?: return
        container.removeView(extra)
        extra.destroy()
        popup = null
    }

    private fun openCheckout() {
        if (opened) return
        opened = true
        main.evaluateJavascript("openPay($optionsJson)", null)
    }

    inner class Bridge {
        @JavascriptInterface
        fun postMessage(msg: String) {
            runOnUiThread {
                val type =
                    try {
                        JSONObject(msg).optString("type")
                    } catch (_: Exception) {
                        ""
                    }
                when (type) {
                    "ready" -> openCheckout()
                    "success", "failed", "dismiss" -> finishWith(msg)
                    else -> {}
                }
            }
        }
    }

    private fun finishWith(payload: String) {
        if (finished) return
        finished = true
        val data = Intent()
        data.putExtra(EXTRA_PAYLOAD, payload)
        setResult(RESULT_OK, data)
        finish()
    }

    @Deprecated("Deprecated in Java")
    override fun onBackPressed() {
        val extra = popup
        if (extra != null) {
            if (extra.canGoBack()) {
                extra.goBack()
            } else {
                dropPopup()
            }
            return
        }
        if (main.canGoBack()) {
            main.goBack()
        } else {
            finishWith("""{"type":"dismiss"}""")
        }
    }

    override fun onDestroy() {
        dropPopup()
        main.destroy()
        super.onDestroy()
    }

    companion object {
        const val EXTRA_HTML = "html"
        const val EXTRA_OPTIONS = "options"
        const val EXTRA_PAYLOAD = "payload"
    }
}

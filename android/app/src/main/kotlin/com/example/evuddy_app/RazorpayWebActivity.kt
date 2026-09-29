package com.example.evuddy_app

import androidx.appcompat.app.AppCompatActivity
import com.razorpay.Checkout
import com.razorpay.PaymentData
import com.razorpay.PaymentResultWithDataListener
import org.json.JSONObject

class RazorpayWebActivity : AppCompatActivity(), PaymentResultWithDataListener {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        Checkout.preload(applicationContext)
        val raw = intent.getStringExtra(EXTRA_OPTIONS) ?: "{}"
        val options = JSONObject(raw)
        val key = options.optString("key")
        val checkout = Checkout()
        if (key.isNotEmpty()) checkout.setKeyID(key)
        try {
            checkout.open(this, options)
        } catch (e: Exception) {
            finishWith(
                JSONObject()
                    .put("type", "failed")
                    .put("message", e.message ?: "Unable to open Razorpay.")
                    .toString(),
            )
        }
    }

    override fun onPaymentSuccess(razorpayPaymentId: String?, data: PaymentData?) {
        finishWith(
            JSONObject()
                .put("type", "success")
                .put("razorpay_payment_id", razorpayPaymentId ?: data?.paymentId ?: "")
                .put("razorpay_order_id", data?.orderId ?: "")
                .put("razorpay_signature", data?.signature ?: "")
                .toString(),
        )
    }

    override fun onPaymentError(code: Int, response: String?, data: PaymentData?) {
        val message =
            try {
                JSONObject(response ?: "{}").optJSONObject("error")?.optString("description")
                    ?: response
                    ?: "Payment failed."
            } catch (_: Exception) {
                response ?: "Payment failed."
            }
        finishWith(
            JSONObject()
                .put("type", "failed")
                .put("message", message)
                .toString(),
        )
    }

    @Deprecated("Deprecated in Java")
    override fun onBackPressed() {
        finishWith(JSONObject().put("type", "dismiss").toString())
    }

    private fun finishWith(payload: String) {
        setResult(RESULT_OK, Intent().putExtra(EXTRA_PAYLOAD, payload))
        finish()
    }

    companion object {
        const val EXTRA_HTML = "html"
        const val EXTRA_OPTIONS = "options"
        const val EXTRA_PAYLOAD = "payload"
    }
}

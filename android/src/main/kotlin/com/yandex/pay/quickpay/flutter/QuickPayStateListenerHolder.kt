package com.yandex.pay.quickpay.flutter

import com.yandex.pay.quickpay.api.IsPaymentEnabled
import com.yandex.pay.quickpay.api.QuickPayResult
import com.yandex.pay.quickpay.api.QuickPaymentStateListener

/**
 * Singleton holder for QuickPaymentStateListener.
 * Used to bridge between native initialization and Flutter plugin.
 */
internal object QuickPayStateListenerHolder {

    private var callback: Callback? = null

    val listener = object : QuickPaymentStateListener {
        override fun onPaymentEnabledStateChanged(isEnabled: IsPaymentEnabled) {
            callback?.onPaymentEnabledStateChanged(isEnabled)
        }

        override fun onSessionExpired() {
            callback?.onSessionExpired()
        }

        override fun onPaymentResult(quickpayResult: QuickPayResult) {
            callback?.onPaymentResult(quickpayResult)
        }
    }

    fun setCallback(callback: Callback?) {
        this.callback = callback
    }

    interface Callback {
        fun onPaymentEnabledStateChanged(isEnabled: IsPaymentEnabled)
        fun onSessionExpired()
        fun onPaymentResult(quickpayResult: QuickPayResult)
    }
}


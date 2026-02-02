package com.yandex.pay.quickpay.flutter

import android.app.Application
import androidx.fragment.app.FragmentActivity
import com.yandex.pay.quickpay.api.IsPaymentEnabled
import com.yandex.pay.quickpay.api.QuickPayConfig
import com.yandex.pay.quickpay.api.QuickPayEnvironment
import com.yandex.pay.quickpay.api.QuickPayLocale
import com.yandex.pay.quickpay.api.QuickPayResult
import com.yandex.pay.quickpay.api.QuickPayThemeColorScheme
import com.yandex.pay.quickpay.api.YandexQuickPay

internal class QuickPayImpl(
    private val eventSender: EventSender,
) {
    private val stateCallback = object : QuickPayStateListenerHolder.Callback {
        override fun onPaymentEnabledStateChanged(isEnabled: IsPaymentEnabled) {
            eventSender.sendEvent(
                mapOf(
                    ChannelKeys.TYPE to EventTypes.PAYMENT_ENABLED_STATE_CHANGED,
                    ChannelKeys.IS_ENABLED to isEnabled.value,
                )
            )
        }

        override fun onSessionExpired() {
            eventSender.sendEvent(mapOf(ChannelKeys.TYPE to EventTypes.SESSION_EXPIRED))
        }

        override fun onPaymentResult(quickpayResult: QuickPayResult) {
            val resultValue = when (quickpayResult) {
                is QuickPayResult.Success -> ResultValues.SUCCESS
                is QuickPayResult.Failure -> ResultValues.FAILURE
            }
            eventSender.sendEvent(
                mapOf(
                    ChannelKeys.TYPE to EventTypes.PAYMENT_RESULT,
                    ChannelKeys.RESULT to resultValue,
                )
            )
        }
    }

    fun initialize(
        context: Application,
        config: QuickPayConfig,
        locale: QuickPayLocale,
        theme: QuickPayThemeColorScheme,
    ) {
        YandexQuickPay.locale = locale
        YandexQuickPay.theme = theme

        YandexQuickPay.initialize(
            context = context,
            config = config,
            quickPaymentStateListener = QuickPayStateListenerHolder.listener,
        )
        QuickPayStateListenerHolder.setCallback(stateCallback)
    }

    fun setStateListener() {
        QuickPayStateListenerHolder.setCallback(stateCallback)
    }

    suspend fun initUi(activity: FragmentActivity) {
        YandexQuickPay.initUi(
            activity = activity,
            fragmentManager = activity.supportFragmentManager,
        )
    }

    suspend fun isQuickPaymentEnabled(): Boolean {
        return try {
            YandexQuickPay.isQuickPaymentEnabled().value
        } catch (e: Exception) {
            // Return false if user is not authorized or other error occurs
            false
        }
    }

    suspend fun enableQuickPayment(): Boolean {
        return YandexQuickPay.enableQuickPayment().isSuccess
    }

    suspend fun disableQuickPayment(): Boolean {
        return YandexQuickPay.disableQuickPayment().isSuccess
    }

    suspend fun getPaymentSessionId(): String {
        return YandexQuickPay.getPaymentSessionId()
    }

    fun logout() {
        YandexQuickPay.logout()
    }
}

internal fun interface EventSender {
    fun sendEvent(event: Map<String, Any?>)
}


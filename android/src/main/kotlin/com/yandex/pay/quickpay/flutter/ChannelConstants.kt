package com.yandex.pay.quickpay.flutter

internal object ChannelConstants {
    const val METHOD_CHANNEL_NAME = "yandex_quick_pay/methods"
    const val EVENT_CHANNEL_NAME = "yandex_quick_pay/events"
    const val PLATFORM_VIEW_TYPE = "yandex_quick_pay/payment_methods"
    const val ACTIVE_PAYMENT_METHOD_BADGE_VIEW_TYPE = "yandex_quick_pay/active_payment_method_badge"
}

internal object MethodNames {
    const val INITIALIZE = "initialize"
    const val IS_QUICK_PAYMENT_ENABLED = "isQuickPaymentEnabled"
    const val ENABLE_QUICK_PAYMENT = "enableQuickPayment"
    const val DISABLE_QUICK_PAYMENT = "disableQuickPayment"
    const val GET_PAYMENT_SESSION_ID = "getPaymentSessionId"
    const val LOGIN = "login"
    const val LOGOUT = "logout"
    const val HANDLE_USER_ACTIVITY = "handleUserActivity"
    const val HANDLE_OPEN_URL = "handleOpenURL"
    const val SHOW_ACTIVE_PAYMENT_METHOD = "showActivePaymentMethod"
    const val HIDE_ACTIVE_PAYMENT_METHOD = "hideActivePaymentMethod"
}

internal object EventTypes {
    const val PAYMENT_ENABLED_STATE_CHANGED = "paymentEnabledStateChanged"
    const val SESSION_EXPIRED = "sessionExpired"
    const val PAYMENT_RESULT = "paymentResult"
}

internal object ChannelKeys {
    const val TYPE = "type"
    const val MERCHANT_ID = "merchantId"
    const val ENVIRONMENT = "environment"
    const val LOCALE = "locale"
    const val THEME = "theme"
    const val IS_ENABLED = "isEnabled"
    const val SUCCESS = "success"
    const val SESSION_ID = "sessionId"
    const val RESULT = "result"
    const val URL = "url"
    const val HANDLED = "handled"
}

internal object ResultValues {
    const val SUCCESS = "success"
    const val FAILURE = "failure"
}

internal object ErrorCodes {
    const val NOT_INITIALIZED = "NOT_INITIALIZED"
    const val INVALID_ARGUMENT = "INVALID_ARGUMENT"
    const val SDK_ERROR = "SDK_ERROR"
    const val SESSION_ERROR = "SESSION_ERROR"
}


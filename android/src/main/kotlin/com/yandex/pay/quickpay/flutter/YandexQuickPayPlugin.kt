package com.yandex.pay.quickpay.flutter

import android.app.Application
import androidx.fragment.app.FragmentActivity
import com.yandex.pay.quickpay.api.QuickPayConfig
import com.yandex.pay.quickpay.api.QuickPayEnvironment
import com.yandex.pay.quickpay.api.QuickPayLocale
import com.yandex.pay.quickpay.api.QuickPayThemeColorScheme
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch

class YandexQuickPayPlugin : FlutterPlugin, MethodCallHandler, ActivityAware, EventChannel.StreamHandler {

    private var methodChannel: MethodChannel? = null
    private var eventChannel: EventChannel? = null
    private var eventSink: EventChannel.EventSink? = null

    private var activity: FragmentActivity? = null
    private var applicationContext: Application? = null

    private var isInitialized = false

    private val coroutineScope = CoroutineScope(SupervisorJob() + Dispatchers.Main)

    private val quickPayImpl by lazy {
        QuickPayImpl(eventSender = { event -> eventSink?.success(event) })
    }

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        applicationContext = flutterPluginBinding.applicationContext as Application

        methodChannel = MethodChannel(flutterPluginBinding.binaryMessenger, ChannelConstants.METHOD_CHANNEL_NAME)
        methodChannel?.setMethodCallHandler(this)

        eventChannel = EventChannel(flutterPluginBinding.binaryMessenger, ChannelConstants.EVENT_CHANNEL_NAME)
        eventChannel?.setStreamHandler(this)

        // Register platform view for payment methods widget
        flutterPluginBinding.platformViewRegistry.registerViewFactory(
            ChannelConstants.PLATFORM_VIEW_TYPE,
            PaymentMethodsViewFactory(
                messenger = flutterPluginBinding.binaryMessenger,
                activityProvider = { activity },
            ),
        )

        // Register platform view for active payment method badge
        flutterPluginBinding.platformViewRegistry.registerViewFactory(
            ChannelConstants.ACTIVE_PAYMENT_METHOD_BADGE_VIEW_TYPE,
            ActivePaymentMethodBadgeViewFactory(
                messenger = flutterPluginBinding.binaryMessenger,
                activityProvider = { activity },
            ),
        )
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel?.setMethodCallHandler(null)
        methodChannel = null

        eventChannel?.setStreamHandler(null)
        eventChannel = null

        coroutineScope.cancel()
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity as? FragmentActivity

        // On Android, SDK is initialized in QuickPayFlutterActivity.onCreate
        // (because registerForActivityResult must be called before STARTED state)
        isInitialized = true
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity as? FragmentActivity
    }

    override fun onDetachedFromActivity() {
        activity = null
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            MethodNames.INITIALIZE -> handleInitialize(call, result)
            MethodNames.IS_QUICK_PAYMENT_ENABLED -> handleIsQuickPaymentEnabled(result)
            MethodNames.ENABLE_QUICK_PAYMENT -> handleEnableQuickPayment(result)
            MethodNames.DISABLE_QUICK_PAYMENT -> handleDisableQuickPayment(result)
            MethodNames.GET_PAYMENT_SESSION_ID -> handleGetPaymentSessionId(result)
            MethodNames.LOGIN -> handleLogin(result)
            MethodNames.LOGOUT -> handleLogout(result)
            MethodNames.HANDLE_USER_ACTIVITY -> handleUserActivity(result)
            MethodNames.HANDLE_OPEN_URL -> handleOpenURL(result)
            MethodNames.SHOW_ACTIVE_PAYMENT_METHOD -> handleShowActivePaymentMethod(result)
            MethodNames.HIDE_ACTIVE_PAYMENT_METHOD -> handleHideActivePaymentMethod(result)
            else -> result.notImplemented()
        }
    }

    private fun handleInitialize(call: MethodCall, result: Result) {
        // On Android, SDK is initialized in QuickPayFlutterActivity.onCreate
        // (because registerForActivityResult must be called before STARTED state)
        // Here we just connect the event listener from Dart

        if (isInitialized) {
            quickPayImpl.setStateListener()
            result.success(null)
            return
        }

        // Fallback: initialize if not done yet
        val context = applicationContext
        if (context == null) {
            result.error(ErrorCodes.NOT_INITIALIZED, ERROR_MSG_CONTEXT_NOT_AVAILABLE, null)
            return
        }

        val merchantId = call.argument<String>(ChannelKeys.MERCHANT_ID)
        if (merchantId.isNullOrEmpty()) {
            result.error(ErrorCodes.INVALID_ARGUMENT, ERROR_MSG_MERCHANT_ID_REQUIRED, null)
            return
        }

        val config = QuickPayConfig(
            merchantId = merchantId,
            environment = call.argument<String>(ChannelKeys.ENVIRONMENT).toEnvironment(),
        )

        quickPayImpl.initialize(
            context = context,
            config = config,
            locale = call.argument<String>(ChannelKeys.LOCALE).toLocale(),
            theme = call.argument<String>(ChannelKeys.THEME).toTheme(),
        )

        isInitialized = true
        result.success(null)
    }

    private fun handleIsQuickPaymentEnabled(result: Result) {
        if (!isInitialized) {
            result.error(ErrorCodes.NOT_INITIALIZED, ERROR_MSG_SDK_NOT_INITIALIZED, null)
            return
        }
        coroutineScope.launch {
            try {
                val isEnabled = quickPayImpl.isQuickPaymentEnabled()
                result.success(mapOf(ChannelKeys.IS_ENABLED to isEnabled))
            } catch (e: Exception) {
                result.error(ErrorCodes.SDK_ERROR, e.message ?: ERROR_MSG_UNKNOWN, null)
            }
        }
    }

    private fun handleEnableQuickPayment(result: Result) {
        if (!isInitialized) {
            result.error(ErrorCodes.NOT_INITIALIZED, ERROR_MSG_SDK_NOT_INITIALIZED, null)
            return
        }
        coroutineScope.launch {
            try {
                val success = quickPayImpl.enableQuickPayment()
                result.success(mapOf(ChannelKeys.SUCCESS to success))
            } catch (e: Exception) {
                result.error(ErrorCodes.SDK_ERROR, e.message ?: ERROR_MSG_UNKNOWN, null)
            }
        }
    }

    private fun handleDisableQuickPayment(result: Result) {
        if (!isInitialized) {
            result.error(ErrorCodes.NOT_INITIALIZED, ERROR_MSG_SDK_NOT_INITIALIZED, null)
            return
        }
        coroutineScope.launch {
            try {
                val success = quickPayImpl.disableQuickPayment()
                result.success(mapOf(ChannelKeys.SUCCESS to success))
            } catch (e: Exception) {
                result.error(ErrorCodes.SDK_ERROR, e.message ?: ERROR_MSG_UNKNOWN, null)
            }
        }
    }

    private fun handleGetPaymentSessionId(result: Result) {
        if (!isInitialized) {
            result.error(ErrorCodes.NOT_INITIALIZED, ERROR_MSG_SDK_NOT_INITIALIZED, null)
            return
        }
        coroutineScope.launch {
            try {
                val sessionId = quickPayImpl.getPaymentSessionId()
                result.success(mapOf(ChannelKeys.SESSION_ID to sessionId))
            } catch (e: Exception) {
                result.error(ErrorCodes.SESSION_ERROR, e.message ?: ERROR_MSG_SESSION_FAILED, null)
            }
        }
    }

    private fun handleLogin(result: Result) {
        if (!isInitialized) {
            result.error(ErrorCodes.NOT_INITIALIZED, ERROR_MSG_SDK_NOT_INITIALIZED, null)
            return
        }
        coroutineScope.launch {
            try {
                val success = quickPayImpl.enableQuickPayment()
                result.success(mapOf(ChannelKeys.SUCCESS to success))
            } catch (e: Exception) {
                result.error(ErrorCodes.SDK_ERROR, e.message ?: ERROR_MSG_UNKNOWN, null)
            }
        }
    }

    private fun handleLogout(result: Result) {
        if (!isInitialized) {
            result.error(ErrorCodes.NOT_INITIALIZED, ERROR_MSG_SDK_NOT_INITIALIZED, null)
            return
        }
        try {
            quickPayImpl.logout()
            result.success(null)
        } catch (e: Exception) {
            result.error(ErrorCodes.SDK_ERROR, e.message ?: ERROR_MSG_UNKNOWN, null)
        }
    }

    private fun handleUserActivity(result: Result) {
        // Not supported on Android, always returns false
        result.success(mapOf(ChannelKeys.HANDLED to false))
    }

    private fun handleOpenURL(result: Result) {
        // Not supported on Android, always returns false
        result.success(mapOf(ChannelKeys.HANDLED to false))
    }

    private fun handleShowActivePaymentMethod(result: Result) {
        if (!isInitialized) {
            result.error(ErrorCodes.NOT_INITIALIZED, ERROR_MSG_SDK_NOT_INITIALIZED, null)
            return
        }
        try {
            quickPayImpl.showActivePaymentMethod()
            result.success(null)
        } catch (e: Exception) {
            result.error(ErrorCodes.SDK_ERROR, e.message ?: ERROR_MSG_UNKNOWN, null)
        }
    }

    private fun handleHideActivePaymentMethod(result: Result) {
        if (!isInitialized) {
            result.error(ErrorCodes.NOT_INITIALIZED, ERROR_MSG_SDK_NOT_INITIALIZED, null)
            return
        }
        try {
            quickPayImpl.hideActivePaymentMethod()
            result.success(null)
        } catch (e: Exception) {
            result.error(ErrorCodes.SDK_ERROR, e.message ?: ERROR_MSG_UNKNOWN, null)
        }
    }

    private fun String?.toEnvironment(): QuickPayEnvironment {
        return when (this?.lowercase()) {
            ENV_PRODUCTION -> QuickPayEnvironment.PRODUCTION
            else -> QuickPayEnvironment.SANDBOX
        }
    }

    private fun String?.toLocale(): QuickPayLocale {
        return when (this?.lowercase()) {
            LOCALE_RU -> QuickPayLocale.RU
            LOCALE_EN -> QuickPayLocale.EN
            else -> QuickPayLocale.SYSTEM
        }
    }

    private fun String?.toTheme(): QuickPayThemeColorScheme {
        return when (this?.lowercase()) {
            THEME_LIGHT -> QuickPayThemeColorScheme.LIGHT
            THEME_DARK -> QuickPayThemeColorScheme.DARK
            else -> QuickPayThemeColorScheme.SYSTEM
        }
    }

    private companion object {
        const val ERROR_MSG_CONTEXT_NOT_AVAILABLE = "Application context is not available"
        const val ERROR_MSG_MERCHANT_ID_REQUIRED = "merchantId is required"
        const val ERROR_MSG_UNKNOWN = "Unknown error"
        const val ERROR_MSG_SESSION_FAILED = "Failed to get session ID"
        const val ERROR_MSG_SDK_NOT_INITIALIZED = "SDK must be initialized first. Call initialize() before using other methods."

        const val ENV_PRODUCTION = "production"
        const val LOCALE_RU = "ru"
        const val LOCALE_EN = "en"
        const val THEME_LIGHT = "light"
        const val THEME_DARK = "dark"
    }
}

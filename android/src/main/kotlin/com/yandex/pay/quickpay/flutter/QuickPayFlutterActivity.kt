package com.yandex.pay.quickpay.flutter

import android.content.pm.PackageManager
import android.os.Bundle
import androidx.lifecycle.lifecycleScope
import com.yandex.pay.quickpay.api.QuickPayConfig
import com.yandex.pay.quickpay.api.QuickPayEnvironment
import com.yandex.pay.quickpay.api.YandexQuickPay
import io.flutter.embedding.android.FlutterFragmentActivity
import kotlinx.coroutines.launch

/**
 * Base Activity for Flutter apps using Yandex Quick Pay SDK.
 *
 * This Activity handles the early initialization required by the SDK.
 * The SDK uses registerForActivityResult which must be called before Activity reaches STARTED state.
 *
 * ## Setup
 *
 * 1. In your `MainActivity.kt`, inherit from `QuickPayFlutterActivity`:
 * ```kotlin
 * package com.example.myapp
 *
 * import com.yandex.pay.quickpay.flutter.QuickPayFlutterActivity
 *
 * class MainActivity : QuickPayFlutterActivity()
 * ```
 *
 * 2. In your `AndroidManifest.xml`, add merchant ID meta-data:
 * ```xml
 * <application ...>
 *     <meta-data
 *         android:name="com.yandex.pay.quickpay.MERCHANT_ID"
 *         android:value="your-merchant-id" />
 *     <!-- Optional: set to "production" for production environment -->
 *     <meta-data
 *         android:name="com.yandex.pay.quickpay.ENVIRONMENT"
 *         android:value="sandbox" />
 *     ...
 * </application>
 * ```
 */
open class QuickPayFlutterActivity : FlutterFragmentActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        initQuickPay()
    }

    private fun initQuickPay() {
        val appInfo = packageManager.getApplicationInfo(
            packageName,
            PackageManager.GET_META_DATA
        )
        val metaData = appInfo.metaData

        val merchantId = metaData?.getString(META_MERCHANT_ID)
        if (merchantId.isNullOrEmpty()) {
            throw IllegalStateException(
                "Yandex Quick Pay SDK requires MERCHANT_ID in AndroidManifest.xml.\n" +
                "Add the following meta-data to your <application> tag:\n" +
                "<meta-data android:name=\"$META_MERCHANT_ID\" android:value=\"your-merchant-id\" />"
            )
        }

        val envString = metaData.getString(META_ENVIRONMENT, "sandbox")
        val environment = when (envString?.lowercase()) {
            "production" -> QuickPayEnvironment.PRODUCTION
            else -> QuickPayEnvironment.SANDBOX
        }

        val config = QuickPayConfig(
            merchantId = merchantId,
            environment = environment,
        )

        YandexQuickPay.initialize(
            context = application,
            config = config,
            quickPaymentStateListener = QuickPayStateListenerHolder.listener,
        )

        lifecycleScope.launch {
            YandexQuickPay.initUi(
                activity = this@QuickPayFlutterActivity,
                fragmentManager = supportFragmentManager,
            )
        }
    }

    private companion object {
        const val META_MERCHANT_ID = "com.yandex.pay.quickpay.MERCHANT_ID"
        const val META_ENVIRONMENT = "com.yandex.pay.quickpay.ENVIRONMENT"
    }
}


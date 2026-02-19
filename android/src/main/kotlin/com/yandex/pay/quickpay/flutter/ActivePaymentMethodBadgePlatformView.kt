package com.yandex.pay.quickpay.flutter

import android.content.Context
import android.view.View
import android.view.ViewTreeObserver
import android.widget.FrameLayout
import com.yandex.pay.quickpay.api.YandexActivePaymentMethodBadge
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory
import kotlin.math.abs

internal class ActivePaymentMethodBadgeViewFactory(
    private val messenger: BinaryMessenger,
    private val activityProvider: () -> Context?,
) : PlatformViewFactory(StandardMessageCodec.INSTANCE) {

    override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
        val activityContext = activityProvider() ?: context
        return ActivePaymentMethodBadgePlatformView(activityContext, viewId, messenger)
    }
}

internal class ActivePaymentMethodBadgePlatformView(
    private val context: Context,
    viewId: Int,
    messenger: BinaryMessenger,
) : PlatformView {

    private val methodChannel = MethodChannel(
        messenger,
        "${ChannelConstants.ACTIVE_PAYMENT_METHOD_BADGE_VIEW_TYPE}/$viewId"
    )

    private val containerView = FrameLayout(context)
    private var widget: YandexActivePaymentMethodBadge? = null
    private var lastReportedHeight = 0f

    private fun reportHeight(view: View) {
        val density = context.resources.displayMetrics.density

        val widthSpec = View.MeasureSpec.makeMeasureSpec(view.width, View.MeasureSpec.EXACTLY)
        val heightSpec = View.MeasureSpec.makeMeasureSpec(0, View.MeasureSpec.UNSPECIFIED)
        view.measure(widthSpec, heightSpec)

        val measuredHeightDp = view.measuredHeight.toFloat() / density

        if (measuredHeightDp > 0 && abs(measuredHeightDp - lastReportedHeight) > 0.5f) {
            lastReportedHeight = measuredHeightDp
            methodChannel.invokeMethod("updateHeight", mapOf("height" to measuredHeightDp.toDouble()))
        }
    }

    private val globalLayoutListener = ViewTreeObserver.OnGlobalLayoutListener {
        widget?.let { reportHeight(it) }
    }

    init {
        try {
            widget = YandexActivePaymentMethodBadge(context).also { widgetView ->
                widgetView.viewTreeObserver.addOnGlobalLayoutListener(globalLayoutListener)

                containerView.addView(
                    widgetView,
                    FrameLayout.LayoutParams(
                        FrameLayout.LayoutParams.MATCH_PARENT,
                        FrameLayout.LayoutParams.WRAP_CONTENT
                    )
                )
            }
        } catch (_: Exception) {
        }
    }

    override fun getView(): View = containerView

    override fun dispose() {
        widget?.viewTreeObserver?.removeOnGlobalLayoutListener(globalLayoutListener)
        widget = null
    }
}

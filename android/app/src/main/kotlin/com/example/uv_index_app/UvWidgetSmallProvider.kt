package com.example.uv_index_app

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

class UvWidgetSmallProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        for (widgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.uv_widget_small_layout)

            val value = widgetData.getInt("uv_value", -1)
            // Fully opaque ARGB values (alpha 0xFF) exceed Int32's signed range,
            // so the platform channel sends them as Int64 — read as Long and
            // truncate to the 32-bit color int Android expects.
            val color = widgetData.getLong("uv_color", DEFAULT_COLOR).toInt()

            views.setTextViewText(R.id.widget_value, if (value >= 0) value.toString() else "--")
            views.setInt(R.id.widget_background, "setColorFilter", color)

            views.setOnClickPendingIntent(
                R.id.widget_root,
                HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java),
            )

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }

    companion object {
        // WHO "Low" green, matching UvScale.forValue's default band in Dart.
        private const val DEFAULT_COLOR = 0xFF558B2FL
    }
}

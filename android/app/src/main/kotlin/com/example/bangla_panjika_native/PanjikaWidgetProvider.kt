package com.example.bangla_panjika_native

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews

/**
 * বাংলা পঞ্জিকার হোম স্ক্রিন উইজেট।
 *
 * Flutter সাইডে home_widget প্যাকেজ "HomeWidgetPreferences" নামের একটা
 * SharedPreferences ফাইলে আজকের বাংলা তারিখ/তিথি লিখে রাখে (দেখুন
 * main.dart-এর HomeWidgetService ক্লাস) — এই ক্লাস শুধু সেই ডেটা পড়ে
 * উইজেটে দেখায়। home_widget প্যাকেজের কোনো Kotlin API সরাসরি ব্যবহার
 * করা হয়নি (শুধু Android-এর নিজস্ব AppWidgetProvider), যাতে প্যাকেজ
 * ভার্সন বদলালেও এই ফাইলটা ভাঙে না।
 */
class PanjikaWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        val prefs = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
        val bengaliDate = prefs.getString("bengali_date", "বাংলা পঞ্জিকা") ?: "বাংলা পঞ্জিকা"
        val tithiText = prefs.getString("tithi_text", "") ?: ""

        val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)
        val pendingIntent = if (launchIntent != null) {
            PendingIntent.getActivity(
                context,
                0,
                launchIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
        } else {
            null
        }

        for (widgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.panjika_widget)
            views.setTextViewText(R.id.widget_bengali_date, bengaliDate)
            views.setTextViewText(R.id.widget_tithi, tithiText)
            if (pendingIntent != null) {
                views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}

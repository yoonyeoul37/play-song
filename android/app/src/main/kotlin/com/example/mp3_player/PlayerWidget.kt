package com.example.mp3_player

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews

class PlayerWidget : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        when (intent.action) {
            ACTION_PLAY_PAUSE -> {
                val keyEvent = android.view.KeyEvent(
                    android.view.KeyEvent.ACTION_DOWN,
                    android.view.KeyEvent.KEYCODE_MEDIA_PLAY_PAUSE
                )
                val mediaIntent = Intent(Intent.ACTION_MEDIA_BUTTON)
                mediaIntent.putExtra(Intent.EXTRA_KEY_EVENT, keyEvent)
                context.sendOrderedBroadcast(mediaIntent, null)
            }
            ACTION_NEXT -> {
                val keyEvent = android.view.KeyEvent(
                    android.view.KeyEvent.ACTION_DOWN,
                    android.view.KeyEvent.KEYCODE_MEDIA_NEXT
                )
                val mediaIntent = Intent(Intent.ACTION_MEDIA_BUTTON)
                mediaIntent.putExtra(Intent.EXTRA_KEY_EVENT, keyEvent)
                context.sendOrderedBroadcast(mediaIntent, null)
            }
            ACTION_PREV -> {
                val keyEvent = android.view.KeyEvent(
                    android.view.KeyEvent.ACTION_DOWN,
                    android.view.KeyEvent.KEYCODE_MEDIA_PREVIOUS
                )
                val mediaIntent = Intent(Intent.ACTION_MEDIA_BUTTON)
                mediaIntent.putExtra(Intent.EXTRA_KEY_EVENT, keyEvent)
                context.sendOrderedBroadcast(mediaIntent, null)
            }
        }
    }

    companion object {
        const val ACTION_PLAY_PAUSE = "com.example.mp3_player.PLAY_PAUSE"
        const val ACTION_NEXT = "com.example.mp3_player.NEXT"
        const val ACTION_PREV = "com.example.mp3_player.PREV"

        fun updateAppWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int,
            title: String = "플레이쏭",
            artist: String = "음악을 재생해보세요",
            isPlaying: Boolean = false
        ) {
            val views = RemoteViews(context.packageName, R.layout.widget_player)

            views.setTextViewText(R.id.widget_title, title)
            views.setTextViewText(R.id.widget_artist, artist)

            val playPauseIcon = if (isPlaying)
                android.R.drawable.ic_media_pause
            else
                android.R.drawable.ic_media_play
            views.setImageViewResource(R.id.widget_play_pause, playPauseIcon)

            val openIntent = Intent(context, MainActivity::class.java)
            val openPendingIntent = PendingIntent.getActivity(
                context, 0, openIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_title, openPendingIntent)

            val prevIntent = Intent(ACTION_PREV).apply { setPackage(context.packageName) }
            val prevPendingIntent = PendingIntent.getBroadcast(
                context, 1, prevIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_prev, prevPendingIntent)

            val playPauseIntent = Intent(ACTION_PLAY_PAUSE).apply { setPackage(context.packageName) }
            val playPausePendingIntent = PendingIntent.getBroadcast(
                context, 2, playPauseIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_play_pause, playPausePendingIntent)

            val nextIntent = Intent(ACTION_NEXT).apply { setPackage(context.packageName) }
            val nextPendingIntent = PendingIntent.getBroadcast(
                context, 3, nextIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_next, nextPendingIntent)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
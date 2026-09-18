package com.minharotina.minha_rotina

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.graphics.Color
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import org.json.JSONArray

/**
 * Widget de tela inicial (Etapa 13): mostra a categoria do dia (cor e
 * nome) e a posição no ciclo, sem precisar abrir o app.
 *
 * Os dados vêm pré-calculados pelo lado Dart (WidgetService, uma janela
 * de ~30 dias salva em [widgetData]) — este código nunca calcula a
 * escala, só escolhe a entrada de hoje dentro do que já foi salvo e
 * desenha. Isso é o que permite o widget continuar certo por semanas sem
 * o app precisar estar aberto: o [HomeWidgetScheduledUpdateReceiver] do
 * próprio plugin (agendado via `HomeWidget.scheduleWidgetUpdates`) chama
 * este `onUpdate` de novo à meia-noite de cada dia.
 */
class MinhaRotinaWidgetProvider : HomeWidgetProvider() {

  private data class TodayEntry(
      val label: String,
      val colorHex: String,
      val cycleLabel: String,
  )

  override fun onUpdate(
      context: Context,
      appWidgetManager: AppWidgetManager,
      appWidgetIds: IntArray,
      widgetData: SharedPreferences,
  ) {
    val todayIso = SimpleDateFormat("yyyy-MM-dd", Locale.US).format(Date())
    val entry = findTodayEntry(widgetData, todayIso)

    appWidgetIds.forEach { widgetId ->
      val views =
          RemoteViews(context.packageName, R.layout.widget_today_layout).apply {
            setTextViewText(R.id.widget_today_label, entry.label)
            setTextViewText(R.id.widget_today_cycle, entry.cycleLabel)
            setInt(R.id.widget_today_dot, "setColorFilter", parseColor(entry.colorHex))

            val pendingIntent =
                HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java)
            setOnClickPendingIntent(R.id.widget_today_container, pendingIntent)
          }
      appWidgetManager.updateAppWidget(widgetId, views)
    }
  }

  private fun findTodayEntry(widgetData: SharedPreferences, todayIso: String): TodayEntry {
    val fallback = TodayEntry("Minha Rotina", "#6B7280", "Abra o app para atualizar")
    val raw = widgetData.getString("schedule_days", null) ?: return fallback
    return try {
      val days = JSONArray(raw)
      for (i in 0 until days.length()) {
        val item = days.getJSONObject(i)
        if (item.getString("date") == todayIso) {
          val cycleLabel =
              if (item.isNull("cycleDayNumber") || item.isNull("cycleDayCount")) {
                ""
              } else {
                "Dia ${item.getInt("cycleDayNumber")} de ${item.getInt("cycleDayCount")}"
              }
          return TodayEntry(
              item.optString("label", fallback.label),
              item.optString("color", fallback.colorHex),
              cycleLabel,
          )
        }
      }
      fallback
    } catch (e: Exception) {
      // Dados ausentes/corrompidos — mostra o padrão em vez de quebrar o widget.
      fallback
    }
  }

  private fun parseColor(hex: String): Int {
    return try {
      Color.parseColor(hex)
    } catch (e: IllegalArgumentException) {
      Color.parseColor("#6B7280")
    }
  }
}

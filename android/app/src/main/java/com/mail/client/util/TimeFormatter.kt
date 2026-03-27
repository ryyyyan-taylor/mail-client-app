package com.mail.client.util

import java.text.DateFormat
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import java.util.Locale

object TimeFormatter {
    fun format(timestamp: Long): String {
        if (timestamp == 0L) return ""
        val msg = Calendar.getInstance().apply { timeInMillis = timestamp }
        val now = Calendar.getInstance()

        return when {
            msg.get(Calendar.YEAR) == now.get(Calendar.YEAR) &&
            msg.get(Calendar.DAY_OF_YEAR) == now.get(Calendar.DAY_OF_YEAR) ->
                DateFormat.getTimeInstance(DateFormat.SHORT).format(Date(timestamp))

            msg.get(Calendar.YEAR) == now.get(Calendar.YEAR) ->
                SimpleDateFormat("MMM d", Locale.getDefault()).format(Date(timestamp))

            else ->
                SimpleDateFormat("MMM d, yy", Locale.getDefault()).format(Date(timestamp))
        }
    }
}

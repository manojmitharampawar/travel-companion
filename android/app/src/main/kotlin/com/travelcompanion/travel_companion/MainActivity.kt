package com.travelcompanion.travel_companion

import android.content.ContentResolver
import android.database.Cursor
import android.net.Uri
import android.provider.Telephony
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val SMS_CHANNEL = "com.travelcompanion/sms"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SMS_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getIrctcMessages" -> {
                    val senderIds = call.argument<List<String>>("senderIds") ?: emptyList()
                    val afterTimestamp = call.argument<Long>("afterTimestamp") ?: 0L

                    try {
                        val messages = readSmsMessages(senderIds, afterTimestamp)
                        result.success(messages)
                    } catch (e: SecurityException) {
                        result.error("PERMISSION_DENIED", "SMS permission not granted", null)
                    } catch (e: Exception) {
                        result.error("ERROR", e.message, null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun readSmsMessages(
        senderIds: List<String>,
        afterTimestamp: Long
    ): List<Map<String, Any>> {
        val messages = mutableListOf<Map<String, Any>>()
        val contentResolver: ContentResolver = applicationContext.contentResolver

        // Build selection query for IRCTC senders
        val selectionArgs = mutableListOf<String>()
        val senderConditions = senderIds.map { sender ->
            selectionArgs.add("%$sender%")
            "address LIKE ?"
        }.joinToString(" OR ")

        var selection = "($senderConditions)"
        if (afterTimestamp > 0) {
            selection += " AND date > ?"
            selectionArgs.add(afterTimestamp.toString())
        }

        val cursor: Cursor? = contentResolver.query(
            Telephony.Sms.Inbox.CONTENT_URI,
            arrayOf("address", "body", "date"),
            selection,
            selectionArgs.toTypedArray(),
            "date DESC"
        )

        cursor?.use {
            val addressIndex = it.getColumnIndex("address")
            val bodyIndex = it.getColumnIndex("body")
            val dateIndex = it.getColumnIndex("date")

            while (it.moveToNext()) {
                val sender = it.getString(addressIndex) ?: ""
                val body = it.getString(bodyIndex) ?: ""
                val date = it.getLong(dateIndex)

                // Double-check sender matches IRCTC patterns
                val isIrctc = senderIds.any { id ->
                    sender.uppercase().contains(id.uppercase())
                }

                if (isIrctc && body.isNotEmpty()) {
                    messages.add(
                        mapOf(
                            "sender" to sender,
                            "body" to body,
                            "date" to date
                        )
                    )
                }
            }
        }

        return messages
    }
}

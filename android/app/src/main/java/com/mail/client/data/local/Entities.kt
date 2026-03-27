package com.mail.client.data.local

import androidx.room.Entity
import androidx.room.PrimaryKey

@Entity(tableName = "threads")
data class ThreadEntity(
    @PrimaryKey val id: String,
    val snippet: String,
    val historyId: String,
    val subject: String,
    val from: String,
    /** Comma-separated label IDs e.g. "INBOX,UNREAD" */
    val labelIds: String,
    val lastMessageTimestamp: Long,
    val messageCount: Int,
    val isRead: Boolean,
)

@Entity(tableName = "messages")
data class MessageEntity(
    @PrimaryKey val id: String,
    val threadId: String,
    val from: String,
    val to: String,
    val subject: String,
    val snippet: String,
    /** Decoded HTML or plain-text body. Empty until thread is opened (format=full fetch). */
    val body: String,
    val date: Long,
    /** Comma-separated label IDs */
    val labelIds: String,
    val isRead: Boolean,
)

@Entity(tableName = "labels")
data class LabelEntity(
    @PrimaryKey val id: String,
    val name: String,
    val type: String,
)

// ── Helpers ───────────────────────────────────────────────────────────────────

fun ThreadEntity.labelList(): List<String> =
    if (labelIds.isBlank()) emptyList() else labelIds.split(",")

fun MessageEntity.labelList(): List<String> =
    if (labelIds.isBlank()) emptyList() else labelIds.split(",")

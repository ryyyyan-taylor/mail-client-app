package com.mail.client.data.remote.dto

// ── Thread list ──────────────────────────────────────────────────────────────

data class ThreadListResponse(
    val threads: List<ThreadSummaryDto>?,
    val nextPageToken: String?,
    val resultSizeEstimate: Int?,
)

data class ThreadSummaryDto(
    val id: String,
    val snippet: String?,
    val historyId: String?,
)

// ── Thread detail (threads.get) ───────────────────────────────────────────────

data class ThreadDetailDto(
    val id: String,
    val snippet: String?,
    val historyId: String?,
    val messages: List<MessageDto>?,
)

// ── Message ───────────────────────────────────────────────────────────────────

data class MessageDto(
    val id: String,
    val threadId: String?,
    val labelIds: List<String>?,
    val snippet: String?,
    val payload: PayloadDto?,
    val internalDate: String?,
)

data class PayloadDto(
    val mimeType: String?,
    val headers: List<HeaderDto>?,
    val body: BodyDto?,
    val parts: List<PayloadDto>?,
)

data class HeaderDto(
    val name: String,
    val value: String,
)

data class BodyDto(
    val size: Int?,
    val data: String?,
)

// ── Labels ────────────────────────────────────────────────────────────────────

data class LabelListResponse(
    val labels: List<LabelDto>?,
)

data class LabelDto(
    val id: String,
    val name: String,
    val type: String?,
)

// ── Modify request ────────────────────────────────────────────────────────────

data class ModifyRequest(
    val addLabelIds: List<String>? = null,
    val removeLabelIds: List<String>? = null,
)

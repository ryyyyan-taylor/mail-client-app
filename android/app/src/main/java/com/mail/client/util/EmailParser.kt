package com.mail.client.util

import android.util.Base64
import com.mail.client.data.remote.dto.HeaderDto
import com.mail.client.data.remote.dto.PayloadDto

object EmailParser {

    /** Decode a base64url-encoded string (as returned by the Gmail API). */
    fun decodeBase64Url(data: String): String {
        val base64 = data.replace('-', '+').replace('_', '/')
        return try {
            String(Base64.decode(base64, Base64.DEFAULT), Charsets.UTF_8)
        } catch (e: Exception) {
            ""
        }
    }

    fun extractHeader(headers: List<HeaderDto>?, name: String): String =
        headers?.firstOrNull { it.name.equals(name, ignoreCase = true) }?.value ?: ""

    /**
     * Recursively extract the best body from a message payload.
     * Prefers text/html over text/plain for rich rendering.
     */
    fun extractBody(payload: PayloadDto?): String {
        if (payload == null) return ""

        // Simple single-part message
        val directData = payload.body?.data
        if (directData != null) return decodeBase64Url(directData)

        val parts = payload.parts ?: return ""

        // Prefer HTML part, fall back to plain text
        val html = parts.firstOrNull { it.mimeType == "text/html" }
        val plain = parts.firstOrNull { it.mimeType == "text/plain" }
        val best = html ?: plain

        if (best?.body?.data != null) return decodeBase64Url(best.body.data)

        // Nested multipart — recurse into each part
        return parts.firstNotNullOfOrNull { part ->
            extractBody(part).ifEmpty { null }
        } ?: ""
    }

    /**
     * Extract a display name from a "Name <email@example.com>" formatted string.
     * Falls back to the raw string if no name is present.
     */
    fun displayName(from: String): String {
        val match = Regex("""^"?(.+?)"?\s*<""").find(from)
        return match?.groupValues?.get(1)?.trim() ?: from.substringBefore("@").trim()
    }
}

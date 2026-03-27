package com.mail.client.data.remote

import com.mail.client.data.remote.dto.LabelListResponse
import com.mail.client.data.remote.dto.ModifyRequest
import com.mail.client.data.remote.dto.ThreadDetailDto
import com.mail.client.data.remote.dto.ThreadListResponse
import com.mail.client.data.remote.dto.ThreadSummaryDto
import retrofit2.http.Body
import retrofit2.http.GET
import retrofit2.http.POST
import retrofit2.http.Path
import retrofit2.http.Query

interface GmailApiService {

    @GET("gmail/v1/users/me/threads")
    suspend fun listThreads(
        @Query("labelIds") labelId: String? = null,
        @Query("q") q: String? = null,
        @Query("pageToken") pageToken: String? = null,
        @Query("maxResults") maxResults: Int = 50,
    ): ThreadListResponse

    // format=metadata returns headers + labels but no body (fast, used for inbox list)
    // format=full returns complete messages with body (used when opening a thread)
    @GET("gmail/v1/users/me/threads/{id}")
    suspend fun getThread(
        @Path("id") id: String,
        @Query("format") format: String = "metadata",
    ): ThreadDetailDto

    @POST("gmail/v1/users/me/threads/{id}/modify")
    suspend fun modifyThread(
        @Path("id") id: String,
        @Body body: ModifyRequest,
    ): ThreadSummaryDto

    @POST("gmail/v1/users/me/threads/{id}/trash")
    suspend fun trashThread(@Path("id") id: String): ThreadSummaryDto

    @POST("gmail/v1/users/me/threads/{id}/untrash")
    suspend fun untrashThread(@Path("id") id: String): ThreadSummaryDto

    @GET("gmail/v1/users/me/labels")
    suspend fun listLabels(): LabelListResponse
}

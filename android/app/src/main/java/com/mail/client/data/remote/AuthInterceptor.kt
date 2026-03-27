package com.mail.client.data.remote

import com.mail.client.data.repository.AuthRepository
import kotlinx.coroutines.runBlocking
import okhttp3.Interceptor
import okhttp3.Response

class AuthInterceptor(private val authRepository: AuthRepository) : Interceptor {
    override fun intercept(chain: Interceptor.Chain): Response {
        val token = runBlocking { authRepository.getAccessToken() }

        val request = chain.request().newBuilder()
            .addHeader("Authorization", "Bearer $token")
            .build()

        val response = chain.proceed(request)

        // On 401, invalidate the cached token and retry once with a fresh one
        if (response.code == 401) {
            response.close()
            runBlocking { authRepository.invalidateToken() }
            val newToken = runBlocking { authRepository.getAccessToken() }
            val retryRequest = chain.request().newBuilder()
                .addHeader("Authorization", "Bearer $newToken")
                .build()
            return chain.proceed(retryRequest)
        }

        return response
    }
}

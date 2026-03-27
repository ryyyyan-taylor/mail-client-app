package com.mail.client.data.remote

import com.mail.client.data.repository.AuthRepository
import com.squareup.moshi.Moshi
import com.squareup.moshi.kotlin.reflect.KotlinJsonAdapterFactory
import okhttp3.OkHttpClient
import okhttp3.logging.HttpLoggingInterceptor
import retrofit2.Retrofit
import retrofit2.converter.moshi.MoshiConverterFactory

object RetrofitProvider {

    fun create(authRepository: AuthRepository): GmailApiService {
        val moshi = Moshi.Builder()
            .addLast(KotlinJsonAdapterFactory())
            .build()

        val logging = HttpLoggingInterceptor().apply {
            level = HttpLoggingInterceptor.Level.BASIC
        }

        val okhttp = OkHttpClient.Builder()
            .addInterceptor(AuthInterceptor(authRepository))
            .addInterceptor(logging)
            .build()

        return Retrofit.Builder()
            .baseUrl("https://gmail.googleapis.com/")
            .client(okhttp)
            .addConverterFactory(MoshiConverterFactory.create(moshi))
            .build()
            .create(GmailApiService::class.java)
    }
}

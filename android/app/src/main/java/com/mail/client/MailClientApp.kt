package com.mail.client

import android.app.Application
import com.mail.client.di.appModule
import org.koin.android.ext.koin.androidContext
import org.koin.core.context.startKoin

class MailClientApp : Application() {
    override fun onCreate() {
        super.onCreate()
        startKoin {
            androidContext(this@MailClientApp)
            modules(appModule)
        }
    }
}

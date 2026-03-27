package com.mail.client.di

import com.mail.client.data.local.MailDatabase
import com.mail.client.data.remote.RetrofitProvider
import com.mail.client.data.repository.AuthRepository
import com.mail.client.data.repository.MailRepository
import com.mail.client.data.local.TokenStorage
import com.mail.client.ui.auth.SignInViewModel
import com.mail.client.ui.inbox.InboxViewModel
import com.mail.client.ui.thread.ThreadDetailViewModel
import org.koin.android.ext.koin.androidContext
import org.koin.androidx.viewmodel.dsl.viewModel
import org.koin.dsl.module

val appModule = module {

    // ── Auth ──────────────────────────────────────────────────────────────────
    single { TokenStorage(androidContext()) }
    single { AuthRepository(androidContext(), get()) }
    viewModel { SignInViewModel(get()) }

    // ── Database ──────────────────────────────────────────────────────────────
    single { MailDatabase.create(androidContext()) }
    single { get<MailDatabase>().threadDao() }
    single { get<MailDatabase>().messageDao() }
    single { get<MailDatabase>().labelDao() }

    // ── Network ───────────────────────────────────────────────────────────────
    single { RetrofitProvider.create(get()) }

    // ── Repository ────────────────────────────────────────────────────────────
    single { MailRepository(get(), get(), get(), get()) }

    // ── Inbox ─────────────────────────────────────────────────────────────────
    viewModel { InboxViewModel(get()) }

    // ── Thread detail ─────────────────────────────────────────────────────────
    viewModel { params -> ThreadDetailViewModel(params.get(), get()) }
}

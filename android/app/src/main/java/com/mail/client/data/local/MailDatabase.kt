package com.mail.client.data.local

import android.content.Context
import androidx.room.Database
import androidx.room.Room
import androidx.room.RoomDatabase

@Database(
    entities = [ThreadEntity::class, MessageEntity::class, LabelEntity::class],
    version = 1,
    exportSchema = false,
)
abstract class MailDatabase : RoomDatabase() {
    abstract fun threadDao(): ThreadDao
    abstract fun messageDao(): MessageDao
    abstract fun labelDao(): LabelDao

    companion object {
        fun create(context: Context): MailDatabase =
            Room.databaseBuilder(context, MailDatabase::class.java, "mail.db")
                .fallbackToDestructiveMigration(dropAllTables = true)
                .build()
    }
}

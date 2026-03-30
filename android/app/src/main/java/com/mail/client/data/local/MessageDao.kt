package com.mail.client.data.local

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import androidx.room.Transaction
import kotlinx.coroutines.flow.Flow

@Dao
interface MessageDao {

    @Query("SELECT * FROM messages WHERE threadId = :threadId ORDER BY date ASC")
    fun observeForThread(threadId: String): Flow<List<MessageEntity>>

    @Query("SELECT * FROM messages WHERE threadId = :threadId ORDER BY date ASC")
    suspend fun getForThread(threadId: String): List<MessageEntity>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertAll(messages: List<MessageEntity>)

    @Query("DELETE FROM messages WHERE threadId = :threadId")
    suspend fun deleteForThread(threadId: String)

    /** Atomically replaces all messages for a thread — Flow observers never see an empty state. */
    @Transaction
    suspend fun replaceForThread(threadId: String, messages: List<MessageEntity>) {
        deleteForThread(threadId)
        insertAll(messages)
    }
}

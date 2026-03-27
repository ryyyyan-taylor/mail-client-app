package com.mail.client.data.local

import androidx.room.Dao
import androidx.room.Delete
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import kotlinx.coroutines.flow.Flow

@Dao
interface ThreadDao {

    @Query("SELECT * FROM threads WHERE labelIds LIKE '%INBOX%' ORDER BY lastMessageTimestamp DESC")
    fun observeInbox(): Flow<List<ThreadEntity>>

    @Query("SELECT * FROM threads WHERE id = :id")
    suspend fun getById(id: String): ThreadEntity?

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertAll(threads: List<ThreadEntity>)

    @Delete
    suspend fun delete(thread: ThreadEntity)

    @Query("SELECT MAX(lastMessageTimestamp) FROM threads")
    suspend fun getLatestTimestamp(): Long?
}

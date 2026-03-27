package com.mail.client.data.local

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query

@Dao
interface LabelDao {

    @Query("SELECT * FROM labels")
    suspend fun getAll(): List<LabelEntity>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertAll(labels: List<LabelEntity>)
}

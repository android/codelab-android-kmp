/*
 * Copyright 2024 The Android Open Source Project
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     https://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package com.example.fruitties.kmptutorial.android.database

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import com.example.fruitties.kmptutorial.android.model.Fruittie
import kotlinx.coroutines.flow.Flow

@Dao
interface FruittieDao {

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(fruitties: List<Fruittie>): List<Long>

    @Query("SELECT * FROM Fruittie")
    fun getAll(): Flow<List<Fruittie>>

    @Query("SELECT COUNT(*) as count FROM Fruittie")
    suspend fun count(): Int
}

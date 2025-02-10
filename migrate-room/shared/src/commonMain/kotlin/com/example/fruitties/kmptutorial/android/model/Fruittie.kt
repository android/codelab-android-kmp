package com.example.fruitties.kmptutorial.android.model

import androidx.room.Entity
import androidx.room.PrimaryKey

@Entity(indices = [androidx.room.Index(value = ["id"], unique = true)])
data class Fruittie(
    @PrimaryKey(autoGenerate = true) val id: Long = 0,
    val name: String,
    val fullName: String,
    val calories: String,
)
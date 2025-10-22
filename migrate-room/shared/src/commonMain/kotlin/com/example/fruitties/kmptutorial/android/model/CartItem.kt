package com.example.fruitties.kmptutorial.android.model

import androidx.room.Embedded
import androidx.room.Entity
import androidx.room.ForeignKey
import androidx.room.PrimaryKey
import androidx.room.Relation
import kotlin.experimental.ExperimentalObjCName
import kotlin.native.ObjCName

@OptIn(ExperimentalObjCName::class)
@ObjCName("CartItemEntity")
@Entity(
    foreignKeys = [
        ForeignKey(
            entity = Fruittie::class,
            parentColumns = ["id"],
            childColumns = ["id"],
            onDelete = ForeignKey.CASCADE,
        ),
    ],
)
data class CartItem(@PrimaryKey val id: Long, val count: Int = 1)

data class CartItemWithFruittie(
    @Relation(
        parentColumn = "id",
        entityColumn = "id",
    )
    val fruittie: Fruittie,
    @Embedded val cartItem: CartItem,
)
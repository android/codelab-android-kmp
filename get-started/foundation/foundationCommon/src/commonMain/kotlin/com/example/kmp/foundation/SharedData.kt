package com.example.kmp.foundation

data class SharedData(
    val id: Int,
    val message: String
)

fun createSharedData(id: Int, message: String): SharedData =
    SharedData(id, message)

fun describeSharedData(data: SharedData): String =
    "SharedData(id=${data.id}, message='${data.message}')"

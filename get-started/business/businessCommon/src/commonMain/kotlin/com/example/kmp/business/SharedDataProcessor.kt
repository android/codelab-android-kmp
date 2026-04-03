package com.example.kmp.business

import com.example.kmp.foundation.SharedData

class SharedDataProcessor {

    fun processSharedData(data: SharedData): String =
        "Processed: id=${data.id}, msg='${data.message}'"

    fun validateAsSharedData(data: Any): Boolean =
        data is SharedData

    fun forceProcessAny(data: Any): String {
        val sd = data as SharedData
        return "Force-processed: id=${sd.id}, msg='${sd.message}'"
    }

    fun createLocalSharedData(id: Int, message: String): SharedData =
        SharedData(id, message)

    fun getSharedDataClassName(): String =
        SharedData::class.qualifiedName ?: "unknown"
}

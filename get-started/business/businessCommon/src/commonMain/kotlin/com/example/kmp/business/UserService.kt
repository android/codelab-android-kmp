package com.example.kmp.business

import com.example.kmp.business.model.User
import com.example.kmp.foundation.platform

class UserService {
    fun currentUser(): User = User(
        id = "u001",
        name = "KMP User",
        platform = platform()   // depends on :foundation
    )

    fun formatUserTag(user: User): String = "[${user.platform}] ${user.name}"
}

package com.example.kmp.business

import com.example.kmp.business.model.FeedItem

class FeedService(private val userService: UserService) {
    fun generateFeed(count: Int): List<FeedItem> =
        (1..count).map { i ->
            FeedItem(
                id = "item_$i",
                title = "Feed Item #$i",
                author = userService.currentUser()
            )
        }
}

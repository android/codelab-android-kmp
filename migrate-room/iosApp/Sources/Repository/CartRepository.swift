import ConcurrencyExtras
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
import sharedKit

protocol CartRepository {
    func addToCart(fruittie: Fruittie) async throws

    func getCartItems() -> AsyncStream<[CartItem]>
}

class DefaultCartRepository: CartRepository {
    private let cartDao: CartDao

    init(cartDao: CartDao) {
        self.cartDao = cartDao
    }

    func addToCart(fruittie: Fruittie) async throws {
        try await cartDao.insertOrIncreaseCount(fruittie: fruittie.entity)
    }

    func getCartItems() -> AsyncStream<[CartItem]> {
        return cartDao.getAll().map { entities in
                entities.map(CartItem.init(entity:))
            }.eraseToStream()
    }
}

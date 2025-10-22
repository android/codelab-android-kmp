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

import ConcurrencyExtras
import sharedKit

protocol FruittieRepository {
    func getData() -> AsyncStream<[Fruittie]>
}

class DefaultFruittieRepository: FruittieRepository {
    private let fruittieDao: any FruittieDao
    private let api: FruittieApi

    init(fruittieDao: FruittieDao, api: FruittieApi) {
        self.fruittieDao = fruittieDao
        self.api = api
    }

    func getData() -> AsyncStream<[Fruittie]> {
        let dao = fruittieDao
        Task {
                let isEmpty = try await dao.count() == 0
                if isEmpty {
                    let response = try await api.getData(pageNumber: 0)
                    let fruitties = response.feed.map {
                        FruittieEntity(
                            id: 0,
                            name: $0.name,
                            fullName: $0.fullName,
                            calories: ""
                        )
                    }
                    _ = try await dao.insert(fruitties: fruitties)
                }
            }
        return dao.getAll().map { entities in
            entities.map(Fruittie.init(entity:))
        }.eraseToStream()
    }
}

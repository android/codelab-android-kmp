/*
 * Copyright 2025 The Android Open Source Project
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
package com.example.fruitties.kmptutorial.android.fakes

import com.example.fruitties.kmptutorial.android.model.Fruittie
import com.example.fruitties.kmptutorial.android.network.FruittieApi
import com.example.fruitties.kmptutorial.android.network.FruittiesResponse

class FakeFruittieApi(val list: List<Fruittie>) : FruittieApi {
    override suspend fun getData(pageNumber: Int): FruittiesResponse = FruittiesResponse(list, 1, 1)
}

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

import Foundation
import SwiftUI

// If we're running tests we want to have a blank app that doesn't do anything
if ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] == nil {
    FruittiesApp.main()
} else {
    EmptyApp.main()
}

struct FruittiesApp: App {
    @StateObject
    private var appContainer = AppContainer()

    var body: some Scene {
        WindowGroup {
            ContentView(appContainer: appContainer)
        }
    }
}


private struct EmptyApp: App {

    var body: some Scene {
        WindowGroup {

        }
    }
}

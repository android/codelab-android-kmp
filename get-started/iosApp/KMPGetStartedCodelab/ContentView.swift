//
//  ContentView.swift
//  KMPGetStartedCodelab
//
//

import SwiftUI
import sharedKit

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, \(platform())!")
        }
        .padding()
    }
}

#Preview {
    ContentView()
}

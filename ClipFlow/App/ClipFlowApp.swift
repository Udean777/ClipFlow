//
//  ClipFlowApp.swift
//  ClipFlow
//
//  Created by Sajudin on 16/06/26.
//

import SwiftUI
import SwiftData

@main
struct ClipFlowApp: App {
    @State private var viewModel: ClipboardViewModel
    @State private var modelContainer: ModelContainer
    
    init() {
        let container = try! ModelContainer(for: ClipItem.self)
        _modelContainer = State(initialValue: container)
        _viewModel = State(initialValue: ClipboardViewModel(modelContext: container.mainContext))
    }
    
    var body: some Scene {
        MenuBarExtra("ClipFlow", systemImage: "doc.on.clipboard") {
            MenuBarView(viewModel: viewModel)
                .modelContainer(modelContainer)
                .environment(\.modelContext, viewModel.modelContext ?? ModelContext(modelContainer))
        }
        .menuBarExtraStyle(.window)
    }
}

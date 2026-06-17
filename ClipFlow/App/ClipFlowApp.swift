//
//  ClipFlowApp.swift
//  ClipFlow
//
//  Created by Sajudin on 16/06/26.
//

import SwiftUI
import SwiftData

class ClipFlowDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
    }
}

@main
struct ClipFlowApp: App {
    @NSApplicationDelegateAdaptor(ClipFlowDelegate.self) var appDelegate
    
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
        
        Window("ClipFlow", id: "main") {
            MainWindowView(viewModel: viewModel)
                .modelContainer(modelContainer)
                .environment(\.modelContext, viewModel.modelContext ?? ModelContext(modelContainer))
        }
        .defaultLaunchBehavior(.suppressed)
        .windowResizability(.contentMinSize)
        
        Settings {
            IgnoredAppsSettingsView()
        }
    }
}

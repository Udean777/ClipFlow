//
//  FloatingWindowManager.swift
//  ClipFlow
//
//  Created by Sajudin on 16/06/26.
//

import AppKit
import SwiftUI
import SwiftData

final class FloatingWindowManager {
    static let shared = FloatingWindowManager()
    private var panel: NSPanel?
    private var previousApp: NSRunningApplication?
    
    private init() {}
    
    @MainActor
    func toggle(viewModel: ClipboardViewModel) {
        if let panel = panel, panel.isVisible {
            panel.orderOut(nil)
        } else {
            show(viewModel: viewModel)
        }
    }
    
    @MainActor
    private func show(viewModel: ClipboardViewModel) {
        previousApp = NSWorkspace.shared.frontmostApplication
        
        if panel == nil {
            let contentView = MenuBarView(viewModel: viewModel)
                .modelContainer(for: ClipItem.self)
            
            let newPanel = NSPanel(
                contentRect: NSRect(x: 0, y: 0, width: 350, height: 450),
                styleMask: [.titled, .closable, .nonactivatingPanel, .fullSizeContentView],
                backing: .buffered,
                defer: false
            )
            
            newPanel.isFloatingPanel = true
            newPanel.level = .floating
            newPanel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            newPanel.titleVisibility = .hidden
            newPanel.titlebarAppearsTransparent = true
            newPanel.isMovableByWindowBackground = true
            newPanel.contentView = NSHostingView(rootView: contentView)
            newPanel.center()
            
            self.panel = newPanel
        }
        
        panel?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func close() {
        panel?.orderOut(nil)
    }
    
    func closeAndPaste() {
        panel?.orderOut(nil)
        
        if let app = previousApp {
            app.activate(options: .activateIgnoringOtherApps)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            PasteSimulator.paste()
        }
    }
}

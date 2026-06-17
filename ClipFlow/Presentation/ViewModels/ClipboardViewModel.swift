//
//  ClipboardViewModel.swift
//  ClipFlow
//
//  Created by Sajudin on 16/06/26.
//

import Foundation
import SwiftData
import SwiftUI
import Observation
import KeyboardShortcuts

@Observable
@MainActor
final class ClipboardViewModel {
    private var pasteboardService: PasteboardServiceType
    var modelContext: ModelContext?
    
    init(modelContext: ModelContext) {
        self.pasteboardService = PasteboardService()
        self.modelContext = modelContext
        
        pasteboardService.onNewCopy = { [weak self] newItem in
            Task { @MainActor in
                self?.handleNewCopy(item: newItem)
            }
        }
        
        pasteboardService.startMonitoring()
        Log("🚀 Monitoring started at app launch!")
        
        KeyboardShortcuts.onKeyUp(for: .toggleClipFlow) { [weak self] in
            guard let self = self else { return }
            Task { @MainActor in
                FloatingWindowManager.shared.toggle(viewModel: self)
            }
        }
    }
    
    func setup(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func clearAll() {
        guard let context = modelContext else { return }
        
        
        pasteboardService.pauseMonitoring()
        
        
        let descriptor = FetchDescriptor<ClipItem>()
        if let items = try? context.fetch(descriptor) {
            for item in items {
                context.delete(item)
            }
        }
        try? context.save()
        
        Log("🗑️ All items cleared")
        
        
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            self?.pasteboardService.resumeMonitoring()
        }
    }
    
    private func handleNewCopy(item: ClipItem) {
        guard let context = modelContext else {
            Log("❌ handleNewCopy: no modelContext")
            return
        }
        
        if item.type == .text {
            let contentToFind = item.content
            let fetchDescriptor = FetchDescriptor<ClipItem>(predicate: #Predicate { $0.content == contentToFind })
            
            if let existingItems = try? context.fetch(fetchDescriptor), let existingItem = existingItems.first {
                Log("📋 handleNewCopy: found existing text, updating timestamp")
                existingItem.timestamp = Date()
            } else {
                Log("📋 handleNewCopy: inserting new text: \"\(item.content.prefix(40))\"")
                context.insert(item)
            }
        } else if item.type == .image, let newImageData = item.imageData {
            let allDescriptor = FetchDescriptor<ClipItem>(
                predicate: #Predicate { $0.typeRawValue == "image" },
                sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
            )
            
            var isDuplicate = false
            if let existingImages = try? context.fetch(allDescriptor) {
                for existing in existingImages {
                    if existing.imageData?.count == newImageData.count {
                        isDuplicate = true
                        Log("📋 handleNewCopy: found existing image, updating timestamp (size match: \(newImageData.count))")
                        existing.timestamp = Date()
                        break
                    }
                }
            }
            
            if !isDuplicate {
                Log("📋 handleNewCopy: inserting new image, \(newImageData.count) bytes")
                context.insert(item)
            }
        } else {
            Log("📋 handleNewCopy: inserting item type=\(item.typeRawValue)")
            context.insert(item)
        }
        
        
        let allDescriptor = FetchDescriptor<ClipItem>(sortBy: [SortDescriptor(\.timestamp, order: .reverse)])
        if let allItems = try? context.fetch(allDescriptor), allItems.count > 100 {
            for oldItem in allItems.dropFirst(100) {
                context.delete(oldItem)
            }
        }
        
        try? context.save()
    }
}

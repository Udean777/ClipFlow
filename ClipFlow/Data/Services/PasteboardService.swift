//
//  PasteboardService.swift
//  ClipFlow
//
//  Created by Sajudin on 16/06/26.
//

import AppKit

final class PasteboardService: PasteboardServiceType {
    var onNewCopy: ((ClipItem) -> Void)?
    
    private let pasteboard = NSPasteboard.general
    private var lastChangeCount: Int
    private var isMonitoring = false
    private var isPaused = false
    private var justResumed = false
    private let screenshotCapture = ScreenshotCapture()
    
    init() {
        self.lastChangeCount = pasteboard.changeCount
    }
    
    func startMonitoring() {
        stopMonitoring()
        lastChangeCount = pasteboard.changeCount
        isMonitoring = true
        
        screenshotCapture.onScreenshot = { [weak self] imageData in
            guard let self = self else { return }
            Log("📸 Screenshot captured: \(imageData.count) bytes")
            let item = ClipItem(content: "[Screenshot]", type: .image, imageData: imageData)
            Task { @MainActor in
                Log("📸 Inserting screenshot into DB via onNewCopy...")
                self.onNewCopy?(item)
            }
        }
        screenshotCapture.start()
        
        // Mulai polling loop
        pollClipboard()
        
        Log("🚀 Monitoring started!")
    }
    
    func stopMonitoring() {
        isMonitoring = false
        screenshotCapture.stop()
    }
    
    func pauseMonitoring() {
        isPaused = true
    }
    
    func resumeMonitoring() {
        lastChangeCount = pasteboard.changeCount
        justResumed = true
        isPaused = false
        
        // Skip check pertama — biarkan user copy dulu
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            self?.justResumed = false
        }
        Log("🔄 Monitoring resumed")
    }
    
    // MARK: - Polling loop
    
    private func pollClipboard() {
        guard isMonitoring else { return }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self = self else { return }
            // Cek paused DISINI — sebelum checkForChanges
            guard !self.isPaused else {
                self.pollClipboard() // skip check, tetap jadwalkan next poll
                return
            }
            self.checkForChanges()
            self.pollClipboard()
        }
    }
    
    private func checkForChanges() {
        guard !isPaused else { return }
        guard !justResumed else { return }
        
        let currentChangeCount = pasteboard.changeCount
        guard currentChangeCount != lastChangeCount else { return }
        lastChangeCount = currentChangeCount
        
        if pasteboard.types?.contains(NSPasteboard.PasteboardType("org.nspasteboard.ConcealedType")) == true {
            Log("⚠️ ConcealedType — skipping")
            return
        }
        
        let isFileURL = pasteboard.types?.contains(.fileURL) ?? false
        if isFileURL {
            Log("⚠️ FileURL — skipping")
            return
        }
        
        let types = (pasteboard.types ?? []).map { $0.rawValue }
        Log("📋 changeCount=\(currentChangeCount) types=\(types)")
        let currentText = pasteboard.string(forType: .string)
        Log("📋 Clipboard text: \"\(currentText?.prefix(80) ?? "nil")\"")
        
        // 1. PNG
        if let pngData = pasteboard.data(forType: .png) {
            Log("✅ PNG found, \(pngData.count) bytes")
            let item = ClipItem(content: "[Gambar Disolin]", type: .image, imageData: pngData)
            Task { @MainActor in self.onNewCopy?(item) }
            return
        }
        
        // 2. TIFF
        if let tiffData = pasteboard.data(forType: .tiff) {
            Log("✅ TIFF found, \(tiffData.count) bytes")
            let item = ClipItem(content: "[Gambar Disolin]", type: .image, imageData: tiffData)
            Task { @MainActor in self.onNewCopy?(item) }
            return
        }
        
        // 3. NSImage
        if let nsImage = NSImage(pasteboard: pasteboard),
           let tiff = nsImage.tiffRepresentation,
           let bitmap = NSBitmapImageRep(data: tiff),
           let png = bitmap.representation(using: .png, properties: [:]) {
            Log("✅ NSImage found, \(png.count) bytes")
            let item = ClipItem(content: "[Gambar Disolin]", type: .image, imageData: png)
            Task { @MainActor in self.onNewCopy?(item) }
            return
        }
        
        // 4. Teks
        if let text = currentText {
            guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                Log("⏭️ Empty text — skipping")
                return
            }
            Log("✅ Text found: \"\(text.prefix(80))\"")
            let item = ClipItem(content: text, type: .text)
            Task { @MainActor in self.onNewCopy?(item) }
        } else {
            Log("⏭️ No text, no image — nothing to add")
        }
    }
}

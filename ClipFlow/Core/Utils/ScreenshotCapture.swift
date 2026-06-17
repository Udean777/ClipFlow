//
//  ScreenshotCapture.swift
//  ClipFlow
//
//  Created by Sajudin on 16/06/26.
//

import AppKit

final class ScreenshotCapture {
    var onScreenshot: ((Data) -> Void)?
    
    private var fileSource: DispatchSourceFileSystemObject?
    private var desktopFD: Int32 = -1
    
    func start() {
        guard let desktopURL = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first else {
            return
        }
        
        desktopFD = open(desktopURL.path, O_EVTONLY)
        guard desktopFD >= 0 else { return }
        
        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: desktopFD,
            eventMask: [.write, .rename, .delete],
            queue: .main
        )
        
        var seenFiles: Set<String> = []
        
        // Initial snapshot of existing files
        if let files = try? FileManager.default.contentsOfDirectory(atPath: desktopURL.path) {
            for f in files where f.lowercased().hasPrefix("screenshot") && f.lowercased().hasSuffix(".png") {
                seenFiles.insert(f)
            }
        }
        
        source.setEventHandler { [weak self] in
            guard let self = self else { return }
            self.checkForNewScreenshots(seenFiles: &seenFiles)
        }
        
        source.setCancelHandler { [weak self] in
            if let fd = self?.desktopFD, fd >= 0 {
                close(fd)
            }
        }
        
        self.fileSource = source
        source.resume()
        Log("📁 Desktop file watcher started")
    }
    
    func stop() {
        fileSource?.cancel()
        fileSource = nil
        if desktopFD >= 0 {
            close(desktopFD)
            desktopFD = -1
        }
    }
    
    private func checkForNewScreenshots(seenFiles: inout Set<String>) {
        guard let desktopURL = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first else {
            return
        }
        
        let desktopPath = desktopURL.path
        guard let files = try? FileManager.default.contentsOfDirectory(atPath: desktopPath) else {
            return
        }
        
        for file in files {
            let lowercased = file.lowercased()
            guard lowercased.hasPrefix("screenshot") && lowercased.hasSuffix(".png") else {
                continue
            }
            
            // Skip already seen files
            guard !seenFiles.contains(file) else { continue }
            seenFiles.insert(file)
            
            let filePath = (desktopPath as NSString).appendingPathComponent(file)
            
            // Wait briefly for macOS to finish writing
            Thread.sleep(forTimeInterval: 0.2)
            
            guard let imageData = try? Data(contentsOf: URL(fileURLWithPath: filePath)) else {
                continue
            }
            
            print("📸 [ClipFlow] Screenshot captured: \(file)")
            onScreenshot?(imageData)
        }
    }
}

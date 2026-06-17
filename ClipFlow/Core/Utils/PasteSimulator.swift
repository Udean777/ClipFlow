//
//  PasteSimulator.swift
//  ClipFlow
//
//  Created by Sajudin on 16/06/26.
//

import AppKit

enum PasteSimulator {
    static func paste() {
        let vKeyCode: CGKeyCode = 9 
        
        guard let keyDown = CGEvent(keyboardEventSource: nil, virtualKey: vKeyCode, keyDown: true) else { return }
        keyDown.flags = .maskCommand
        keyDown.post(tap: .cgSessionEventTap)
        
        guard let keyUp = CGEvent(keyboardEventSource: nil, virtualKey: vKeyCode, keyDown: false) else { return }
        keyUp.flags = .maskCommand
        keyUp.post(tap: .cgSessionEventTap)
    }
}

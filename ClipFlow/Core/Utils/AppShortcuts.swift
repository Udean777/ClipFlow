//
//  AppShortcuts.swift
//  ClipFlow
//
//  Created by Sajudin on 16/06/26.
//

import KeyboardShortcuts
import AppKit

extension KeyboardShortcuts.Name {
    static let toggleClipFlow = Self("toggleClipFlow", initial: .init(.v, modifiers: [.command, .shift]))
}

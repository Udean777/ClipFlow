//
//  PasteboardServiceType.swift
//  ClipFlow
//
//  Created by Sajudin on 16/06/26.
//

import Foundation

protocol PasteboardServiceType {
    var onNewCopy: ((ClipItem) -> Void)? { get set }
    
    func startMonitoring()
    func stopMonitoring()
    func pauseMonitoring()
    func resumeMonitoring()
}

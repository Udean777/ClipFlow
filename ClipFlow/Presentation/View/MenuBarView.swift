//
//  MenuBarView.swift
//  ClipFlow
//
//  Created by Sajudin on 16/06/26.
//

import SwiftUI
import SwiftData
import Combine


enum DateFilter: String, CaseIterable, Identifiable {
    case semua = "Semua"
    case hariIni = "Hari Ini"
    case tujuhHari = "7 Hari Terakhir"
    
    var id: String { self.rawValue }
    
    var startDate: Date? {
        let calendar = Calendar.current
        let now = Date()
        switch self {
        case .semua:
            return nil
        case .hariIni:
            return calendar.startOfDay(for: now)
        case .tujuhHari:
            return calendar.date(byAdding: .day, value: -7, to: calendar.startOfDay(for: now))
        }
    }
}


struct MenuBarView: View {
    var viewModel: ClipboardViewModel
    
    @Environment(\.modelContext) private var modelContext
    @State private var selectedFilter: DateFilter = .semua
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Text("ClipFlow")
                    .font(.headline)
                Spacer()
                
                Button(action: {
                    viewModel.clearAll()
                }) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
                .buttonStyle(.plain)
                .help("Bersihkan History")
                
                Button(action: {
                    NSApplication.shared.terminate(nil)
                }) {
                    Image(systemName: "power")
                }
                .buttonStyle(.plain)
                .help("Keluar dari Aplikasi")
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))
            
            Picker("Filter Waktu", selection: $selectedFilter) {
                ForEach(DateFilter.allCases) { filter in
                    Text(filter.rawValue).tag(filter)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            FilteredClipList(filter: selectedFilter) { item in
                let pasteboard = NSPasteboard.general
                pasteboard.clearContents()
                
                if item.type == .image, let data = item.imageData {
                    
                    pasteboard.setData(data, forType: .png)
                    
                    
                    if let nsImage = NSImage(data: data), let tiff = nsImage.tiffRepresentation {
                        pasteboard.setData(tiff, forType: .tiff)
                    }
                    
                    
                    if let publicTiff = pasteboard.data(forType: .tiff) {
                        pasteboard.setData(publicTiff, forType: NSPasteboard.PasteboardType("public.tiff"))
                    }
                } else {
                    pasteboard.setString(item.content, forType: .string)
                }
                
                NSSound(named: "Pop")?.play()
                
                FloatingWindowManager.shared.closeAndPaste()
            }
        }
        .frame(width: Constants.UI.popoverWidth, height: Constants.UI.popoverHeight + 40)
    }
}


struct FilteredClipList: View {
    @Environment(\.modelContext) private var modelContext
    let filter: DateFilter
    let action: (ClipItem) -> Void
    
    @State private var clipItems: [ClipItem] = []
    @State private var selectedIndex: Int = 0
    @FocusState private var isListFocused: Bool
    
    init(filter: DateFilter, action: @escaping (ClipItem) -> Void) {
        self.filter = filter
        self.action = action
    }
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 4) {
                    if clipItems.isEmpty {
                        Text("Riwayat kosong untuk filter ini.")
                            .foregroundColor(.secondary)
                            .padding(.top, 30)
                    } else {
                        ForEach(Array(clipItems.enumerated()), id: \.element.persistentModelID) { index, item in
                            ClipItemRow(
                                item: item,
                                isKeyboardSelected: selectedIndex == index
                            ) {
                                action(item)
                            }
                            .id(item.persistentModelID)
                        }
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 8)
            }
            .focusable()
            .focused($isListFocused)
            
            .onKeyPress(.upArrow) {
                if selectedIndex > 0 {
                    selectedIndex -= 1
                    withAnimation {
                        if clipItems.indices.contains(selectedIndex) {
                            proxy.scrollTo(clipItems[selectedIndex].persistentModelID, anchor: .center)
                        }
                    }
                }
                return .handled
            }
            
            .onKeyPress(.downArrow) {
                if selectedIndex < clipItems.count - 1 {
                    selectedIndex += 1
                    withAnimation {
                        if clipItems.indices.contains(selectedIndex) {
                            proxy.scrollTo(clipItems[selectedIndex].persistentModelID, anchor: .center)
                        }
                    }
                }
                return .handled
            }
            
            .onKeyPress(.return) {
                if clipItems.indices.contains(selectedIndex) {
                    action(clipItems[selectedIndex])
                }
                return .handled
            }
            .onAppear {
                isListFocused = true
                selectedIndex = 0
                refreshItems()
            }
            .onChange(of: filter) { _ in
                refreshItems()
            }
            .onReceive(Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()) { _ in
                refreshItems()
            }
        }
    }
    
    private func refreshItems() {
        let sortDescriptors = [SortDescriptor(\ClipItem.timestamp, order: .reverse)]
        var descriptor = FetchDescriptor<ClipItem>(sortBy: sortDescriptors)
        
        if let limitDate = filter.startDate {
            descriptor = FetchDescriptor<ClipItem>(
                predicate: #Predicate { $0.timestamp >= limitDate },
                sortBy: sortDescriptors
            )
        }
        
        let fetched = (try? modelContext.fetch(descriptor)) ?? []
        Log("refreshItems: fetched \(fetched.count) items, context=\(Unmanaged.passUnretained(modelContext).toOpaque())")
        for (i, item) in fetched.enumerated() {
            if item.type == .text {
                Log("  [\(i)] text=\"\(item.content.prefix(40))\" ts=\(item.timestamp)")
            } else {
                Log("  [\(i)] image \(item.imageData?.count ?? 0)bytes ts=\(item.timestamp)")
            }
        }
        clipItems = fetched
    }
}


struct ClipItemRow: View {
    let item: ClipItem
    var isKeyboardSelected: Bool = false
    let action: () -> Void
    
    @State private var isHovered = false
    @State private var isActionTriggered = false
    
    private var isActive: Bool {
        isHovered || isKeyboardSelected
    }
    
    var body: some View {
        HStack {
            if item.type == .image, let data = item.imageData, let nsImage = NSImage(data: data) {
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 32, height: 32)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                
                Text("Gambar")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(.secondary)
            } else {
                Text(item.content)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .font(.system(size: 13, weight: .regular, design: .rounded))
                    .foregroundColor(isActionTriggered ? .primary : (isActive ? .primary : .primary.opacity(0.8)))
            }
            
            Spacer()
            
            if isActionTriggered {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark")
                    Text("Copied")
                }
                .font(.caption.bold())
                .foregroundColor(.green)
                .transition(.move(edge: .trailing).combined(with: .opacity))
            } else if isActive {
                HStack(spacing: 4) {
                    Image(systemName: "return")
                    Text("Copy")
                }
                .font(.caption2.bold())
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.accentColor.opacity(0.2))
                .foregroundColor(.accentColor)
                .cornerRadius(4)
                .transition(.opacity)
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isActionTriggered ? Color.green.opacity(0.15) : (isActive ? Color.primary.opacity(0.06) : Color.clear))
        )
        .contentShape(Rectangle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
            if hovering { NSCursor.pointingHand.push() } else { NSCursor.pop() }
        }
        .onTapGesture {
            guard !isActionTriggered else { return }
            isActionTriggered = true
            action()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                isActionTriggered = false
            }
        }
    }
}


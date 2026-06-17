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
    @Environment(\.openWindow) private var openWindow
    @State private var selectedFilter: DateFilter = .semua
    @State private var searchText: String = ""
    @State private var clipMode: ClipMode = .clipboard
    @FocusState private var isSearchFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 10) {
                HStack(spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: "paperclip.circle.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.accentColor)
                        Text("ClipFlow")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                    }
                    
                    Spacer()
                    
                    Button {
                        openWindow(id: "main")
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                            NSApp.activate(ignoringOtherApps: true)
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "macwindow.and.cursorarrow")
                                .font(.system(size: 10))
                            Text("Buka App")
                                .font(.system(size: 10, weight: .semibold, design: .rounded))
                        }
                        .foregroundColor(.accentColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(Color.accentColor.opacity(0.1))
                        .cornerRadius(5)
                    }
                    .buttonStyle(.plain)
                    
                    SettingsLink {
                        Image(systemName: "gearshape")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                            .frame(width: 24, height: 24)
                            .background(Color.primary.opacity(0.04))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: {
                        NSApplication.shared.terminate(nil)
                    }) {
                        Image(systemName: "power")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                            .frame(width: 24, height: 24)
                            .background(Color.primary.opacity(0.04))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
                
                Picker("Mode", selection: $clipMode) {
                    ForEach(ClipMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                
                HStack(spacing: 6) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                    TextField("Cari...", text: $searchText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 12, design: .rounded))
                        .focused($isSearchFocused)
                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                            isSearchFocused = false
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(Color(NSColor.controlBackgroundColor).opacity(0.4))
                .cornerRadius(6)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.primary.opacity(0.06), lineWidth: 1)
                )
                
                if clipMode == .clipboard {
                    HStack(spacing: 6) {
                        ForEach(DateFilter.allCases) { filter in
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    selectedFilter = filter
                                }
                            }) {
                                Text(filter.rawValue)
                                    .font(.system(size: 10, weight: selectedFilter == filter ? .semibold : .medium, design: .rounded))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(selectedFilter == filter ? Color.accentColor : Color.primary.opacity(0.03))
                                    .foregroundColor(selectedFilter == filter ? .white : .secondary)
                                    .cornerRadius(12)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(.horizontal, 12)
            .padding(.top, 12)
            .padding(.bottom, 8)
            
            Divider()
                .background(Color.primary.opacity(0.05))
            
            if clipMode == .clipboard {
                FilteredClipList(filter: selectedFilter, searchText: searchText) { item in
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
            } else {
                SnippetsListView(readOnly: true) { content in
                    let pasteboard = NSPasteboard.general
                    pasteboard.clearContents()
                    pasteboard.setString(content, forType: .string)
                    NSSound(named: "Pop")?.play()
                    FloatingWindowManager.shared.closeAndPaste()
                }
            }
        }
        .frame(width: Constants.UI.popoverWidth, height: Constants.UI.popoverHeight + 40)
        .background(
            ZStack {
                Button("") { isSearchFocused = true }
                    .keyboardShortcut("f", modifiers: .command)
                    .frame(width: 0, height: 0)
                Button("") {
                    openWindow(id: "main")
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        NSApp.activate(ignoringOtherApps: true)
                    }
                }
                .keyboardShortcut("b", modifiers: .command)
                .frame(width: 0, height: 0)
            }
        )

    }
}

struct FilteredClipList: View {
    @Environment(\.modelContext) private var modelContext
    let filter: DateFilter
    let searchText: String
    let action: (ClipItem) -> Void
    
    @State private var clipItems: [ClipItem] = []
    @State private var selectedIndex: Int = 0
    @FocusState private var isListFocused: Bool
    
    init(filter: DateFilter, searchText: String, action: @escaping (ClipItem) -> Void) {
        self.filter = filter
        self.searchText = searchText
        self.action = action
    }
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 6) {
                    if clipItems.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: !searchText.isEmpty ? "magnifyingglass" : "doc.on.clipboard")
                                .font(.system(size: 32))
                                .foregroundColor(.secondary.opacity(0.5))
                                .padding(.top, 40)
                            Text(!searchText.isEmpty ? "Tidak ada hasil untuk \"\(searchText)\"" : "Riwayat clipboard kosong")
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                    } else {
                        ForEach(Array(clipItems.enumerated()), id: \.element.persistentModelID) { index, item in
                            ClipItemRow(
                                item: item,
                                isKeyboardSelected: selectedIndex == index,
                                onTogglePin: { self.togglePin(for: item) },
                                onDelete: { self.deleteItem(item) }
                            ) {
                                action(item)
                            }
                            .id(item.persistentModelID)
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
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
            .onChange(of: filter) {
                refreshItems()
            }
            .onChange(of: searchText) {
                refreshItems()
            }
            .onReceive(Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()) { _ in
                refreshItems()
            }
        }
    }
    
    private func togglePin(for item: ClipItem) {
        item.isPinned.toggle()
        try? modelContext.save()
        refreshItems()
    }
    
    private func deleteItem(_ item: ClipItem) {
        modelContext.delete(item)
        try? modelContext.save()
        refreshItems()
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
        var sorted = fetched.sorted { a, b in
            if a.isPinned != b.isPinned {
                return a.isPinned
            }
            return a.timestamp > b.timestamp
        }
        
        if !searchText.isEmpty {
            let query = searchText.lowercased()
            sorted = sorted.filter { item in
                item.type == .text && item.content.lowercased().contains(query)
            }
        }
        
        clipItems = sorted
        if selectedIndex >= clipItems.count {
            selectedIndex = max(0, clipItems.count - 1)
        }
    }
}

struct ClipItemRow: View {
    let item: ClipItem
    var isKeyboardSelected: Bool = false
    let action: () -> Void
    var onTogglePin: (() -> Void)?
    var onDelete: (() -> Void)?
    
    init(item: ClipItem, isKeyboardSelected: Bool = false, onTogglePin: (() -> Void)? = nil, onDelete: (() -> Void)? = nil, action: @escaping () -> Void) {
        self.item = item
        self.isKeyboardSelected = isKeyboardSelected
        self.onTogglePin = onTogglePin
        self.onDelete = onDelete
        self.action = action
    }
    
    @State private var isHovered = false
    @State private var isActionTriggered = false
    @State private var isPinHovered = false
    @State private var isDeleteHovered = false
    
    private var isActive: Bool {
        isHovered || isKeyboardSelected
    }
    
    private var copiedPreview: String {
        if item.type == .image, let data = item.imageData {
            return "Gambar (\(data.count / 1024) KB)"
        }
        let text = item.content.trimmingCharacters(in: .whitespacesAndNewlines)
        if text.count > 50 {
            return text.prefix(47) + "..."
        }
        return text
    }
    
    var body: some View {
        HStack(spacing: 10) {
            Button(action: {
                onTogglePin?()
            }) {
                Image(systemName: item.isPinned ? "star.fill" : "star")
                    .font(.system(size: 11))
                    .foregroundColor(item.isPinned ? .yellow : .secondary.opacity(isPinHovered ? 0.8 : 0.35))
                    .frame(width: 20, height: 20)
            }
            .buttonStyle(.plain)
            .onHover { hovering in
                isPinHovered = hovering
                if hovering { NSCursor.pointingHand.push() } else { NSCursor.pop() }
            }
            
            if item.type == .image, let data = item.imageData, let nsImage = NSImage(data: data) {
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 36, height: 36)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Gambar disalin")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(.primary)
                    Text("\(data.count / 1024) KB")
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                }
            } else {
                Text(item.content)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(isActionTriggered ? .primary : (isActive ? .primary : .primary.opacity(0.85)))
            }
            
            Spacer()
            
            if isActionTriggered {
                HStack(spacing: 5) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 14))
                    Text("Copied: ")
                        .foregroundColor(.secondary)
                    Text(copiedPreview)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundColor(.primary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.green.opacity(0.1))
                .cornerRadius(6)
                .transition(.move(edge: .trailing).combined(with: .opacity))
            } else if isHovered {
                HStack(spacing: 6) {
                    Button(action: {
                        onDelete?()
                    }) {
                        Image(systemName: "trash")
                            .font(.system(size: 11))
                            .foregroundColor(isDeleteHovered ? .red : .secondary.opacity(0.6))
                            .frame(width: 22, height: 22)
                            .background(isDeleteHovered ? Color.red.opacity(0.1) : Color.clear)
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .onHover { hovering in
                        isDeleteHovered = hovering
                        if hovering { NSCursor.pointingHand.push() } else { NSCursor.pop() }
                    }
                    
                    HStack(spacing: 3) {
                        Image(systemName: "return")
                        Text("Copy")
                    }
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(6)
                }
                .transition(.opacity)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isActionTriggered ? Color.green.opacity(0.12) : (isActive ? Color.primary.opacity(0.04) : Color.clear))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isKeyboardSelected ? Color.accentColor.opacity(0.3) : Color.clear, lineWidth: 1.5)
        )
        .contentShape(Rectangle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.12)) {
                isHovered = hovering
            }
            if hovering { NSCursor.pointingHand.push() } else { NSCursor.pop() }
        }
        .onTapGesture {
            guard !isActionTriggered else { return }
            isActionTriggered = true
            action()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                isActionTriggered = false
            }
        }
    }
}

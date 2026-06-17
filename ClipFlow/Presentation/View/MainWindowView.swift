import SwiftUI
import SwiftData
import Combine

enum ClipMode: String, CaseIterable {
    case clipboard = "Clipboard"
    case snippets = "Snippet"
}

struct MainWindowView: View {
    var viewModel: ClipboardViewModel
    
    @Environment(\.modelContext) private var modelContext
    @State private var selectedFilter: DateFilter = .semua
    @State private var searchText: String = ""
    @State private var clipMode: ClipMode = .clipboard
    @FocusState private var isSearchFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "paperclip.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.accentColor)
                    Text("ClipFlow")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                    Text(clipMode == .clipboard ? "— Clipboard" : "— Snippet")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: {
                    viewModel.clearAll()
                }) {
                    Image(systemName: "trash")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.red.opacity(0.8))
                        .frame(width: 26, height: 26)
                        .background(Color.red.opacity(0.1))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .help("Bersihkan History")
                .disabled(clipMode == .snippets)
                .opacity(clipMode == .snippets ? 0.3 : 1)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 12)
            
            HStack(spacing: 10) {
                HStack(spacing: 6) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    TextField("Cari...", text: $searchText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 13, design: .rounded))
                        .focused($isSearchFocused)
                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
                .cornerRadius(6)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                )
                
                Picker("Mode", selection: $clipMode) {
                    ForEach(ClipMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 200)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 10)
            
            if clipMode == .clipboard {
                HStack(spacing: 8) {
                    ForEach(DateFilter.allCases) { filter in
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedFilter = filter
                            }
                        }) {
                            Text(filter.rawValue)
                                .font(.system(size: 11, weight: selectedFilter == filter ? .semibold : .medium, design: .rounded))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(selectedFilter == filter ? Color.accentColor : Color.primary.opacity(0.04))
                                .foregroundColor(selectedFilter == filter ? .white : .secondary)
                                .cornerRadius(20)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.bottom, 10)
            }
            
            Divider()
            
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
                }
            } else {
                SnippetsListView { content in
                    let pasteboard = NSPasteboard.general
                    pasteboard.clearContents()
                    pasteboard.setString(content, forType: .string)
                    NSSound(named: "Pop")?.play()
                }
            }
        }
        .frame(minWidth: 450, minHeight: 500)
    }
}

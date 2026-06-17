import SwiftUI
import Combine

struct SnippetsListView: View {
    let action: (String) -> Void
    var readOnly: Bool = false
    
    @State private var snippets = SnippetManager.snippets
    @State private var showAdd = false
    @FocusState private var isListFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            if !readOnly {
                HStack {
                    Spacer()
                    Button {
                        showAdd = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.accentColor)
                        Text("Tambah Snippet")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundColor(.accentColor)
                    }
                    .buttonStyle(.plain)
                    .help("Tambah Snippet")
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
            
            if snippets.isEmpty {
                VStack(spacing: 16) {
                    Spacer(minLength: 30)
                    Image(systemName: "text.alignleft")
                        .font(.system(size: 28))
                        .foregroundColor(.secondary.opacity(0.4))
                    VStack(spacing: 4) {
                        Text("Belum ada snippet")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundColor(.secondary)
                        if readOnly {
                            Text("Buka App Window untuk menambah snippet")
                                .font(.system(size: 11, design: .rounded))
                                .foregroundColor(.secondary.opacity(0.6))
                                .multilineTextAlignment(.center)
                                .frame(width: 200)
                        } else {
                            Text("Klik \"Tambah Snippet\" untuk menyimpan template teks")
                                .font(.system(size: 11, design: .rounded))
                                .foregroundColor(.secondary.opacity(0.6))
                                .multilineTextAlignment(.center)
                                .frame(width: 200)
                        }
                    }
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 6) {
                            ForEach(snippets) { snippet in
                                SnippetRow(snippet: snippet, action: { action(snippet.content) }, onDelete: {
                                    SnippetManager.delete(snippet.id)
                                    withAnimation {
                                        snippets = SnippetManager.snippets
                                    }
                                }, readOnly: readOnly)
                                .id(snippet.id)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                    }
                    .focusable()
                    .focused($isListFocused)
                    .onAppear { isListFocused = true }
                }
            }
        }
        .onReceive(Timer.publish(every: 2.0, on: .main, in: .common).autoconnect()) { _ in
            snippets = SnippetManager.snippets
        }
        .sheet(isPresented: $showAdd) {
            AddSnippetView { title, content in
                SnippetManager.add(title: title, content: content)
                withAnimation {
                    snippets = SnippetManager.snippets
                }
            }
        }
    }
}

struct SnippetRow: View {
    let snippet: Snippet
    let action: () -> Void
    let onDelete: () -> Void
    var readOnly: Bool = false
    
    @State private var isHovered = false
    @State private var isActionTriggered = false
    @State private var isDeleteHovered = false
    
    var body: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 3) {
                Text(snippet.title)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                Text(snippet.content)
                    .lineLimit(2)
                    .truncationMode(.tail)
                    .font(.system(size: 11, weight: .regular, design: .rounded))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if isActionTriggered {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 12))
                    Text("Copied")
                }
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(.green)
                .transition(.opacity)
            } else if isHovered && !readOnly {
                HStack(spacing: 4) {
                    Button {
                        withAnimation { onDelete() }
                    } label: {
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
                    
                    HStack(spacing: 2) {
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
            } else if isHovered {
                HStack(spacing: 2) {
                    Image(systemName: "return")
                    Text("Copy")
                }
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.accentColor)
                .foregroundColor(.white)
                .cornerRadius(6)
                .transition(.opacity)
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isActionTriggered ? Color.green.opacity(0.12) : (isHovered ? Color.primary.opacity(0.04) : Color.clear))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
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
struct AddSnippetView: View {
    @Environment(\.dismiss) private var dismiss
    let onSave: (String, String) -> Void
    
    @State private var title = ""
    @State private var content = ""
    @FocusState private var focusedField: Field?
    
    enum Field { case title, content }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Snippet Baru")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                Spacer()
                Button("Batal") { dismiss() }
                    .buttonStyle(.plain)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 16)
            
            Divider()
            
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Judul")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundColor(.secondary)
                    TextField("Misal: Alamat Email", text: $title)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 13, design: .rounded))
                        .focused($focusedField, equals: .title)
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("Konten")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundColor(.secondary)
                    TextEditor(text: $content)
                        .font(.system(size: 13, design: .rounded))
                        .frame(minHeight: 80, maxHeight: 120)
                        .focused($focusedField, equals: .content)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.primary.opacity(0.12), lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                
                HStack {
                    Text("Enter untuk simpan, Esc untuk batal")
                        .font(.system(size: 10, design: .rounded))
                        .foregroundColor(.secondary.opacity(0.6))
                    Spacer()
                    Button("Simpan") {
                        guard !title.trimmingCharacters(in: .whitespaces).isEmpty,
                              !content.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                        onSave(title.trimmingCharacters(in: .whitespaces),
                               content.trimmingCharacters(in: .whitespaces))
                        dismiss()
                    }
                    .buttonStyle(.plain)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(.accentColor)
                    .opacity(title.trimmingCharacters(in: .whitespaces).isEmpty || content.trimmingCharacters(in: .whitespaces).isEmpty ? 0.4 : 1)
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty || content.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .padding(20)
        }
        .frame(width: 340)
        .onAppear { focusedField = .title }
        .onKeyPress(.return) {
            if focusedField != nil {
                guard !title.trimmingCharacters(in: .whitespaces).isEmpty,
                      !content.trimmingCharacters(in: .whitespaces).isEmpty else { return .handled }
                onSave(title.trimmingCharacters(in: .whitespaces),
                       content.trimmingCharacters(in: .whitespaces))
                dismiss()
                return .handled
            }
            return .handled
        }
        .onKeyPress(.escape) {
            dismiss()
            return .handled
        }
    }
}

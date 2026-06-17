import Foundation

struct Snippet: Codable, Hashable, Identifiable {
    var id: UUID
    var title: String
    var content: String
    var timestamp: Date
}

struct SnippetManager {
    private static let key = "SavedSnippets"
    
    static var snippets: [Snippet] {
        get {
            guard let data = UserDefaults.standard.data(forKey: key) else { return [] }
            return (try? JSONDecoder().decode([Snippet].self, from: data)) ?? []
        }
        set {
            guard let data = try? JSONEncoder().encode(newValue) else { return }
            UserDefaults.standard.set(data, forKey: key)
        }
    }
    
    static func add(title: String, content: String) {
        var current = snippets
        let snippet = Snippet(id: UUID(), title: title, content: content, timestamp: Date())
        current.insert(snippet, at: 0)
        snippets = current
    }
    
    static func delete(_ id: UUID) {
        snippets = snippets.filter { $0.id != id }
    }
    
    static func update(_ snippet: Snippet) {
        var current = snippets
        if let index = current.firstIndex(where: { $0.id == snippet.id }) {
            current[index] = snippet
            snippets = current
        }
    }
}

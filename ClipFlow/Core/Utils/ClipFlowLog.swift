import Foundation

let logFileURL: URL = {
    let url = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent("Library/Logs/ClipFlow.log")
    try? FileManager.default.removeItem(at: url)
    return url
}()

func Log(_ message: String) {
    let line = "\(message)\n"
    print(line.trimmingCharacters(in: .newlines))
    if let data = line.data(using: .utf8) {
        if FileManager.default.fileExists(atPath: logFileURL.path) {
            if let handle = try? FileHandle(forWritingTo: logFileURL) {
                handle.seekToEndOfFile()
                handle.write(data)
                handle.closeFile()
            }
        } else {
            try? data.write(to: logFileURL)
        }
    }
}

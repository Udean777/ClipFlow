import SwiftUI

struct RunningApp: Hashable {
    let name: String
    let bundleID: String
}

struct IgnoredAppsSettingsView: View {
    @State private var ignoredIDs = IgnoredAppsManager.ignoredIDs
    
    private var runningApps: [RunningApp] {
        var seen = Set<String>()
        let apps: [RunningApp] = NSWorkspace.shared.runningApplications
            .filter { $0.activationPolicy == .regular }
            .compactMap { app in
                guard let id = app.bundleIdentifier, seen.insert(id).inserted else { return nil }
                return RunningApp(name: app.localizedName ?? id, bundleID: id)
            }
        return apps.sorted { $0.name.lowercased() < $1.name.lowercased() }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Form {
                Section {
                    if runningApps.isEmpty {
                        HStack {
                            Spacer()
                            VStack(spacing: 8) {
                                Image(systemName: "apps.ipad")
                                    .font(.system(size: 24))
                                    .foregroundColor(.secondary.opacity(0.5))
                                Text("Tidak ada aplikasi ditemukan")
                                    .font(.system(size: 13, design: .rounded))
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                        .padding(.top, 30)
                    } else {
                        ForEach(runningApps, id: \.bundleID) { app in
                            HStack(spacing: 10) {
                                let icon = NSWorkspace.shared.icon(forFile: NSWorkspace.shared.urlForApplication(withBundleIdentifier: app.bundleID)?.path ?? "")
                                Image(nsImage: icon)
                                    .resizable()
                                    .frame(width: 24, height: 24)
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(app.name)
                                        .font(.system(size: 13, weight: .medium, design: .rounded))
                                    Text(app.bundleID)
                                        .font(.system(size: 9, design: .rounded))
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Toggle("", isOn: Binding(
                                    get: { ignoredIDs.contains(app.bundleID) },
                                    set: { on in
                                        if on {
                                            ignoredIDs.append(app.bundleID)
                                        } else {
                                            ignoredIDs.removeAll { $0 == app.bundleID }
                                        }
                                    }
                                ))
                                .toggleStyle(.switch)
                                .controlSize(.small)
                            }
                        }
                    }
                } header: {
                    Text("Abaikan Aplikasi")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                } footer: {
                    Text("Aplikasi yang diabaikan tidak akan tercapture clipboardnya. Tekan \(Image(systemName: "command")) + , untuk membuka pengaturan ini.")
                        .font(.system(size: 11, design: .rounded))
                }
            }
            .formStyle(.grouped)
        }
        .frame(width: 400, height: 450)
        .onDisappear {
            IgnoredAppsManager.ignoredIDs = ignoredIDs
        }
    }
}

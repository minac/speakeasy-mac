import SwiftUI
import AppKit

struct DirectoryPicker: View {
    @Binding var directory: URL

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Output Directory")

            HStack {
                Text(directory.path)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Button("Browse...") {
                    selectDirectory()
                }
            }
        }
    }

    // MARK: - Directory Selection

    private func selectDirectory() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.canCreateDirectories = true
        panel.allowsMultipleSelection = false
        panel.directoryURL = directory
        panel.message = "Choose where to save audio files"
        panel.prompt = "Select"

        panel.begin { response in
            if response == .OK, let url = panel.url {
                directory = url
            }
        }
    }
}

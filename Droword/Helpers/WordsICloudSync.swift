import Foundation

enum WordsICloudSync {
    nonisolated static let enabledKey = "iCloudSyncEnabled"
    nonisolated private static let containerID = "iCloud.com.droword"
    nonisolated private static let fileName = "words.json"

    nonisolated static var isEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: enabledKey) }
        set { UserDefaults.standard.set(newValue, forKey: enabledKey) }
    }

    nonisolated static var isAvailable: Bool {
        FileManager.default.ubiquityIdentityToken != nil
    }

    nonisolated static func ubiquityWordsURL() -> URL? {
        guard let root = FileManager.default.url(
            forUbiquityContainerIdentifier: containerID
        ) else { return nil }
        let docs = root.appendingPathComponent("Documents", isDirectory: true)
        try? FileManager.default.createDirectory(at: docs, withIntermediateDirectories: true)
        return docs.appendingPathComponent(fileName)
    }

    nonisolated static func push(localFileURL: URL) {
        guard isEnabled, isAvailable, let cloudURL = ubiquityWordsURL() else { return }
        guard let data = try? Data(contentsOf: localFileURL) else { return }

        DispatchQueue.global(qos: .utility).async {
            var error: NSError?
            NSFileCoordinator().coordinate(
                writingItemAt: cloudURL,
                options: .forReplacing,
                error: &error
            ) { url in
                try? data.write(to: url, options: .atomic)
            }
        }
    }

    nonisolated static func pullIfNewer(than localFileURL: URL) -> [StoredWord]? {
        guard isEnabled, isAvailable, let cloudURL = ubiquityWordsURL() else { return nil }

        var remoteData: Data?
        var remoteDate: Date?
        var error: NSError?
        NSFileCoordinator().coordinate(readingItemAt: cloudURL, options: [], error: &error) { url in
            remoteData = try? Data(contentsOf: url)
            remoteDate = (try? FileManager.default.attributesOfItem(atPath: url.path))?[.modificationDate] as? Date
        }
        guard let remoteData, let remoteDate else { return nil }

        let localDate = (try? FileManager.default.attributesOfItem(atPath: localFileURL.path))?[.modificationDate] as? Date
        if let localDate, remoteDate <= localDate { return nil }

        return try? JSONDecoder().decode([StoredWord].self, from: remoteData)
    }
}

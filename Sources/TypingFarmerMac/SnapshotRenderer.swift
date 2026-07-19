import AppKit
import SwiftUI
import TypingFarmerCore
import TypingFarmerMacSupport

struct SnapshotRequest {
    var outputURL: URL
    var size: CGSize
}

enum SnapshotRenderer {
    static func request(from arguments: [String]) -> SnapshotRequest? {
        guard let snapshotIndex = arguments.firstIndex(of: "--snapshot"),
              arguments.indices.contains(snapshotIndex + 1) else {
            return nil
        }

        let outputURL = URL(fileURLWithPath: arguments[snapshotIndex + 1])
        let width = numberValue(after: "--snapshot-width", in: arguments) ?? 1040
        let height = numberValue(after: "--snapshot-height", in: arguments) ?? 680
        return SnapshotRequest(outputURL: outputURL, size: CGSize(width: width, height: height))
    }

    @MainActor
    static func render(_ request: SnapshotRequest) throws {
        let app = NSApplication.shared
        app.setActivationPolicy(.prohibited)

        let model = try makeSnapshotModel()
        let rootView = FarmGameWindowView(model: model)
            .frame(width: request.size.width, height: request.size.height)
            .environment(\.colorScheme, .light)

        let hostingView = NSHostingView(rootView: rootView)
        hostingView.frame = NSRect(origin: .zero, size: request.size)
        hostingView.appearance = NSAppearance(named: .aqua)
        hostingView.wantsLayer = true

        let window = NSWindow(
            contentRect: hostingView.frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.contentView = hostingView
        window.displayIfNeeded()
        hostingView.layoutSubtreeIfNeeded()
        hostingView.displayIfNeeded()
        RunLoop.main.run(until: Date().addingTimeInterval(0.8))

        guard let bitmap = hostingView.bitmapImageRepForCachingDisplay(in: hostingView.bounds) else {
            throw SnapshotError.bitmapCreationFailed
        }
        hostingView.cacheDisplay(in: hostingView.bounds, to: bitmap)

        guard let data = bitmap.representation(using: .png, properties: [:]) else {
            throw SnapshotError.pngEncodingFailed
        }

        try FileManager.default.createDirectory(
            at: request.outputURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try data.write(to: request.outputURL, options: [.atomic])
    }

    private static func numberValue(after flag: String, in arguments: [String]) -> Double? {
        guard let flagIndex = arguments.firstIndex(of: flag),
              arguments.indices.contains(flagIndex + 1) else {
            return nil
        }
        return Double(arguments[flagIndex + 1])
    }

    @MainActor
    private static func makeSnapshotModel() throws -> AppViewModel {
        let store = PersistenceStore(fileURL: snapshotStateURL())
        // Snapshot rendering should never depend on the developer's real save
        // file, so seed a temporary store with deterministic sample state.
        try store.save(AppPersistedState(gameState: snapshotGameState(), windowSettings: WindowSettings()))
        return AppViewModel(store: store)
    }

    private static func snapshotStateURL() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("typing-farmer-snapshot", isDirectory: true)
            .appendingPathComponent("state.json")
    }

    private static func snapshotGameState() -> GameState {
        var state = GameState.defaultState()
        state.coins = 268
        state.unlockedCropIDs = Set(CropDefinition.defaults.map(\.id))
        state.selectedCropID = "tomato"
        state.adoptedPets = [
            PetState(definitionID: "dog", adoptedAt: Date(timeIntervalSince1970: 1)),
            PetState(definitionID: "cat", adoptedAt: Date(timeIntervalSince1970: 2)),
            PetState(definitionID: "dog", adoptedAt: Date(timeIntervalSince1970: 3))
        ]

        // Mix mature and growing plots across crop types to exercise the visual
        // states that are most likely to regress in the offscreen renderer.
        let crops = Dictionary(uniqueKeysWithValues: CropDefinition.defaults.map { ($0.id, $0) })
        let cropIDs = CropDefinition.defaults.map(\.id)
        for index in state.keyPlots.indices {
            let cropID = cropIDs[index % cropIDs.count]
            state.keyPlots[index].cropID = cropID
            let requirement = crops[cropID]?.growRequirement ?? 10
            if index < 10 {
                state.keyPlots[index].progress = requirement
            } else {
                state.keyPlots[index].progress = (index * 3) % max(1, requirement)
            }
        }

        state.tasks = [
            FarmTask(title: "整理今日输入目标"),
            FarmTask(title: "完成 2 轮专注")
        ]
        return state
    }
}

enum SnapshotError: Error {
    case bitmapCreationFailed
    case pngEncodingFailed
}

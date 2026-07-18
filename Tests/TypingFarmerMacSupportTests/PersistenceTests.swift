import Foundation
import TypingFarmerCore
@testable import TypingFarmerMacSupport

private let runPersistenceTests: Void = {
    testMissingFileLoadsDefaultAppState()
    testNewEnvelopeRoundTripsGameAndWindowState()
    testLegacyTopLevelGameStateDecodesAndPreservesWindowSettings()
    testLegacyVersionOneSaveMigratesToKeyboardPlots()
    testCorruptFileStillThrowsForViewModelFallback()
    testSavingLegacyStateMigratesToEnvelopeFormat()
}()

private func testMissingFileLoadsDefaultAppState() {
    let store = PersistenceStore(fileURL: temporaryFileURL())

    do {
        let state = try store.load()
        precondition(state.version == AppPersistedState.currentVersion)
        precondition(state.gameState.coins == 0)
        precondition(state.gameState.unlockedCropIDs == ["wheat"])
        precondition(state.gameState.keyPlots.count == MacKeyboardLayout.allKeys.count)
        precondition(state.gameState.adoptedPets.map(\.definitionID) == ["dog"])
        precondition(state.windowSettings == WindowSettings())
    } catch {
        preconditionFailure("Missing file should load default app state: \(error)")
    }
}

private func testNewEnvelopeRoundTripsGameAndWindowState() {
    let url = temporaryFileURL()
    let store = PersistenceStore(fileURL: url)
    var gameState = GameState.defaultState()
    gameState.coins = 123
    gameState.tasks = [FarmTask(title: "写日报")]
    gameState.keyPlots[0].progress = 7
    gameState.adoptedPets.append(PetState(definitionID: "cat", adoptedAt: Date(timeIntervalSince1970: 10)))
    let windowSettings = WindowSettings(isAlwaysOnTop: false, isVisible: false, x: 10, y: 20, width: 1200, height: 720)

    do {
        try store.save(AppPersistedState(gameState: gameState, windowSettings: windowSettings))
        let loaded = try store.load()
        precondition(loaded.version == AppPersistedState.currentVersion)
        precondition(loaded.gameState.coins == 123)
        precondition(loaded.gameState.tasks.map(\.title) == ["写日报"])
        precondition(loaded.gameState.keyPlots[0].progress == 7)
        precondition(loaded.gameState.adoptedPets.map(\.definitionID) == ["dog", "cat"])
        precondition(loaded.windowSettings == windowSettings)
    } catch {
        preconditionFailure("App envelope should round trip: \(error)")
    }
}

private func testLegacyTopLevelGameStateDecodesAndPreservesWindowSettings() {
    let url = temporaryFileURL()
    let json = """
    {
      "version": 2,
      "coins": 77,
      "unlockedCropIDs": ["wheat", "tomato"],
      "keyPlots": [
        {"keyID": "kc_0", "keyCode": 0, "keyLabel": "A", "widthUnits": 1, "cropID": "tomato", "progress": 11}
      ],
      "selectedCropID": "tomato",
      "tasks": [{"id": "\(UUID())", "title": "旧任务", "isDone": false, "createdAt": "2026-06-05T08:00:00Z"}],
      "dailyStats": {},
      "pomodoroSettings": {"durationMinutes": 30},
      "windowSettings": {"isAlwaysOnTop": false, "isVisible": false, "x": 31, "y": 42, "width": 1200, "height": 720}
    }
    """

    do {
        try write(json, to: url)
        let loaded = try PersistenceStore(fileURL: url).load()
        precondition(loaded.version == AppPersistedState.currentVersion)
        precondition(loaded.gameState.version == GameState.currentVersion)
        precondition(loaded.gameState.coins == 77)
        precondition(loaded.gameState.selectedCropID == "tomato")
        precondition(loaded.gameState.tasks.map(\.title) == ["旧任务"])
        precondition(loaded.gameState.pomodoroSettings.durationMinutes == 30)
        precondition(loaded.gameState.keyPlots.count == MacKeyboardLayout.allKeys.count)
        precondition(loaded.gameState.keyPlots.first { $0.keyCode == 0 }?.progress == 11)
        precondition(loaded.gameState.adoptedPets.map(\.definitionID) == ["dog"])
        precondition(loaded.windowSettings.isAlwaysOnTop == false)
        precondition(loaded.windowSettings.isVisible == false)
        precondition(loaded.windowSettings.x == 31)
        precondition(loaded.windowSettings.y == 42)
        precondition(loaded.windowSettings.width == 1200)
        precondition(loaded.windowSettings.height == 720)
    } catch {
        preconditionFailure("Legacy top-level state should decode: \(error)")
    }
}

private func testLegacyVersionOneSaveMigratesToKeyboardPlots() {
    let url = temporaryFileURL()
    let json = """
    {
      "version": 1,
      "coins": 77,
      "unlockedCropIDs": ["wheat", "tomato"],
      "plots": [{"id": "\(UUID())", "cropID": "wheat", "progress": 9}],
      "tasks": [{"id": "\(UUID())", "title": "旧任务", "isDone": false, "createdAt": "2026-06-05T08:00:00Z"}],
      "dailyStats": {},
      "pomodoroSettings": {"durationMinutes": 30}
    }
    """

    do {
        try write(json, to: url)
        let loaded = try PersistenceStore(fileURL: url).load()
        precondition(loaded.gameState.version == GameState.currentVersion)
        precondition(loaded.gameState.coins == 77)
        precondition(loaded.gameState.unlockedCropIDs.contains("tomato"))
        precondition(loaded.gameState.tasks.map(\.title) == ["旧任务"])
        precondition(loaded.gameState.pomodoroSettings.durationMinutes == 30)
        precondition(loaded.gameState.keyPlots.count == MacKeyboardLayout.allKeys.count)
        precondition(loaded.gameState.adoptedPets.map(\.definitionID) == ["dog"])
        precondition(loaded.windowSettings == WindowSettings())
    } catch {
        preconditionFailure("Legacy v1 state should migrate: \(error)")
    }
}

private func testCorruptFileStillThrowsForViewModelFallback() {
    let url = temporaryFileURL()

    do {
        try write("{not json", to: url)
        _ = try PersistenceStore(fileURL: url).load()
        preconditionFailure("Corrupt file should throw.")
    } catch {
        return
    }
}

private func testSavingLegacyStateMigratesToEnvelopeFormat() {
    let url = temporaryFileURL()
    let legacyJSON = """
    {
      "version": 2,
      "coins": 12,
      "unlockedCropIDs": ["wheat"],
      "keyPlots": [],
      "selectedCropID": "wheat",
      "tasks": [],
      "dailyStats": {},
      "pomodoroSettings": {"durationMinutes": 25},
      "windowSettings": {"isAlwaysOnTop": false, "isVisible": true, "width": 1040, "height": 680}
    }
    """

    do {
        try write(legacyJSON, to: url)
        let store = PersistenceStore(fileURL: url)
        let loaded = try store.load()
        try store.save(loaded)
        let savedJSON = try String(contentsOf: url, encoding: .utf8)
        precondition(savedJSON.contains("\"gameState\""))
        precondition(savedJSON.contains("\"windowSettings\""))
    } catch {
        preconditionFailure("Legacy state should save back as app envelope: \(error)")
    }
}

private func temporaryFileURL() -> URL {
    FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString, isDirectory: true)
        .appendingPathComponent("state.json")
}

private func write(_ string: String, to url: URL) throws {
    try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
    try Data(string.utf8).write(to: url)
}

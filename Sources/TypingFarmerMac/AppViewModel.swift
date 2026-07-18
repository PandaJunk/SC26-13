import AppKit
import Foundation
import SwiftUI
import TypingFarmerCore
import TypingFarmerMacSupport

@MainActor
final class AppViewModel: ObservableObject {
    @Published private(set) var state: GameState
    @Published private(set) var windowSettings: WindowSettings
    @Published private(set) var permissionStatus: InputMonitor.PermissionStatus = .notAuthorized
    @Published private(set) var pomodoro: PomodoroTimerModel
    @Published private(set) var harvestAnimationEvents: [HarvestAnimationEvent] = []
    @Published var newTaskTitle = ""
    @Published var selectedTab: AppTab = .farm
    @Published var lastError: String?

    let crops = CropDefinition.defaults
    let petDefinitions = PetDefinition.defaults

    private let store: PersistenceStore
    private lazy var monitor = InputMonitor { [weak self] event in
        DispatchQueue.main.async {
            self?.applyInput(event)
        }
    }
    private var timer: Timer?
    private var petHarvestTimer: Timer?
    private var pendingPetHarvests: [UUID: String] = [:]
    private var nextPetHarvestAt: [UUID: Date] = [:]
    private let petHarvestInterval: TimeInterval = 24
    private let petHarvestCheckInterval: TimeInterval = 4

    init(store: PersistenceStore) {
        self.store = store
        do {
            let loadedState = try store.load()
            state = loadedState.gameState
            windowSettings = loadedState.windowSettings
            pomodoro = PomodoroTimerModel(settings: loadedState.gameState.pomodoroSettings)
        } catch {
            state = .defaultState()
            windowSettings = WindowSettings()
            pomodoro = PomodoroTimerModel()
            lastError = "读取存档失败，已使用默认农场。"
        }
        schedulePetHarvestTimer()
    }

    deinit {
        timer?.invalidate()
        petHarvestTimer?.invalidate()
    }

    var cropsByID: [String: CropDefinition] {
        Dictionary(uniqueKeysWithValues: crops.map { ($0.id, $0) })
    }

    var unlockedCrops: [CropDefinition] {
        crops.filter { state.unlockedCropIDs.contains($0.id) }
    }

    var lockedCrops: [CropDefinition] {
        crops.filter { !state.unlockedCropIDs.contains($0.id) }
    }

    var todayStats: DailyStats {
        FarmEngine(state: state, cropDefinitions: crops).todayStats()
    }

    var selectedCrop: CropDefinition? {
        cropsByID[state.selectedCropID]
    }

    var petDefinitionsByID: [String: PetDefinition] {
        Dictionary(uniqueKeysWithValues: petDefinitions.map { ($0.id, $0) })
    }

    func petDefinition(for pet: PetState) -> PetDefinition? {
        petDefinitionsByID[pet.definitionID]
    }

    func startInputMonitoring() {
        permissionStatus = monitor.refreshPermissionStatus()
        guard permissionStatus == .authorized else {
            return
        }
        if !monitor.start() {
            lastError = "输入监听启动失败，请确认辅助功能权限。"
        }
    }

    func requestAccessibilityPermission() {
        InputMonitor.requestAccessibilityPermissionPrompt()
        permissionStatus = monitor.refreshPermissionStatus()
    }

    func refreshPermission() {
        startInputMonitoring()
    }

    func applyInput(_ event: InputEvent) {
        guard permissionStatus == .authorized else {
            return
        }
        updateState { engine in
            engine.apply(event)
        }
    }

    func harvest(keyID: String) {
        var animationEvent: HarvestAnimationEvent?
        updateState { engine in
            if let plot = engine.state.keyPlots.first(where: { $0.keyID == keyID }),
               let coins = engine.harvest(keyID: keyID) {
                animationEvent = HarvestAnimationEvent(
                    keyID: plot.keyID,
                    keyCode: plot.keyCode,
                    coins: coins,
                    source: .player
                )
            }
        }
        if let animationEvent {
            appendHarvestEvents([animationEvent])
        }
    }

    func plant(cropID: String, in keyID: String) {
        updateState { engine in
            _ = engine.plant(cropID: cropID, in: keyID)
        }
    }

    func unlockCrop(id: String) {
        updateState { engine in
            _ = engine.unlockCrop(id: id)
        }
    }

    func adoptPet(definitionID: String) {
        updateState { engine in
            _ = engine.adoptPet(definitionID: definitionID)
        }
    }

    func selectCrop(id: String) {
        updateState { engine in
            _ = engine.selectCrop(id: id)
        }
    }

    func addTask() {
        let title = newTaskTitle
        newTaskTitle = ""
        updateState { engine in
            engine.addTask(title: title)
        }
    }

    func toggleTask(id: UUID) {
        updateState { engine in
            _ = engine.toggleTask(id: id)
        }
    }

    func deleteTask(id: UUID) {
        updateState { engine in
            _ = engine.deleteTask(id: id)
        }
    }

    func setPomodoroDuration(_ minutes: Int) {
        pomodoro.setDurationMinutes(minutes)
        state.pomodoroSettings = PomodoroSettings(durationMinutes: pomodoro.durationMinutes)
        save()
    }

    func startPomodoro() {
        pomodoro.start()
        scheduleTimer()
    }

    func pausePomodoro() {
        pomodoro.pause()
        timer?.invalidate()
        timer = nil
    }

    func resetPomodoro() {
        pomodoro.reset()
        timer?.invalidate()
        timer = nil
    }

    func resetFarm() {
        state = .defaultState()
        windowSettings = WindowSettings()
        pomodoro = PomodoroTimerModel()
        harvestAnimationEvents = []
        pendingPetHarvests = [:]
        nextPetHarvestAt = [:]
        newTaskTitle = ""
        syncPetHarvestSchedule()
        save()
    }

    func quit() {
        NSApplication.shared.terminate(nil)
    }

    func setAlwaysOnTop(_ isAlwaysOnTop: Bool) {
        windowSettings.isAlwaysOnTop = isAlwaysOnTop
        save()
        NotificationCenter.default.post(name: .typingFarmerAlwaysOnTopChanged, object: nil)
    }

    func setWindowVisible(_ isVisible: Bool) {
        windowSettings.isVisible = isVisible
        save()
    }

    func updateWindowFrame(x: Double, y: Double, width: Double, height: Double) {
        windowSettings.x = x
        windowSettings.y = y
        windowSettings.width = width
        windowSettings.height = height
        save()
    }

    private func scheduleTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] timer in
            Task { @MainActor in
                guard let self else {
                    timer.invalidate()
                    return
                }
                let completed = self.pomodoro.advance(seconds: 1)
                if completed > 0 {
                    timer.invalidate()
                    self.timer = nil
                    self.updateState { engine in
                        engine.recordFocusSession()
                    }
                }
            }
        }
    }

    private func schedulePetHarvestTimer() {
        syncPetHarvestSchedule()
        petHarvestTimer?.invalidate()
        petHarvestTimer = Timer.scheduledTimer(withTimeInterval: petHarvestCheckInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.performPetHarvestChecks()
            }
        }
        petHarvestTimer?.tolerance = 1.5
    }

    private func syncPetHarvestSchedule(now: Date = Date()) {
        let adoptedIDs = Set(state.adoptedPets.map(\.id))
        pendingPetHarvests = pendingPetHarvests.filter { adoptedIDs.contains($0.key) }
        nextPetHarvestAt = nextPetHarvestAt.filter { adoptedIDs.contains($0.key) }

        let stagger = state.adoptedPets.isEmpty
            ? 0
            : min(6, petHarvestInterval / Double(max(1, state.adoptedPets.count)))
        for (index, pet) in state.adoptedPets.enumerated() where nextPetHarvestAt[pet.id] == nil {
            nextPetHarvestAt[pet.id] = now.addingTimeInterval(Double(index) * stagger)
        }
    }

    private func performPetHarvestChecks(now: Date = Date()) {
        syncPetHarvestSchedule(now: now)
        let engine = FarmEngine(state: state, cropDefinitions: crops, petDefinitions: petDefinitions)
        var claimedKeyIDs = Set(pendingPetHarvests.values)
        var events: [HarvestAnimationEvent] = []

        for pet in state.adoptedPets {
            guard pendingPetHarvests[pet.id] == nil,
                  (nextPetHarvestAt[pet.id] ?? now) <= now,
                  let definition = petDefinition(for: pet) else {
                continue
            }

            nextPetHarvestAt[pet.id] = now.addingTimeInterval(petHarvestInterval)
            guard let result = engine.firstMatureHarvestCandidate(excluding: claimedKeyIDs) else {
                continue
            }

            pendingPetHarvests[pet.id] = result.keyID
            claimedKeyIDs.insert(result.keyID)
            events.append(HarvestAnimationEvent(
                keyID: result.keyID,
                keyCode: result.keyCode,
                coins: result.coins,
                source: .pet(PetHarvestSource(
                    petID: pet.id,
                    species: definition.species,
                    assetPrefix: definition.assetPrefix
                ))
            ))
        }

        appendHarvestEvents(events)
    }

    func completePetHarvest(petID: UUID, keyID: String) -> Bool {
        guard pendingPetHarvests[petID] == keyID else {
            return false
        }
        pendingPetHarvests[petID] = nil

        var didHarvest = false
        updateState { engine in
            didHarvest = engine.harvest(keyID: keyID) != nil
        }
        return didHarvest
    }

    private func appendHarvestEvents(_ events: [HarvestAnimationEvent]) {
        guard !events.isEmpty else {
            return
        }
        harvestAnimationEvents = Array((harvestAnimationEvents + events).suffix(24))
    }

    private func updateState(_ mutation: (inout FarmEngine) -> Void) {
        var engine = FarmEngine(state: state, cropDefinitions: crops, petDefinitions: petDefinitions)
        mutation(&engine)
        state = engine.state
        syncPetHarvestSchedule()
        save()
    }

    private func save() {
        do {
            try store.save(AppPersistedState(gameState: state, windowSettings: windowSettings))
            lastError = nil
        } catch {
            lastError = "保存失败：\(error.localizedDescription)"
        }
    }
}

extension Notification.Name {
    static let typingFarmerAlwaysOnTopChanged = Notification.Name("typingFarmerAlwaysOnTopChanged")
    static let typingFarmerShowControlPanel = Notification.Name("typingFarmerShowControlPanel")
}

enum AppTab: String, CaseIterable, Identifiable {
    case farm = "农场"
    case focus = "专注"
    case settings = "设置"

    var id: String {
        rawValue
    }
}

struct HarvestAnimationEvent: Equatable, Identifiable {
    enum Source: Equatable {
        case player
        case pet(PetHarvestSource)
    }

    let id = UUID()
    let keyID: String
    let keyCode: Int
    let coins: Int
    let source: Source
    let timestamp = Date()
}

struct PetHarvestSource: Equatable {
    let petID: UUID
    let species: PetSpecies
    let assetPrefix: String
}

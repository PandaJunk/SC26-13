import AppKit
import AVFoundation
import SwiftUI
import TypingFarmerCore
import TypingFarmerMacSupport

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var windowController: FarmWindowController?
    private var controlPanelController: FarmControlPanelController?
    private var viewModel: AppViewModel?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let store = PersistenceStore()
        let model = AppViewModel(store: store)
        viewModel = model

        let controller = FarmWindowController(model: model)
        windowController = controller
        controlPanelController = FarmControlPanelController(model: model)

        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem = item
        item.button?.image = NSImage(systemSymbolName: "leaf.fill", accessibilityDescription: "Typing Farmer")
        item.button?.title = " 农场"
        item.button?.target = self
        item.button?.action = #selector(toggleWindow(_:))

        model.startInputMonitoring()
        if model.windowSettings.isVisible {
            controller.showWindow(nil)
        }
    }

    @objc private func toggleWindow(_ sender: AnyObject?) {
        windowController?.toggleWindow()
    }
}

final class FarmWindowController: NSWindowController, NSWindowDelegate {
    private let model: AppViewModel
    private let backgroundMusicPlayer = BackgroundMusicPlayer(resourceName: "bgm", fileExtension: "mp3")

    init(model: AppViewModel) {
        self.model = model

        let settings = model.windowSettings
        let initialSize = NSSize(width: max(1040, settings.width), height: max(680, settings.height))
        let rect: NSRect
        if let x = settings.x, let y = settings.y {
            rect = NSRect(x: x, y: y, width: initialSize.width, height: initialSize.height)
        } else {
            rect = NSRect(origin: .zero, size: initialSize)
        }

        let window = FarmPanel(
            contentRect: rect,
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.title = "指尖农场"
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.isMovableByWindowBackground = true
        window.backgroundColor = .clear
        window.isReleasedWhenClosed = false
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.level = settings.isAlwaysOnTop ? .floating : .normal
        window.minSize = NSSize(width: 1040, height: 680)
        window.standardWindowButton(.closeButton)?.isHidden = true
        window.standardWindowButton(.miniaturizeButton)?.isHidden = true
        window.standardWindowButton(.zoomButton)?.isHidden = true
        window.contentViewController = NSHostingController(rootView: FarmGameWindowView(model: model))

        super.init(window: window)
        window.delegate = self
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applyWindowLevel),
            name: .typingFarmerAlwaysOnTopChanged,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(hideGameWindow),
            name: .typingFarmerHideWindow,
            object: nil
        )
        if settings.x == nil || settings.y == nil {
            window.center()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func toggleWindow() {
        guard let window else {
            return
        }
        if window.isVisible, NSApp.isActive, window.isKeyWindow {
            window.orderOut(nil)
            model.setWindowVisible(false)
            backgroundMusicPlayer.pause()
        } else {
            showWindow(nil)
        }
    }

    override func showWindow(_ sender: Any?) {
        ensureWindowIsOnScreen()
        NSApp.activate(ignoringOtherApps: true)
        super.showWindow(sender)
        applyWindowLevel()
        window?.orderFrontRegardless()
        window?.makeKeyAndOrderFront(sender)
        model.setWindowVisible(true)
        backgroundMusicPlayer.play()
    }

    @objc private func applyWindowLevel() {
        window?.level = model.windowSettings.isAlwaysOnTop ? .floating : .normal
    }

    @objc private func hideGameWindow() {
        saveWindowFrame()
        window?.orderOut(nil)
        model.setWindowVisible(false)
        backgroundMusicPlayer.pause()
    }

    func windowDidMove(_ notification: Notification) {
        saveWindowFrame()
    }

    func windowDidResize(_ notification: Notification) {
        saveWindowFrame()
    }

    func windowWillClose(_ notification: Notification) {
        saveWindowFrame()
        model.setWindowVisible(false)
        backgroundMusicPlayer.pause()
    }

    func windowDidBecomeKey(_ notification: Notification) {
        guard window?.isVisible == true else {
            return
        }
        backgroundMusicPlayer.play()
    }

    func windowDidResignKey(_ notification: Notification) {
        backgroundMusicPlayer.pause()
    }

    private func saveWindowFrame() {
        guard let frame = window?.frame else {
            return
        }
        model.updateWindowFrame(
            x: frame.origin.x,
            y: frame.origin.y,
            width: frame.width,
            height: frame.height
        )
    }

    private func ensureWindowIsOnScreen() {
        guard let window else {
            return
        }
        let visibleFrames = NSScreen.screens.map(\.visibleFrame)
        if let currentScreen = NSScreen.screens.first(where: { $0.visibleFrame.intersects(window.frame) }) ?? NSScreen.main {
            let visibleFrame = currentScreen.visibleFrame.insetBy(dx: 18, dy: 18)
            var frame = window.frame
            frame.size.width = min(frame.width, visibleFrame.width)
            frame.size.height = min(frame.height, visibleFrame.height)
            frame.origin.x = min(max(frame.origin.x, visibleFrame.minX), visibleFrame.maxX - frame.width)
            frame.origin.y = min(max(frame.origin.y, visibleFrame.minY), visibleFrame.maxY - frame.height)
            if frame != window.frame {
                window.setFrame(frame, display: false)
                saveWindowFrame()
            }
        }
        let intersectsVisibleScreen = visibleFrames.contains { screenFrame in
            window.frame.intersection(screenFrame).width >= 120
                && window.frame.intersection(screenFrame).height >= 120
        }
        if !intersectsVisibleScreen {
            window.center()
            saveWindowFrame()
        }
    }
}

final class FarmControlPanelController: NSWindowController {
    private let model: AppViewModel

    init(model: AppViewModel) {
        self.model = model

        let window = FarmPanel(
            contentRect: NSRect(x: 0, y: 0, width: 360, height: 640),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.title = "农场面板"
        window.titlebarAppearsTransparent = true
        window.backgroundColor = .clear
        window.isReleasedWhenClosed = false
        window.level = model.windowSettings.isAlwaysOnTop ? .floating : .normal
        window.minSize = NSSize(width: 320, height: 560)
        window.contentViewController = NSHostingController(rootView: FarmControlPanelView(model: model))

        super.init(window: window)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(showPanel),
            name: .typingFarmerShowControlPanel,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applyWindowLevel),
            name: .typingFarmerAlwaysOnTopChanged,
            object: nil
        )
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func showPanel() {
        if window?.isVisible != true {
            window?.center()
        }
        applyWindowLevel()
        showWindow(nil)
        window?.orderFrontRegardless()
        window?.makeKeyAndOrderFront(nil)
    }

    @objc private func applyWindowLevel() {
        window?.level = model.windowSettings.isAlwaysOnTop ? .floating : .normal
    }
}

final class FarmPanel: NSPanel {
    override var canBecomeKey: Bool {
        true
    }

    override var canBecomeMain: Bool {
        true
    }
}

final class BackgroundMusicPlayer {
    private static let fadeDuration: TimeInterval = 1.5
    private static let playbackVolume: Float = 0.35

    private let resourceName: String
    private let fileExtension: String
    private var player: AVAudioPlayer?
    private var didAttemptLoad = false
    private var pendingPause: DispatchWorkItem?

    init(resourceName: String, fileExtension: String) {
        self.resourceName = resourceName
        self.fileExtension = fileExtension
    }

    func play() {
        loadPlayerIfNeeded()
        pendingPause?.cancel()
        pendingPause = nil

        guard let player else {
            return
        }

        if !player.isPlaying {
            player.volume = 0
            player.play()
        }
        player.setVolume(Self.playbackVolume, fadeDuration: Self.fadeDuration)
    }

    func pause() {
        pendingPause?.cancel()

        guard let player, player.isPlaying else {
            return
        }

        player.setVolume(0, fadeDuration: Self.fadeDuration)
        let pauseWork = DispatchWorkItem { [weak self, weak player] in
            guard let self, let player, self.pendingPause?.isCancelled == false else {
                return
            }
            player.pause()
            player.volume = Self.playbackVolume
            self.pendingPause = nil
        }
        pendingPause = pauseWork
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.fadeDuration, execute: pauseWork)
    }

    private func loadPlayerIfNeeded() {
        guard !didAttemptLoad else {
            return
        }
        didAttemptLoad = true

        guard let url = Bundle.module.url(forResource: resourceName, withExtension: fileExtension) else {
            NSLog("Typing Farmer BGM resource not found: \(resourceName).\(fileExtension)")
            return
        }

        do {
            let audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer.numberOfLoops = -1
            audioPlayer.volume = 0.35
            audioPlayer.prepareToPlay()
            player = audioPlayer
        } catch {
            NSLog("Typing Farmer failed to load BGM: \(error)")
        }
    }
}

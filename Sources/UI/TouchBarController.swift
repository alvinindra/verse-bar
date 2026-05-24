import Cocoa
import SwiftUI
import Combine

/// Hosting controller for the popover that vends an NSTouchBar.
/// When the popover is visible, macOS shows this Touch Bar in the app region (left)
/// of the MacBook Pro Touch Bar.
///
/// We intentionally do NOT use the private Control Strip (system tray) API.
/// Apple closed that on macOS Sequoia (15.x) — third-party tray items are silently
/// ignored even when `addSystemTrayItem:` reports success.
final class PopoverHostingController: NSHostingController<PopoverView>, NSTouchBarDelegate {

    private let lyricId    = NSTouchBarItem.Identifier("com.versebar.popover.touchbar.lyric")
    private let controlsId = NSTouchBarItem.Identifier("com.versebar.popover.touchbar.controls")

    private weak var lyricLabel: NSTextField?
    private weak var playPauseButton: NSButton?

    private var playbackEngine = PlaybackEngine.shared
    private var lyricsService = LyricsService.shared
    private var cancellables = Set<AnyCancellable>()

    override func makeTouchBar() -> NSTouchBar? {
        let bar = NSTouchBar()
        bar.delegate = self
        bar.customizationIdentifier = NSTouchBar.CustomizationIdentifier("com.versebar.popover.touchbar")
        bar.defaultItemIdentifiers = [lyricId, .flexibleSpace, controlsId]
        bar.customizationAllowedItemIdentifiers = [lyricId, controlsId]
        return bar
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        // NSPopover doesn't always propagate makeTouchBar() down the responder
        // chain to the active Touch Bar — assign it explicitly to the popover
        // window so the lyric appears reliably when the popover opens.
        guard let window = view.window else {
            Logger.error("PopoverHostingController.viewDidAppear: no window", category: "touchbar")
            return
        }
        let bar = makeTouchBar()
        window.touchBar = bar
        self.touchBar = bar
        window.makeFirstResponder(self)
        Logger.info("🎛 Touch Bar attached to popover window", category: "touchbar")
    }

    override func viewDidDisappear() {
        super.viewDidDisappear()
        view.window?.touchBar = nil
        self.touchBar = nil
    }

    func touchBar(_ touchBar: NSTouchBar, makeItemForIdentifier identifier: NSTouchBarItem.Identifier) -> NSTouchBarItem? {
        switch identifier {
        case lyricId:
            return makeLyricItem()
        case controlsId:
            return makeControlsItem()
        default:
            return nil
        }
    }

    private func makeLyricItem() -> NSTouchBarItem {
        let label = NSTextField(labelWithString: currentText())
        label.font = .systemFont(ofSize: 15, weight: .semibold)
        label.textColor = .white
        label.lineBreakMode = .byTruncatingTail
        label.maximumNumberOfLines = 1
        label.cell?.truncatesLastVisibleLine = true
        label.setContentHuggingPriority(.defaultLow, for: .horizontal)
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        self.lyricLabel = label
        bindLyricUpdates()

        let stack = NSStackView(views: [label])
        stack.orientation = .horizontal
        stack.alignment = .centerY
        stack.edgeInsets = NSEdgeInsets(top: 0, left: 12, bottom: 0, right: 12)
        let width = stack.widthAnchor.constraint(equalToConstant: 560)
        width.priority = .defaultHigh
        width.isActive = true

        let item = NSCustomTouchBarItem(identifier: lyricId)
        item.view = stack
        item.customizationLabel = "Synced Lyric"
        return item
    }

    private func makeControlsItem() -> NSTouchBarItem {
        let prev = makeMediaButton(symbol: "backward.fill",
                                   accessibility: "Previous track",
                                   action: #selector(handlePrevious))
        let playPause = makeMediaButton(symbol: currentPlayPauseSymbol(),
                                        accessibility: "Play or pause",
                                        action: #selector(handlePlayPause))
        playPause.contentTintColor = .systemBlue
        self.playPauseButton = playPause
        let next = makeMediaButton(symbol: "forward.fill",
                                   accessibility: "Next track",
                                   action: #selector(handleNext))

        let stack = NSStackView(views: [prev, playPause, next])
        stack.orientation = .horizontal
        stack.alignment = .centerY
        stack.spacing = 4
        stack.edgeInsets = NSEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)

        let item = NSCustomTouchBarItem(identifier: controlsId)
        item.view = stack
        item.customizationLabel = "Playback Controls"
        return item
    }

    private func makeMediaButton(symbol: String, accessibility: String, action: Selector) -> NSButton {
        let image = NSImage(systemSymbolName: symbol, accessibilityDescription: accessibility) ?? NSImage()
        image.isTemplate = true

        let button = NSButton(image: image, target: self, action: action)
        button.bezelStyle = .texturedRounded
        button.imagePosition = .imageOnly
        button.imageScaling = .scaleProportionallyDown
        button.setAccessibilityLabel(accessibility)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.widthAnchor.constraint(equalToConstant: 56).isActive = true
        return button
    }

    private func currentPlayPauseSymbol() -> String {
        let isPaused = playbackEngine.currentTrack?.isPaused ?? true
        return isPaused ? "play.fill" : "pause.fill"
    }

    private func refreshPlayPauseIcon() {
        guard let button = playPauseButton else { return }
        let image = NSImage(systemSymbolName: currentPlayPauseSymbol(), accessibilityDescription: "Play or pause")
        image?.isTemplate = true
        button.image = image
    }

    @objc private func handlePlayPause() {
        playbackEngine.togglePlayPause()
    }

    @objc private func handleNext() {
        playbackEngine.nextTrack()
    }

    @objc private func handlePrevious() {
        playbackEngine.previousTrack()
    }

    private func bindLyricUpdates() {
        cancellables.removeAll()

        lyricsService.$currentLineIndex
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.refreshLabel() }
            .store(in: &cancellables)

        lyricsService.$lyricLines
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.refreshLabel() }
            .store(in: &cancellables)

        playbackEngine.$currentTrack
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.refreshLabel() }
            .store(in: &cancellables)
    }

    private func refreshLabel() {
        lyricLabel?.stringValue = currentText()
        refreshPlayPauseIcon()
    }

    private func currentText() -> String {
        let text: String
        if !lyricsService.lyricLines.isEmpty,
           let idx = lyricsService.currentLineIndex,
           idx >= 0, idx < lyricsService.lyricLines.count,
           !lyricsService.lyricLines[idx].text.isEmpty {
            text = lyricsService.lyricLines[idx].text
        } else if let track = playbackEngine.currentTrack {
            text = "\(track.title) — \(track.artist)"
        } else {
            text = "Verse Bar"
        }

        let maxChars = 80
        return text.count > maxChars
            ? String(text.prefix(maxChars - 1)) + "…"
            : text
    }
}

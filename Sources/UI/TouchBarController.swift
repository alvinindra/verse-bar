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

    private let lyricId = NSTouchBarItem.Identifier("com.versebar.popover.touchbar.lyric")
    private let iconId  = NSTouchBarItem.Identifier("com.versebar.popover.touchbar.icon")

    private weak var lyricLabel: NSTextField?

    private var playbackEngine = PlaybackEngine.shared
    private var lyricsService = LyricsService.shared
    private var cancellables = Set<AnyCancellable>()

    override func makeTouchBar() -> NSTouchBar? {
        let bar = NSTouchBar()
        bar.delegate = self
        bar.customizationIdentifier = NSTouchBar.CustomizationIdentifier("com.versebar.popover.touchbar")
        bar.defaultItemIdentifiers = [lyricId, .flexibleSpace, iconId]
        bar.customizationAllowedItemIdentifiers = [lyricId, iconId]
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
        case iconId:
            return makeIconItem()
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

    private func makeIconItem() -> NSTouchBarItem {
        let image = NSImage(systemSymbolName: "music.note", accessibilityDescription: "Verse Bar")
            ?? NSImage()
        image.isTemplate = true

        let imageView = NSImageView(image: image)
        imageView.contentTintColor = .systemBlue
        imageView.imageScaling = .scaleProportionallyDown
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.widthAnchor.constraint(equalToConstant: 24).isActive = true

        let item = NSCustomTouchBarItem(identifier: iconId)
        item.view = imageView
        item.customizationLabel = "Verse Bar Icon"
        return item
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

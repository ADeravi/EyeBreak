import Cocoa
import UserNotifications

private let breakSeconds = 20

final class OverlayWindow: NSWindow {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

final class OverlayView: NSView {
    var onDismiss: (() -> Void)?
    weak var countdownLabel: NSTextField?

    override var acceptsFirstResponder: Bool { true }

    override func mouseDown(with event: NSEvent) { onDismiss?() }
    override func keyDown(with event: NSEvent) { onDismiss?() }
    override func cancelOperation(_ sender: Any?) { onDismiss?() }
}

final class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    private var statusItem: NSStatusItem!
    private var menu: NSMenu!
    private var timer: Timer?
    private var titleItem: NSMenuItem!
    private var pauseItem: NSMenuItem!
    private var fullScreenItem: NSMenuItem!

    private var remaining: TimeInterval = 20 * 60
    private var paused = false
    private var intervalMinutes = 20
    private var fullScreenBreak = true

    private var overlayWindows: [NSWindow] = []
    private var overlayTimer: Timer?
    private var overlaySeconds = breakSeconds

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "eye", accessibilityDescription: "Eye Break")
            button.font = NSFont.monospacedDigitSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)
        }

        buildMenu()
        statusItem.menu = menu

        let center = UNUserNotificationCenter.current()
        center.delegate = self
        center.requestAuthorization(options: [.alert, .sound]) { _, _ in }

        startTimer()
        updateTitle()

        // Demonstration mode: trigger an immediate break.
        if CommandLine.arguments.contains("--demo") {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                self?.triggerBreak()
            }
        }
    }

    // MARK: - Timer

    private func startTimer() {
        timer?.invalidate()
        let t = Timer(timeInterval: 1.0, repeats: true) { [weak self] _ in self?.tick() }
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    private func tick() {
        guard !paused else { return }
        remaining -= 1
        if remaining <= 0 {
            triggerBreak()
            remaining = TimeInterval(intervalMinutes * 60)
        }
        updateTitle()
    }

    private func updateTitle() {
        let title: String
        if paused {
            title = "⏸"
        } else {
            let s = max(0, Int(remaining.rounded(.up)))
            title = String(format: "%02d:%02d", s / 60, s % 60)
        }
        statusItem.button?.title = title
        titleItem?.title = "Next reminder in " + (paused ? "— (paused)" : title)
    }

    // MARK: - Menu

    private func buildMenu() {
        menu = NSMenu()

        titleItem = NSMenuItem(title: "", action: nil, keyEquivalent: "")
        menu.addItem(titleItem)
        menu.addItem(NSMenuItem.separator())

        let intervalItem = NSMenuItem(title: "Interval", action: nil, keyEquivalent: "")
        let sub = NSMenu()
        for m in [15, 20, 25, 30, 45, 60] {
            let it = NSMenuItem(title: "\(m) minutes", action: #selector(changeInterval(_:)), keyEquivalent: "")
            it.target = self
            it.tag = m
            it.state = (m == intervalMinutes) ? .on : .off
            sub.addItem(it)
        }
        intervalItem.submenu = sub
        menu.addItem(intervalItem)

        fullScreenItem = NSMenuItem(title: "Full-screen break", action: #selector(toggleFullScreen(_:)), keyEquivalent: "")
        fullScreenItem.target = self
        fullScreenItem.state = fullScreenBreak ? .on : .off
        menu.addItem(fullScreenItem)

        pauseItem = NSMenuItem(title: "Pause", action: #selector(togglePause(_:)), keyEquivalent: "")
        pauseItem.target = self
        menu.addItem(pauseItem)

        let nowItem = NSMenuItem(title: "Look away now", action: #selector(lookAwayNow), keyEquivalent: "")
        nowItem.target = self
        menu.addItem(nowItem)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "Quit Eye Break", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        menu.addItem(quitItem)
    }

    @objc private func togglePause(_ sender: NSMenuItem) {
        paused.toggle()
        pauseItem.title = paused ? "Resume" : "Pause"
        updateTitle()
    }

    @objc private func toggleFullScreen(_ sender: NSMenuItem) {
        fullScreenBreak.toggle()
        fullScreenItem.state = fullScreenBreak ? .on : .off
    }

    @objc private func changeInterval(_ sender: NSMenuItem) {
        intervalMinutes = sender.tag
        remaining = TimeInterval(intervalMinutes * 60)
        for it in sender.menu?.items ?? [] { it.state = (it.tag == intervalMinutes) ? .on : .off }
        updateTitle()
    }

    @objc private func lookAwayNow() {
        triggerBreak()
    }

    // MARK: - Break

    private func triggerBreak() {
        sendNotification()
        if fullScreenBreak {
            showOverlay()
        }
    }

    private func sendNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Look away 👀"
        content.body = "20-20-20: focus on something about 6 metres away for 20 seconds."
        content.sound = .default
        if #available(macOS 12.0, *) {
            content.interruptionLevel = .timeSensitive
        }
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.5, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Full-screen overlay

    private func showOverlay() {
        guard overlayWindows.isEmpty else { return }

        for screen in NSScreen.screens {
            let frame = screen.frame
            let window = OverlayWindow(contentRect: frame, styleMask: [.borderless], backing: .buffered, defer: false)
            window.isOpaque = false
            window.backgroundColor = NSColor.black.withAlphaComponent(0.88)
            window.level = .screenSaver
            window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            window.hasShadow = false
            window.isReleasedWhenClosed = false

            let overlay = OverlayView(frame: NSRect(origin: .zero, size: frame.size))
            overlay.onDismiss = { [weak self] in self?.dismissOverlay() }

            let title = NSTextField(labelWithString: "Look away 👀")
            title.font = NSFont.systemFont(ofSize: 84, weight: .bold)
            title.textColor = .white
            title.alignment = .center
            title.translatesAutoresizingMaskIntoConstraints = false

            let subtitle = NSTextField(labelWithString: "Focus on something about 6 metres away")
            subtitle.font = NSFont.systemFont(ofSize: 34, weight: .medium)
            subtitle.textColor = NSColor(white: 0.88, alpha: 1)
            subtitle.alignment = .center
            subtitle.translatesAutoresizingMaskIntoConstraints = false

            let countdown = NSTextField(labelWithString: "\(breakSeconds)")
            countdown.font = NSFont.monospacedDigitSystemFont(ofSize: 150, weight: .bold)
            countdown.textColor = NSColor(calibratedRed: 0.4, green: 0.9, blue: 0.7, alpha: 1)
            countdown.alignment = .center
            countdown.translatesAutoresizingMaskIntoConstraints = false

            let hint = NSTextField(labelWithString: "Press any key, click, or wait for it to finish")
            hint.font = NSFont.systemFont(ofSize: 20)
            hint.textColor = NSColor(white: 0.55, alpha: 1)
            hint.alignment = .center
            hint.translatesAutoresizingMaskIntoConstraints = false

            overlay.countdownLabel = countdown
            overlay.addSubview(title)
            overlay.addSubview(subtitle)
            overlay.addSubview(countdown)
            overlay.addSubview(hint)

            NSLayoutConstraint.activate([
                title.centerXAnchor.constraint(equalTo: overlay.centerXAnchor),
                title.centerYAnchor.constraint(equalTo: overlay.centerYAnchor, constant: -70),
                subtitle.centerXAnchor.constraint(equalTo: overlay.centerXAnchor),
                subtitle.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 18),
                countdown.centerXAnchor.constraint(equalTo: overlay.centerXAnchor),
                countdown.topAnchor.constraint(equalTo: subtitle.bottomAnchor, constant: 50),
                hint.centerXAnchor.constraint(equalTo: overlay.centerXAnchor),
                hint.bottomAnchor.constraint(equalTo: overlay.bottomAnchor, constant: -90)
            ])

            window.contentView = overlay
            overlayWindows.append(window)
            window.makeKeyAndOrderFront(nil)
        }

        if let first = overlayWindows.first {
            first.makeFirstResponder(first.contentView)
        }
        NSApp.activate(ignoringOtherApps: true)

        overlaySeconds = breakSeconds
        updateOverlayCountdown()

        overlayTimer?.invalidate()
        let t = Timer(timeInterval: 1.0, repeats: true) { [weak self] _ in self?.overlayTick() }
        RunLoop.main.add(t, forMode: .common)
        overlayTimer = t
    }

    private func overlayTick() {
        overlaySeconds -= 1
        if overlaySeconds <= 0 {
            dismissOverlay()
        } else {
            updateOverlayCountdown()
        }
    }

    private func updateOverlayCountdown() {
        for window in overlayWindows {
            (window.contentView as? OverlayView)?.countdownLabel?.stringValue = "\(overlaySeconds)"
        }
    }

    private func dismissOverlay() {
        overlayTimer?.invalidate()
        overlayTimer = nil
        for window in overlayWindows {
            window.orderOut(nil)
        }
        overlayWindows.removeAll()
    }

    // MARK: - Notification delegate

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()

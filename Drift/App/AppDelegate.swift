import AppKit
import SwiftUI
import ServiceManagement

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var panel: DriftPanelWindow?
    private var engine = DriftTimeEngine()
    private var trayTimer: Timer?
    private var clickMonitor: Any?
    private var lastTrayText = ""

    // MARK: - Lifecycle

    func applicationDidFinishLaunching(_ notification: Notification) {
        DriftFonts.registerFonts()

        // Hide dock icon (LSUIElement handles this, but belt-and-suspenders)
        NSApp.setActivationPolicy(.accessory)

        setupStatusItem()
        updateTrayTitle()

        // Tick every second; the title is only reassigned when the text changes
        trayTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.updateTrayTitle()
        }
        RunLoop.main.add(trayTimer!, forMode: .common)
    }

    // MARK: - Status Item

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            button.action = #selector(statusItemClicked(_:))
            button.target = self
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
    }

    private func updateTrayTitle() {
        guard let button = statusItem.button else { return }
        let text = engine.menubarText
        guard text != lastTrayText else { return }
        lastTrayText = text
        let attributes: [NSAttributedString.Key: Any] = [
            .font: DriftFonts.jetbrainsRegularNS(12),
            .baselineOffset: 0.5
        ]
        button.attributedTitle = NSAttributedString(string: text, attributes: attributes)
    }

    // MARK: - Click Handling

    @objc private func statusItemClicked(_ sender: NSStatusBarButton) {
        // Accessibility presses arrive with no current event.
        if NSApp.currentEvent?.type == .rightMouseUp {
            showContextMenu()
        } else {
            togglePanel()
        }
    }

    // MARK: - Panel

    private func togglePanel() {
        if let panel, panel.isVisible {
            hidePanel()
        } else {
            showPanel()
        }
    }

    private func showPanel() {
        if panel == nil {
            let contentView = DriftPanelView(engine: engine)
            panel = DriftPanelWindow(contentView: contentView)
        }

        guard let panel, let button = statusItem.button,
              let buttonWindow = button.window else { return }

        // Position below the status item
        let buttonRect = buttonWindow.convertToScreen(button.convert(button.bounds, to: nil))
        let panelWidth = DriftPanelView.size.width
        let panelHeight = DriftPanelView.size.height
        let x = buttonRect.midX - panelWidth / 2
        let y = buttonRect.minY - panelHeight - 4

        panel.setFrame(NSRect(x: x, y: y, width: panelWidth, height: panelHeight), display: true)
        panel.alphaValue = 0
        panel.makeKeyAndOrderFront(nil)

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.25
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            panel.animator().alphaValue = 1
        }

        updateTrayTitle()
        installClickMonitor()
    }

    private func hidePanel() {
        guard let panel else { return }
        removeClickMonitor()

        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.2
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            panel.animator().alphaValue = 0
        }, completionHandler: {
            panel.orderOut(nil)
        })
    }

    // MARK: - Click Outside Monitor

    private func installClickMonitor() {
        clickMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            self?.hidePanel()
        }
    }

    private func removeClickMonitor() {
        if let monitor = clickMonitor {
            NSEvent.removeMonitor(monitor)
            clickMonitor = nil
        }
    }

    // MARK: - Context Menu

    private func showContextMenu() {
        let menu = NSMenu()

        let launchItem = NSMenuItem(title: "Launch at Login", action: #selector(toggleLaunchAtLogin(_:)), keyEquivalent: "")
        launchItem.target = self
        launchItem.state = isLaunchAtLoginEnabled ? .on : .off
        menu.addItem(launchItem)

        menu.addItem(.separator())

        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "2.0"
        let versionItem = NSMenuItem(title: "Drift v\(version)", action: nil, keyEquivalent: "")
        versionItem.isEnabled = false
        menu.addItem(versionItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        menu.addItem(quitItem)

        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        // Reset menu so left-click works again
        DispatchQueue.main.async { [weak self] in
            self?.statusItem.menu = nil
        }
    }

    // MARK: - Launch at Login

    private var isLaunchAtLoginEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    @objc private func toggleLaunchAtLogin(_ sender: NSMenuItem) {
        do {
            if isLaunchAtLoginEnabled {
                try SMAppService.mainApp.unregister()
            } else {
                try SMAppService.mainApp.register()
            }
        } catch {
            NSLog("Failed to toggle launch at login: \(error)")
        }
    }
}

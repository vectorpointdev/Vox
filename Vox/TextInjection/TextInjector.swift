import AppKit
import Carbon.HIToolbox

@MainActor
final class TextInjector {

    func inject(text: String) {
        // Small delay to ensure hotkey modifier keys are fully released
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            self.injectViaClipboard(text: text)
        }
    }

    // MARK: - Clipboard Injection (Primary)

    private func injectViaClipboard(text: String) {
        let pasteboard = NSPasteboard.general

        // Save current clipboard
        let previousString = pasteboard.string(forType: .string)

        // Set transcribed text
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)

        print("[Vox] Clipboard set to: '\(text)'")

        // Simulate Cmd+V to paste
        simulatePasteCGEvent()

        if !AXIsProcessTrusted() {
            print("[Vox] WARNING: Not AX trusted — paste may not work. Toggle Vox off/on in System Settings → Accessibility.")
        }

        // Restore previous clipboard after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            pasteboard.clearContents()
            if let prev = previousString {
                pasteboard.setString(prev, forType: .string)
            }
        }
    }

    // MARK: - Paste via CGEvent

    private func simulatePasteCGEvent() -> Bool {
        let source = CGEventSource(stateID: .combinedSessionState)

        guard let keyDown = CGEvent(keyboardEventSource: source, virtualKey: UInt16(kVK_ANSI_V), keyDown: true),
              let keyUp = CGEvent(keyboardEventSource: source, virtualKey: UInt16(kVK_ANSI_V), keyDown: false) else {
            print("[Vox] Failed to create CGEvent")
            return false
        }

        keyDown.flags = .maskCommand
        keyUp.flags = .maskCommand

        keyDown.post(tap: .cghidEventTap)
        keyUp.post(tap: .cghidEventTap)
        print("[Vox] CGEvent Cmd+V posted")
        return true
    }

    // MARK: - Paste via AppleScript (fallback)

    private func simulatePasteAppleScript() {
        let script = NSAppleScript(source: """
            tell application "System Events"
                keystroke "v" using command down
            end tell
            """)
        var error: NSDictionary?
        script?.executeAndReturnError(&error)
        if let error {
            print("[Vox] AppleScript paste error: \(error)")
        } else {
            print("[Vox] AppleScript paste succeeded")
        }
    }

    // MARK: - Permission Checks

    static func hasAccessibilityPermission() -> Bool {
        AXIsProcessTrusted()
    }

    static func requestAccessibilityPermission() {
        let promptKey = "AXTrustedCheckOptionPrompt" as CFString
        let options = [promptKey: kCFBooleanTrue!] as CFDictionary
        AXIsProcessTrustedWithOptions(options)
    }
}

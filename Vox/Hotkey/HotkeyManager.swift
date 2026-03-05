import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    static let holdToTalk = Self("holdToTalk", default: .init(.space, modifiers: .option))
}

@MainActor
final class HotkeyManager {
    var onRecordStart: (() -> Void)?
    var onRecordStop: (() -> Void)?

    init() {
        KeyboardShortcuts.onKeyDown(for: .holdToTalk) { [weak self] in
            self?.onRecordStart?()
        }
        KeyboardShortcuts.onKeyUp(for: .holdToTalk) { [weak self] in
            self?.onRecordStop?()
        }
    }
}

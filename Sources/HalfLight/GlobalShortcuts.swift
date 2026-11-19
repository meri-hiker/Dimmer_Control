import Carbon

@MainActor
final class GlobalShortcuts {
    private var handler: EventHandlerRef?
    private var references: [EventHotKeyRef] = []
    private var action: ((UInt32) -> Void)?

    func register(action: @escaping (UInt32) -> Void) -> Bool {
        self.action = action
        var event = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        let context = Unmanaged.passUnretained(self).toOpaque()
        let result = InstallEventHandler(GetApplicationEventTarget(), { _, event, context in
            guard let event, let context else { return OSStatus(eventNotHandledErr) }
            var identifier = EventHotKeyID()
            let status = GetEventParameter(event, EventParamName(kEventParamDirectObject),
                                          EventParamType(typeEventHotKeyID), nil,
                                          MemoryLayout<EventHotKeyID>.size, nil, &identifier)
            guard status == noErr else { return status }
            // Carbon application events run on the main event loop.
            MainActor.assumeIsolated {
                let shortcuts = Unmanaged<GlobalShortcuts>.fromOpaque(context).takeUnretainedValue()
                shortcuts.action?(identifier.id)
            }
            return noErr
        }, 1, &event, context, &handler)
        guard result == noErr else { return false }

        for (key, id) in [(kVK_ANSI_D, UInt32(1)), (kVK_ANSI_S, UInt32(2))] {
            var reference: EventHotKeyRef?
            let status = RegisterEventHotKey(UInt32(key), UInt32(controlKey | optionKey | cmdKey),
                                              EventHotKeyID(signature: 0x484C4754, id: id),
                                              GetApplicationEventTarget(), 0, &reference)
            guard status == noErr, let reference else {
                unregister()
                return false
            }
            references.append(reference)
        }
        return true
    }

    func unregister() {
        references.forEach { UnregisterEventHotKey($0) }
        references.removeAll()
        if let handler { RemoveEventHandler(handler) }
        handler = nil
        action = nil
    }
}

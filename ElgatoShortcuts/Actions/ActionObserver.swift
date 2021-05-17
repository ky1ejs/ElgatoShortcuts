//
//  ActionObserver.swift
//  ElgatoShortcuts
//
//  Created by Kyle McAlpine on 16/05/2021.
//

import Foundation

final class ActionObserver {
    typealias ActionFired = (Action) -> ()
    private let notificationCenter: DistributedNotificationCenter
    var handler: ActionFired?

    private static let commandMap: [String : Action.Command] = [
        "ElgatoShortcuts.ToggleOnOff" : .toggleOnOff,
        "ElgatoShortcuts.BrightnessUp" : .brightness(.up),
        "ElgatoShortcuts.BrightnessDown" : .brightness(.down),
        "ElgatoShortcuts.TemperatureUp" : .temperature(.up),
        "ElgatoShortcuts.TemperatureDown" : .temperature(.down),
    ]

    init(notificationCenter: DistributedNotificationCenter = .default()) {
        self.notificationCenter = notificationCenter

        for key in type(of: self).commandMap.keys {
            notificationCenter.addObserver(forName: NSNotification.Name(key), object: nil, queue: nil) { [weak self] notification in
                self?.handleRequest(with: notification.name.rawValue)
            }
        }
    }

    deinit {
        notificationCenter.removeObserver(self)
    }

    private func handleRequest(with name: String) {
        guard let command = type(of: self).commandMap[name] else {
            print("Unknown command: \(name)")
            return
        }

        handler?(Action(command: command))
    }
}

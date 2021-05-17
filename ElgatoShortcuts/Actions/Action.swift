//
//  Action.swift
//  ElgatoShortcuts
//
//  Created by Kyle McAlpine on 16/05/2021.
//

import Foundation

struct Action: Hashable {
    let command: Command
    let initiatedAt = Date()

    enum Command: Hashable {
        case toggleOnOff, brightness(Direction), temperature(Direction)

        enum Direction {
            case up, down
        }

        func hash(into hasher: inout Hasher) {
            switch self {
            case .toggleOnOff:
                hasher.combine("toggleOnOff")
            case .brightness:
                hasher.combine("brightness")
            case .temperature:
                hasher.combine("temperature")
            }
        }
    }

    func hash(into hasher: inout Hasher) {
        command.hash(into: &hasher)
    }

    static func == (lhs: Action, rhs: Action) -> Bool {
        lhs.hashValue == rhs.hashValue
    }
}

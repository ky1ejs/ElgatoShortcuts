//
//  LightConfigUpdateBuilder.swift
//  ElgatoShortcuts
//
//  Created by Kyle McAlpine on 17/05/2021.
//

import Foundation

struct LightConfigUpdateBuilder {
    private static let brightnessInterval = 5
    private static let temperatureInterval = 10

    func updateConfigRequest(currentConfig: LightConfig, action: Action) -> LightConfigUpdate {
        switch action.command {
        case .toggleOnOff:
            return LightConfigUpdate(isOn: !currentConfig.isOn, brightness: nil, temperature: nil)
        case let .brightness(direction):
            let brightness = direction.operation(currentConfig.brightness, type(of: self).brightnessInterval)
            return LightConfigUpdate(isOn: nil, brightness: brightness, temperature: nil)
        case let .temperature(direction):
            let temperature = direction.operation(currentConfig.temperature, type(of: self).temperatureInterval)
            return LightConfigUpdate(isOn: nil, brightness: nil, temperature: temperature)
        }
    }
}

private extension Action.Command.Direction {
    var operation: (Int, Int) -> Int {
        switch self {
        case .down:
            return (-)
        case .up:
            return (+)
        }
    }
}

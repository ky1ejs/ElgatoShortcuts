//
//  LightConfigUpdate.swift
//  ElgatoShortcuts
//
//  Created by Kyle McAlpine on 17/05/2021.
//

import Foundation

struct LightConfigUpdate {
    private static let maxBrightness = 100
    private static let minBrightness = 3
    private static let maxTemperature = 344
    private static let minTemperature = 143

    let isOn: Bool?
    let brightness: Int?
    let temperature: Int?

    init(isOn: Bool?, brightness: Int?, temperature: Int?) {
        self.isOn = isOn
        let selfType = type(of: self)
        self.brightness = brightness?.between(min: selfType.minBrightness, max: selfType.maxBrightness)
        self.temperature = temperature?.between(min: selfType.minTemperature, max: selfType.maxTemperature)
    }
}

extension LightConfigUpdate: Encodable {
    enum CodingKeys: String, CodingKey {
        case lights
        case brightness
        case on
        case numberOfLights
        case temperature
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        var lights = container.nestedUnkeyedContainer(forKey: .lights)
        var lightObject = lights.nestedContainer(keyedBy: CodingKeys.self)

        if let isOn = isOn {
            try lightObject.encode(isOn ? 1 : 0, forKey: .on)
        }

        if let brightness = brightness {
            try lightObject.encode(brightness, forKey: .brightness)
        }

        if let temperature = temperature {
            try lightObject.encode(temperature, forKey: .temperature)
        }

        try container.encode(0, forKey: .numberOfLights)
    }
}

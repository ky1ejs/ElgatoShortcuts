//
//  LightConfig.swift
//  ElgatoShortcuts
//
//  Created by Kyle McAlpine on 17/05/2021.
//

import Foundation

struct LightConfig {
    let isOn: Bool
    let brightness: Int
    let temperature: Int
}

extension LightConfig: Decodable {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: LightConfigCodingKeys.self)
        var lights = try container.nestedUnkeyedContainer(forKey: .lights)
        let lightsObject = try lights.nestedContainer(keyedBy: LightConfigCodingKeys.self)

        isOn = try lightsObject.decode(Int.self, forKey: .on) >= 1
        brightness = try lightsObject.decode(Int.self, forKey: .brightness)
        temperature = try lightsObject.decode(Int.self, forKey: .temperature)
    }
}

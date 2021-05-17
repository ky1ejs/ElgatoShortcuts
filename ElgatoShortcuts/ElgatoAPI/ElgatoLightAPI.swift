//
//  UpdateLightConfigEndpoint.swift
//  ElgatoShortcuts
//
//  Created by Kyle McAlpine on 17/05/2021.
//

import Foundation

private var endpoint: URL { URL(string: "http://192.168.1.6:9123/elgato/lights")! }

struct GetLightConfigEndpoint: Endpoint {
    typealias SuccessData = LightConfig
    typealias D = JSONDeserializer<SuccessData>

    typealias Payload = EmptyPayload
    typealias S = JSONSerializer<Payload>

    var url: URL { endpoint }
    var method: HTTPMethod { .get }
}

struct UpdateLightConfigEndpoint: Endpoint {
    typealias SuccessData = LightConfig
    typealias D = JSONDeserializer<SuccessData>

    typealias Payload = LightConfigUpdate
    typealias S = JSONSerializer<Payload>

    var url: URL { endpoint }
    var method: HTTPMethod { .put }
}

//
//  RequestBuilder.swift
//  ElgatoShortcuts
//
//  Created by Kyle McAlpine on 16/05/2021.
//

import Foundation

struct RequestBuilder {
    func build<E: Endpoint>(_ endpoint: E, payload: E.Payload) throws -> URLRequest {
        var request = URLRequest(url: endpoint.url)
        request.httpMethod = endpoint.method.rawValue
        try E.S.serialize(entity: payload, inTo: &request)
        return request
    }
}

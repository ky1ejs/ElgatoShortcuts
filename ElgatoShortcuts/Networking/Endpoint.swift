//
//  Endpoint.swift
//  ElgatoShortcuts
//
//  Created by Kyle McAlpine on 17/05/2021.
//

import Foundation

protocol Endpoint {
    associatedtype SuccessData
    associatedtype D: Deserializer where D.T == SuccessData

    associatedtype Payload
    associatedtype S: Serializer where S.T == Payload

    var url: URL { get }
    var method: HTTPMethod { get }
}

protocol Serializer {
    associatedtype T
    static func serialize(entity: T, inTo request: inout URLRequest) throws
}

protocol Deserializer {
    associatedtype T
    static func desrialize(with data: Data?, and response: URLResponse?) throws -> T
}

enum HTTPMethod: String {
    case delete = "DELETE"
    case get = "GET"
    case post = "POST"
    case put = "PUT"
}

// TODO: can do better than this, fix
struct EmptyPayload: Encodable {
}

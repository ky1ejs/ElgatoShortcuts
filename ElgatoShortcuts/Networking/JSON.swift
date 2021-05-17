//
//  JSON.swift
//  ElgatoShortcuts
//
//  Created by Kyle McAlpine on 17/05/2021.
//

import Foundation

struct JSONSerializer<TT: Encodable>: Serializer {
    typealias T = TT
    static func serialize(entity: TT, inTo request: inout URLRequest) throws {
        request.addValue("accept", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(entity)
    }
}

enum JSONDeserializeError: Error {
    case invalid
}
struct JSONDeserializer<TT: Decodable>: Deserializer {
    typealias T = TT
    static func desrialize(with data: Data?, and response: URLResponse?) throws -> T {
        guard let data = data, let response = response as? HTTPURLResponse, response.statusCode == 200 else {
            throw JSONDeserializeError.invalid
        }
        return try JSONDecoder().decode(T.self, from: data)
    }
}

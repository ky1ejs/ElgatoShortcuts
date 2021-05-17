//
//  NetworkClient.swift
//  ElgatoShortcuts
//
//  Created by Kyle McAlpine on 16/05/2021.
//

import Foundation

enum NetworkClientError: Error {
    case requestError(Error)
    case somethingWentWrong
    case parsingError(Error)
}

struct NetworkClient {
    private let requestBuilder = RequestBuilder()

    func call<E: Endpoint>(_ endpoint: E, payload: E.Payload, completion: @escaping (Result<E.SuccessData, NetworkClientError>) -> ()) {
        do {
            let request = try requestBuilder.build(endpoint, payload: payload)
            let task = URLSession(configuration: .default).dataTask(with: request) { data, response, error in
                print(data as Any)
                print(response as Any)
                print(error as Any)
                do {
                    let entity = try E.D.desrialize(with: data, and: response)
                    completion(.success(entity))
                } catch {
                    completion(.failure(.parsingError(error)))
                }
            }
            task.resume()
        } catch {
            completion(.failure(.requestError(error)))
        }
    }
}


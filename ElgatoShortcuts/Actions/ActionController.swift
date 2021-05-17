//
//  ActionController.swift
//  ElgatoShortcuts
//
//  Created by Kyle McAlpine on 17/05/2021.
//

import Foundation
import OrderedCollections

class ActionController {
    private let client: NetworkClient
    private let updateBuilder = LightConfigUpdateBuilder()

    private var queue = OrderedSet<Action>()
    private var latestConfig: LightConfig?
    private var actionInFlight: Action?

    init(client: NetworkClient = .init()) {
        self.client = client
    }

    func execute(_ action: Action) {
        _ = queue.updateOrAppend(action)
        run()
    }

    private func run() {
        print(queue.count)
        print(latestConfig?.isOn as Any)
        print(latestConfig?.temperature as Any)
        print(latestConfig?.brightness as Any)
        print("---------")
        guard actionInFlight == nil, let action = queue.first else {
            return
        }

        actionInFlight = action
        _ = queue.removeFirst()

        let completionHandler: (Result<LightConfig, NetworkClientError>) -> () = { [weak self] result in
            switch result {
            case let .success(config):
                self?.latestConfig = config
            case .failure:
                print("Request failed: \(result)")
            }
            self?.actionInFlight = nil
            self?.run()
        }

        guard let latestConfig = latestConfig else {
            client.call(GetLightConfigEndpoint(), payload: EmptyPayload(), completion: completionHandler)
            return
        }
        let updateConfig = updateBuilder.updateConfigRequest(currentConfig: latestConfig, action: action)
        client.call(UpdateLightConfigEndpoint(), payload: updateConfig, completion: completionHandler)
    }
}

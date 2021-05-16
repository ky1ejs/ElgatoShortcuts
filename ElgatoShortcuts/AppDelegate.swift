//
//  AppDelegate.swift
//  ElgatoShortcuts
//
//  Created by Kyle McAlpine on 15/05/2021.
//
import Cocoa
import SwiftUI

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    var popover: NSPopover!
    var statusBarItem: NSStatusItem!

    private let ro = RequestObserver()

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Create the SwiftUI view that provides the window contents.
        let contentView = ContentView()

        // Create the popover
        let popover = NSPopover()
        popover.contentSize = NSSize(width: 400, height: 500)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: contentView)
        self.popover = popover

        // Create the status item
        self.statusBarItem = NSStatusBar.system.statusItem(withLength: CGFloat(NSStatusItem.variableLength))

        if let button = self.statusBarItem.button {
            button.image = NSImage(named: "Icon")
            button.action = #selector(togglePopover(_:))
        }

        let nf = DistributedNotificationCenter.default()
        nf.addObserver(forName: NSNotification.Name("SUPERDUPERSHIT"), object: nil, queue: nil) { _ in
            print("Well that was fucking simple.")
        }
    }

    @objc func togglePopover(_ sender: AnyObject?) {
        if let button = self.statusBarItem.button {
            if self.popover.isShown {
                self.popover.performClose(sender)
            } else {
                self.popover.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
            }
        }
    }
}

final class RequestObserver {
    private let nf: DistributedNotificationCenter
    private let requestManager: RequestManager

    private static let commandMap: [String : NotificationRequest.Command] = [
        "ElgatoShortcuts.ToggleOnOff" : .toggleOnOff,
        "ElgatoShortcuts.BrightnessUp" : .brightness(.up),
        "ElgatoShortcuts.BrightnessDown" : .brightness(.down),
        "ElgatoShortcuts.TemperatureUp" : .temperature(.up),
        "ElgatoShortcuts.TemperatureDown" : .temperature(.down),
    ]

    init(nf: DistributedNotificationCenter = .default(), requestManager: RequestManager = .init()) {
        self.nf = nf
        self.requestManager = requestManager

        for key in type(of: self).commandMap.keys {
            nf.addObserver(forName: NSNotification.Name(key), object: nil, queue: nil) { [weak self] notification in
                self?.handleRequest(with: notification.name.rawValue)
            }
        }
    }

    deinit {
        nf.removeObserver(self)
    }

    private func handleRequest(with name: String) {
        guard let command = type(of: self).commandMap[name] else {
            print("Unknown command: \(name)")
            return
        }

        requestManager.execute(NotificationRequest(command: command))
    }
}

import OrderedCollections

class RequestManager {
    private let client: RequestClient
    private var queue = OrderedSet<NotificationRequest>()
    private var latestConfig: LightConfig?
    private var requestInFlight: NotificationRequest?

    init(client: RequestClient = .init()) {
        self.client = client
    }

    func execute(_ request: NotificationRequest) {
        _ = queue.updateOrAppend(request)
        run()
    }

    private func run() {
        print(queue.count)
        print(latestConfig?.isOn as Any)
        print(latestConfig?.temperature as Any)
        print(latestConfig?.brightness as Any)
        print("---------")
        guard requestInFlight == nil, let request = queue.first else {
            return
        }

        requestInFlight = request
        _ = queue.removeFirst()

        let completionHandler: (Result<LightConfig, RequestClient.NetworkingError>) -> () = { [weak self] result in
            switch result {
            case let .success(config):
                self?.latestConfig = config
            case .failure:
                print("Request failed: \(result)")
            }
            self?.requestInFlight = nil
            self?.run()
        }

        guard let latestConfig = latestConfig else {
            client.getConfig(completion: completionHandler)
            return
        }
        let updateConfig = request.buildUpdate(currentConfig: latestConfig)
        client.update(with: updateConfig, completion: completionHandler)
    }
}

struct RequestClient {
    private static let endpoint = URL(string: "http://192.168.1.6:9123/elgato/lights")!

    enum NetworkingError: Error {
        case somethingWentWrong
        case parsingError(Error)
    }

    func getConfig(completion: @escaping (Result<LightConfig, NetworkingError>) -> ()) {
        var request = URLRequest(url: type(of: self).endpoint)
        request.httpMethod = "GET"
        let task = URLSession(configuration: .default).dataTask(with: request) { d, r, e in
            guard let data = d, let response = r as? HTTPURLResponse, response.statusCode == 200, e == nil else {
                print(e as Any)
                print(r as Any)
                print(d as Any)
                completion(.failure(.somethingWentWrong))
                return
            }

            do {
                let config = try JSONDecoder().decode(LightConfig.self, from: data)
                completion(.success(config))
            } catch {
                completion(.failure(.parsingError(error)))
            }
        }
        task.resume()
    }

    func update(with config: LightConfigUpdate, completion: @escaping (Result<LightConfig, NetworkingError>) -> ()) {
        var request = URLRequest(url: type(of: self).endpoint)
        request.httpMethod = "PUT"
        request.httpBody = try! JSONEncoder().encode(config)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let task = URLSession(configuration: .default).dataTask(with: request) { d, r, e in
            guard let data = d, let response = r as? HTTPURLResponse, response.statusCode == 200, e == nil else {
                print(e as Any)
                print(r as Any)
                print(d as Any)
                completion(.failure(.somethingWentWrong))
                return
            }
            do {
                let config = try JSONDecoder().decode(LightConfig.self, from: data)
                completion(.success(config))
            } catch {
                completion(.failure(.somethingWentWrong))
            }
        }
        task.resume()
    }
}

struct NotificationRequest: Hashable {
    let command: Command
    let date = Date()

    private static let brightnessInterval = 5
    private static let temperatureInterval = 10

    enum Command: Hashable {
        case toggleOnOff, brightness(Direction), temperature(Direction)

        enum Direction {
            case up, down

            var operation: (Int, Int) -> Int {
                switch self {
                case .down:
                    return (-)
                case .up:
                    return (+)
                }
            }
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

    func buildUpdate(currentConfig: LightConfig) -> LightConfigUpdate {
        switch command {
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

    func hash(into hasher: inout Hasher) {
        command.hash(into: &hasher)
    }

    static func == (lhs: NotificationRequest, rhs: NotificationRequest) -> Bool {
        lhs.hashValue == rhs.hashValue
    }
}



enum LightConfigCodingKeys: String, CodingKey {
    case lights
    case brightness
    case on
    case numberOfLights
    case temperature
}

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

extension Int {
    func between(min: Int, max: Int) -> Int {
        Swift.max(Swift.min(self, max), min)
    }
}

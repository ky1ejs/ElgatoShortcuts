//
//  ElgatoShortcutsTests.swift
//  ElgatoShortcutsTests
//
//  Created by Kyle McAlpine on 16/05/2021.
//

import XCTest

@testable import ElgatoShortcuts

class ElgatoShortcutsTests: XCTestCase {
    func testParseConfig() throws {
        let config: LightConfig = try decoderFromJsonFile(named: "LightConfig")
        XCTAssertEqual(config.isOn, true)
        XCTAssertEqual(config.brightness, 100)
        XCTAssertEqual(config.temperature, 230)
    }

    func testSerialiseUpdateConfig_givenIsOn_onlyIsOnIsPresent() throws {
        let update = LightConfigUpdate(isOn: true, brightness: nil, temperature: nil)
        let json = try update.encodeToString()
        let expected = try stringFromJsonFile(named: "IsOnUpdate")
        XCTAssertEqual(json, expected)
    }

    func testSerialiseUpdateConfig_givenBrigtness_onlyBrightnessIsPresent() throws {
        let update = LightConfigUpdate(isOn: nil, brightness: 100, temperature: nil)
        let json = try update.encodeToString()
        let expected = try stringFromJsonFile(named: "BrightnessUpdate")
        XCTAssertEqual(json, expected)
    }

    func testSerialiseUpdateConfig_givenTemperature_onlyTemperatureIsPresent() throws {
        let update = LightConfigUpdate(isOn: nil, brightness: nil, temperature: 200)
        let json = try update.encodeToString()
        let expected = try stringFromJsonFile(named: "TemperatureUpdate")
        XCTAssertEqual(json, expected)
    }

    func testActionHashing() {
        let a = Action(command: .brightness(.up))
        let b = Action(command: .brightness(.down))
        XCTAssertEqual(a.hashValue, b.hashValue)
    }

    func testActionEquality() {
        let a = Action(command: .brightness(.up))
        let b = Action(command: .brightness(.down))
        XCTAssertEqual(a, b)
    }
}

extension ElgatoShortcutsTests {
    func dataFromJsonFile(named name: String) throws -> Data {
        let bundle = Bundle(for: type(of: self))
        let url = bundle.url(forResource: name, withExtension: "json")!
        return try Data(contentsOf: url)
    }

    func decoderFromJsonFile<T: Decodable>(named name: String) throws -> T {
        let data = try dataFromJsonFile(named: name)
        return try JSONDecoder().decode(T.self, from: data)
    }

    func stringFromJsonFile(named name: String) throws -> String {
        let data = try dataFromJsonFile(named: name)
        return String(data: data, encoding: .utf8)!.trimmingCharacters(in: .newlines)
    }
}

extension Encodable {
    func encodeToString() throws -> String {
        let data = try JSONEncoder().encode(self)
        return String(data: data, encoding: .utf8)!
    }
}

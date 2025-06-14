//
//  SettingsModel.swift
//  hopas
//
//  Created by Connor Link on 6/10/25.
//

import SwiftUI
import Combine

class SettingsModel: ObservableObject, Codable {
    public static var DEFAULT_IPADDRESS = "192.168.1.21";
    public static var DEFAULT_PORT: UInt16 = 49000;
    
    private static var DEFAULT_REVERSETHRUST_DATAREF = "sim/engines/thrust_reverse_toggle"
    private static var DEFAULT_BRAKES_DATAREF = "sim/cockpit2/controls/wheel_brake_ratio"
    private static var DEFAULT_GEAR_DATAREF = "sim/cockpit2/controls/gear_handle_down"
    private static var DEFAULT_AUTOTHROTTLE_DATAREF = "sim/cockpit2/autopilot/autothrottle_enabled"
    private static var DEFAULT_AUTOPILOT_COMMAND = "sim/autopilot/servos_toggle"
    private static var DEFAULT_SPEEDBRAKES_DATAREF = "sim/cockpit2/controls/speedbrake_ratio"
    private static var DEFAULT_FLAPS_DATAREF = "sim/cockpit2/controls/flap_ratio"
    private static var DEFAULT_TRIM_DATAREF = "sim/cockpit2/controls/elevator_trim"
    
    @Published var isYawControlEnabled: Bool = true
    @Published var isPitchControlInverted: Bool = true
    @Published var isRollControlInverted: Bool = false
    @Published var isYawControlInverted: Bool = false

    @Published var ipAddress: String = "192.168.1.19"
    @Published var port: String = "49000"
    @Published var transmitRate: Int = 10

    @Published var maxRollOrientation: Int = 90
    @Published var maxYawOrientation: Int = 90
    @Published var maxPitchOrientation: Int = 90

    @Published var showReverseThrust: Bool = true
    @Published var showBrakes: Bool = true
    @Published var showGear: Bool = true
    @Published var showAutothrottle: Bool = true
    @Published var showAutopilot: Bool = true
    @Published var showFlaps: Bool = true
    @Published var showSpeedbrakes: Bool = true
    @Published var showThrottle: Bool = true
    @Published var showControls: Bool = true
    @Published var showTrim: Bool = true
    
    @Published var reverseThrustDataref = DEFAULT_REVERSETHRUST_DATAREF
    @Published var brakesDataref = DEFAULT_BRAKES_DATAREF
    @Published var gearDataref = DEFAULT_GEAR_DATAREF
    @Published var autothrottleDataref = DEFAULT_AUTOTHROTTLE_DATAREF
    @Published var autopilotCommand = DEFAULT_AUTOPILOT_COMMAND
    @Published var speedbrakesDataref = DEFAULT_SPEEDBRAKES_DATAREF
    @Published var flapsDataref = DEFAULT_FLAPS_DATAREF
    @Published var trimDataref = DEFAULT_TRIM_DATAREF
    // default to the standard A3xx flap configuration
    @Published var numberOfFlapsNotches: Int = 4
    
    enum CodingKeys: String, CodingKey {
        case isYawControlEnabled, isPitchControlInverted, isRollControlInverted, isYawControlInverted
        case ipAddress, port, transmitRate
        case maxRollOrientation, maxYawOrientation, maxPitchOrientation
        case showReverseThrust, showBrakes, showGear, showAutothrottle, showAutopilot, showFlaps, showSpeedbrakes, showThrottle, showControls, showTrim
        case numberOfFlapsNotches
        case reverseThrustDataref, brakesDataref, gearDataref, autothrottleDataref, autopilotCommand, speedbrakesDataref, flapsDataref, trimDataref
    }

    init() {
        // default values pre-populated
    }
    
    // MARK: - Codable
    required init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        isYawControlEnabled = try c.decode(Bool.self, forKey: .isYawControlEnabled)
        isPitchControlInverted = try c.decode(Bool.self, forKey: .isPitchControlInverted)
        isRollControlInverted = try c.decode(Bool.self, forKey: .isRollControlInverted)
        isYawControlInverted = try c.decode(Bool.self, forKey: .isYawControlInverted)
        ipAddress = try c.decode(String.self, forKey: .ipAddress)
        port = try c.decode(String.self, forKey: .port)
        transmitRate = try c.decode(Int.self, forKey: .transmitRate)
        maxRollOrientation = try c.decode(Int.self, forKey: .maxRollOrientation)
        maxYawOrientation = try c.decode(Int.self, forKey: .maxYawOrientation)
        maxPitchOrientation = try c.decode(Int.self, forKey: .maxPitchOrientation)
        showReverseThrust = try c.decode(Bool.self, forKey: .showReverseThrust)
        showBrakes = try c.decode(Bool.self, forKey: .showBrakes)
        showGear = try c.decode(Bool.self, forKey: .showGear)
        showAutothrottle = try c.decode(Bool.self, forKey: .showAutothrottle)
        showAutopilot = try c.decode(Bool.self, forKey: .showAutopilot)
        showFlaps = try c.decode(Bool.self, forKey: .showFlaps)
        showSpeedbrakes = try c.decode(Bool.self, forKey: .showSpeedbrakes)
        showThrottle = try c.decode(Bool.self, forKey: .showThrottle)
        showControls = try c.decode(Bool.self, forKey: .showControls)
        showTrim = try c.decode(Bool.self, forKey: .showTrim)
        numberOfFlapsNotches = try c.decode(Int.self, forKey: .numberOfFlapsNotches)
        reverseThrustDataref = try c.decode(String.self, forKey: .reverseThrustDataref)
        brakesDataref = try c.decode(String.self, forKey: .brakesDataref)
        gearDataref = try c.decode(String.self, forKey: .gearDataref)
        autothrottleDataref = try c.decode(String.self, forKey: .autothrottleDataref)
        autopilotCommand = try c.decode(String.self, forKey: .autopilotCommand)
        speedbrakesDataref = try c.decode(String.self, forKey: .speedbrakesDataref)
        flapsDataref = try c.decode(String.self, forKey: .flapsDataref)
        trimDataref = try c.decode(String.self, forKey: .trimDataref)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(isYawControlEnabled, forKey: .isYawControlEnabled)
        try c.encode(isPitchControlInverted, forKey: .isPitchControlInverted)
        try c.encode(isRollControlInverted, forKey: .isRollControlInverted)
        try c.encode(isYawControlInverted, forKey: .isYawControlInverted)
        try c.encode(ipAddress, forKey: .ipAddress)
        try c.encode(port, forKey: .port)
        try c.encode(transmitRate, forKey: .transmitRate)
        try c.encode(maxRollOrientation, forKey: .maxRollOrientation)
        try c.encode(maxYawOrientation, forKey: .maxYawOrientation)
        try c.encode(maxPitchOrientation, forKey: .maxPitchOrientation)
        try c.encode(showReverseThrust, forKey: .showReverseThrust)
        try c.encode(showBrakes, forKey: .showBrakes)
        try c.encode(showGear, forKey: .showGear)
        try c.encode(showAutothrottle, forKey: .showAutothrottle)
        try c.encode(showAutopilot, forKey: .showAutopilot)
        try c.encode(showFlaps, forKey: .showFlaps)
        try c.encode(showSpeedbrakes, forKey: .showSpeedbrakes)
        try c.encode(showThrottle, forKey: .showThrottle)
        try c.encode(showControls, forKey: .showControls)
        try c.encode(showTrim, forKey: .showTrim)
        try c.encode(numberOfFlapsNotches, forKey: .numberOfFlapsNotches)
        try c.encode(reverseThrustDataref, forKey: .reverseThrustDataref)
        try c.encode(brakesDataref, forKey: .brakesDataref)
        try c.encode(gearDataref, forKey: .gearDataref)
        try c.encode(autothrottleDataref, forKey: .autothrottleDataref)
        try c.encode(autopilotCommand, forKey: .autopilotCommand)
        try c.encode(speedbrakesDataref, forKey: .speedbrakesDataref)
        try c.encode(flapsDataref, forKey: .flapsDataref)
        try c.encode(trimDataref, forKey: .trimDataref)
    }

    // MARK: - Persistence
    static let fileName = "SettingsModel.plist"

    func save() {
        let encoder = PropertyListEncoder()
        do {
            let data = try encoder.encode(self)
            let url = Self.fileURL()
            try data.write(to: url)
        } catch {
            print("Failed to save settings: \(error)")
        }
    }

    func load() {
        let url = Self.fileURL()
        guard let data = try? Data(contentsOf: url) else { return }
        
        let decoder = PropertyListDecoder()
        
        do {
            let loaded = try decoder.decode(SettingsModel.self, from: data)
            self.copy(from: loaded)
        } catch {
            print("Failed to load settings: \(error)")
        }
    }

    private func copy(from other: SettingsModel) {
        isYawControlEnabled = other.isYawControlEnabled
        isPitchControlInverted = other.isPitchControlInverted
        isRollControlInverted = other.isRollControlInverted
        isYawControlInverted = other.isYawControlInverted
        ipAddress = other.ipAddress
        port = other.port
        transmitRate = other.transmitRate
        maxRollOrientation = other.maxRollOrientation
        maxYawOrientation = other.maxYawOrientation
        maxPitchOrientation = other.maxPitchOrientation
        showReverseThrust = other.showReverseThrust
        showBrakes = other.showBrakes
        showGear = other.showGear
        showAutothrottle = other.showAutothrottle
        showAutopilot = other.showAutopilot
        showFlaps = other.showFlaps
        showSpeedbrakes = other.showSpeedbrakes
        showThrottle = other.showThrottle
        showControls = other.showControls
        showTrim = other.showTrim
        numberOfFlapsNotches = other.numberOfFlapsNotches
        reverseThrustDataref = other.reverseThrustDataref
        brakesDataref = other.brakesDataref
        gearDataref = other.gearDataref
        autothrottleDataref = other.autothrottleDataref
        autopilotCommand = other.autopilotCommand
        speedbrakesDataref = other.speedbrakesDataref
        flapsDataref = other.flapsDataref
        trimDataref = other.trimDataref
    }

    private static func fileURL() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(fileName)
    }
}

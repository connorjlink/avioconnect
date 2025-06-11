//
//  XPlaneUDPClient.swift
//  hopas
//
//  Created by Connor Link on 5/15/25.
//

import Network
import Foundation

class XPlaneUDPClient: ObservableObject {
    private var connection: NWConnection?
    private let queue = DispatchQueue(label: "xplane.udp")
    private var timer: DispatchSourceTimer?
    private var lastPing: Date = Date.distantPast
    
    private static var DEFAULT_REVERSETHRUST_DATAREF = "sim/flightmodel/controls/reverser_ratio"
    private static var DEFAULT_BRAKES_DATAREF = "sim/cockpit2/controls/wheel_brake_ratio"
    private static var DEFAULT_GEAR_DATAREF = "sim/cockpit2/controls/gear_handle_down"
    private static var DEFAULT_AUTOTHROTTLE_DATAREF = "sim/cockpit2/autopilot/autothrottle_enabled"
    private static var DEFAULT_AUTOPILOT_COMMAND = "sim/autopilot/servos_toggle" //"sim/cockpit2/autopilot/servos_enabled"
    
    private static var DEFAULT_SPEEDBRAKES_DATAREF = "sim/cockpit2/controls/speedbrake_ratio"
    private static var DEFAULT_FLAPS_DATAREF = "sim/cockpit2/controls/flap_ratio"
    
    @Published var reverseThrustDataref = DEFAULT_REVERSETHRUST_DATAREF
    @Published var brakesDataref = DEFAULT_BRAKES_DATAREF
    @Published var gearDataref = DEFAULT_GEAR_DATAREF
    @Published var autothrottleDataref = DEFAULT_AUTOTHROTTLE_DATAREF
    @Published var autopilotCommand = DEFAULT_AUTOPILOT_COMMAND
    @Published var speedbrakesDataref = DEFAULT_SPEEDBRAKES_DATAREF
    @Published var flapsDataref = DEFAULT_FLAPS_DATAREF
    
    
    @Published var isConnected: Bool = false
    
    init(host: String, port: UInt16 = 49000) {
        create(host: host, port: port)
    }

    deinit {
        cleanup()
    }
    
    func create(host: String, port: UInt16 = 49000) {
        cleanup()
        
        let endpoint = NWEndpoint.Host(host)
        let nwPort = NWEndpoint.Port(rawValue: port)!

        connection = NWConnection(host: endpoint, port: nwPort, using: .udp)
        connection?.start(queue: queue)

        startReceiving()
        startConnectionMonitor()
    }
    
    func cleanup() {
        connection?.cancel()
        connection = nil
        timer?.cancel()
        timer = nil
    }
    
    private func sendDATA(index: Int32, values: [Float]) {
        var packet = Data()
        packet.append(contentsOf: "DATA\0".utf8)
        
        var indexCopy = index
        packet.append(Data(bytes: &indexCopy, count: 4))
        
        // data packet should always contain eight numbers
        let paddedValues = values + Array(repeating: Float(0), count: max(0, 8 - values.count))
        for var v in paddedValues.prefix(8) {
            packet.append(Data(bytes: &v, count: 4))
        }
        
        connection?.send(content: packet, completion: .contentProcessed { _ in })
    }
    
    private func sendDREF(value: Float, for dataref: String) {
        var packet = Data()
        packet.append(contentsOf: "DREF0".utf8) // 5 bytes
        
        var val = value
        packet.append(Data(bytes: &val, count: 4)) // 4 bytes
        
        var drefNameData = (dataref + "\0").data(using: .utf8) ?? Data()
        if drefNameData.count > 500 {
            drefNameData = drefNameData.prefix(500)
        }
        packet.append(drefNameData)
        
        if packet.count < 509 {
            packet.append(Data(repeating: 0, count: 509 - packet.count))
        }

        connection?.send(content: packet, completion: .contentProcessed { _ in })
    }
    
    private func sendCMND(of command: String) {
        var packet = Data()
        packet.append(contentsOf: "CMND\0".utf8)
        
        if let cmdData = (command + "\0").data(using: .utf8) {
            packet.append(cmdData)
        }
        
        connection?.send(content: packet, completion: .contentProcessed { _ in })
    }

    func sendControls(pitch: Float, roll: Float, yaw: Float) {
        var packet = Data()
        packet.append(contentsOf: "DATA\0".utf8)

        var index: Int32 = 8
        packet.append(Data(bytes: &index, count: 4))

        let values = [pitch, roll, yaw] + Array(repeating: Float(0), count: 5)
        for value in values {
            var v = value
            packet.append(Data(bytes: &v, count: 4))
        }
        
        connection?.send(content: packet, completion: .contentProcessed { _ in
        })
    }
    
    func sendThrottle(value: Float) {
        sendDATA(index: 25, values: [value, value, value, value])
    }
    
    func sendReversers(status: Bool) {
        if status {
            sendCMND(of: "sim/engines/thrust_reverse_on")
        } else {
            sendCMND(of: "sim/engines/thrust_reverse_off")
        }
    }

    func sendGear(status: Bool) {
        let gearValue: Float = status ? 1.0 : 0.0
        sendDREF(value: gearValue, for: gearDataref)
    }
    
    func sendBrakes(status: Bool) {
        let brakeValue: Float = status ? 1.0 : 0.0
        sendDREF(value: brakeValue, for: brakesDataref)
    }
    
    func sendAutothrottle(status: Bool) {
        let value: Float = status ? 0.0 : -1.0
        sendDREF(value: value, for: autothrottleDataref)
    }
    
    func sendAutopilot(status: Bool) {
        sendCMND(of: autopilotCommand)
    }
    
    func sendFlaps(value: Float) {
        sendDREF(value: value, for: flapsDataref)
    }
    
    func sendSpeedbrakes(speedbrakesValue: Float) {
        sendDREF(value: speedbrakesValue, for: speedbrakesDataref)
    }

    private func startConnectionMonitor() {
        timer = DispatchSource.makeTimerSource(queue: DispatchQueue.main)
        timer?.schedule(deadline: .now(), repeating: 1.0)
        timer?.setEventHandler { [weak self] in
            guard let self = self else { return }
            let delta = Date().timeIntervalSince(self.lastPing)
            self.isConnected = connection?.state == .ready && delta < 5.0
        }
        timer?.resume()
    }

    func startReceiving() {
        connection?.receive(minimumIncompleteLength: 1, maximumLength: 1024) { [weak self] data, _, _, _ in
//            if let data = data,
//                let header = String(data: data.prefix(5), encoding: .utf8),
//                header == "PING\0" {
//            }
            self?.lastPing = Date()
            self?.startReceiving()
        }
    }
    
    func pingPacket() -> Data {
        var packet = Data()
        packet.append(contentsOf: "PING\0".utf8)
        return packet
    }

    func ping() {
        let packet = pingPacket()
        connection?.send(content: packet, completion: .contentProcessed { _ in
        })
    }
}

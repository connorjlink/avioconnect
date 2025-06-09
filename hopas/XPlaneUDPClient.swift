//
//  XPlaneUDPClient.swift
//  hopas
//
//  Created by Connor Link on 5/15/25.
//

import Network
import Foundation

class XPlaneUDPClient {
    private var connection: NWConnection?
    private let queue = DispatchQueue(label: "xplane.udp")
    private var timer: DispatchSourceTimer?
    private var lastPing: Date = Date.distantPast
    
    private var brakesStatus: Bool = false
    
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
        var packet = Data()
        packet.append(contentsOf: "DATA\0".utf8)

        var index: Int32 = 25
        packet.append(Data(bytes: &index, count: 4))

        let values = [value, value, value, value] + Array(repeating: Float(0), count: 4)
        for var v in values {
            packet.append(Data(bytes: &v, count: 4))
        }

        connection?.send(content: packet, completion: .contentProcessed { _ in
        })
    }

    func sendBrakes(status: Bool) {
        var packet = Data()
        packet.append(contentsOf: "DATA\0".utf8)

        var index: Int32 = 14 // Brakes data index
        packet.append(Data(bytes: &index, count: 4))

        let brakeValue: Float = status ? 1.0 : 0.0
        let values = [Float(0)] + [brakeValue] + Array(repeating: Float(0), count: 6)
        for var v in values {
            packet.append(Data(bytes: &v, count: 4))
        }

        connection?.send(content: packet, completion: .contentProcessed { _ in })
    }

    func sendReversers(status: Bool) {
        var packet = Data()
        packet.append(contentsOf: "DATA\0".utf8)
        
        var index: Int32 = 27
        packet.append(Data(bytes: &index, count: 4))
        
        let value: Float = status ? 3.0 : 1.0
        let values = [value, value] + Array(repeating: Float(0), count: 6)
        for var v in values {
            packet.append(Data(bytes: &v, count: 4))
        }
        
        connection?.send(content: packet, completion: .contentProcessed { _ in })
    }

    func sendAutothrottle(status: Bool) {
        var packet = Data()
        packet.append(contentsOf: "DATA\0".utf8)
        var index: Int32 = 117
        packet.append(Data(bytes: &index, count: 4))
        let value: Float = status ? 0.0 : -1.0
        let values = [value] + Array(repeating: Float(0), count: 7)
        for var v in values {
            packet.append(Data(bytes: &v, count: 4))
        }
        connection?.send(content: packet, completion: .contentProcessed { _ in })
    }

    func sendAutopilot(status: Bool) {
        var packet = Data()
        packet.append(contentsOf: "DATA\0".utf8)
        var index: Int32 = 108
        packet.append(Data(bytes: &index, count: 4))
        let value: Float = status ? 2.0 : 0.0
        let values = [Float(0), value] + Array(repeating: Float(0), count: 6)
        for var v in values {
            packet.append(Data(bytes: &v, count: 4))
        }
        connection?.send(content: packet, completion: .contentProcessed { _ in })
    }

    func requestStatus(index: Int32) {
        var packet = Data()
        packet.append(contentsOf: "DREQ\0".utf8)
        var index = index
        packet.append(Data(bytes: &index, count: 4))

        connection?.send(content: packet, completion: .contentProcessed { _ in
        })
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

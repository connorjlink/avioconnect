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

    init(host: String, port: UInt16 = 49000) {
        let endpoint = NWEndpoint.Host(host)
        let nwPort = NWEndpoint.Port(rawValue: port)!

        connection = NWConnection(host: endpoint, port: nwPort, using: .udp)
        connection?.start(queue: queue)
    }

    deinit {
        connection?.cancel()
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
        let values = [brakeValue] + Array(repeating: Float(0), count: 7)
        for var v in values {
            packet.append(Data(bytes: &v, count: 4))
        }

        connection?.send(content: packet, completion: .contentProcessed { _ in
        })
    }

    func sendReversers(status: Bool) {
        var packet = Data()
        packet.append(contentsOf: "DATA\0".utf8)

        var index: Int32 = 12 // Reversers data index
        packet.append(Data(bytes: &index, count: 4))

        let reverserValue: Float = status ? -1.0 : 0.0
        let values = [reverserValue, reverserValue, reverserValue, reverserValue] + Array(repeating:    Float(0), count: 4)
        for var v in values {
            packet.append(Data(bytes: &v, count: 4))
        }

        connection?.send(content: packet, completion: .contentProcessed { _ in
        })
    }

    func sendAutothrottle(status: Bool) {
        var packet = Data()
        packet.append(contentsOf: "DATA\0".utf8)

        var index: Int32 = 38 // Autothrottle data index
        packet.append(Data(bytes: &index, count: 4))

        let value: Float = status ? 1.0 : 0.0
        let values = [Float(0), value] + Array(repeating: Float(0), count: 6)
        for var v in values {
            packet.append(Data(bytes: &v, count: 4))
        }

        connection?.send(content: packet, completion: .contentProcessed { _ in
        })
    }

    func sendAutopilot(status: Bool) {
        var packet = Data()
        packet.append(contentsOf: "DATA\0".utf8)

        var index: Int32 = 13 // Autopilot data index
        packet.append(Data(bytes: &index, count: 4))

        let value: Float = status ? 1.0 : 0.0
        let values = [value] + Array(repeating: Float(0), count: 7)
        for var v in values {
            packet.append(Data(bytes: &v, count: 4))
        }

        connection?.send(content: packet, completion: .contentProcessed { _ in
        })
    }

    func requestStatus(index: Int32) {
        var packet = Data()
        packet.append(contentsOf: "DREQ\0".utf8)
        var index = index
        packet.append(Data(bytes: &index, count: 4))

        connection?.send(content: packet, completion: .contentProcessed { _ in
            self.connection?.cancel()
        })
    }

    func ping(completion: @escaping (Bool) -> Void) {
        var packet = Data()
        packet.append(contentsOf: "PING\0".utf8)

        connection?.send(content: packet, completion: .contentProcessed { _ in })
        connection?.receive(minimumIncompleteLength: 1, maximumLength: 1024) { data, _, _, _ in
            let isAlive = (data != nil)
            completion(isAlive)
        }
    }
}

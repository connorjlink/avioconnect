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

    func sendControls(pitch: Float, roll: Float, yaw: Float, to host: String, port: UInt16 = 49000) {
        guard let ip = IPv4Address(host) else { return }

        let endpoint = NWEndpoint.Host(ip.debugDescription)
        let nwPort = NWEndpoint.Port(rawValue: port)!

        let connection = NWConnection(host: endpoint, port: nwPort, using: .udp)
        connection.start(queue: queue)

        var packet = Data()
        packet.append(contentsOf: "DATA\0".utf8)

        var index: Int32 = 8
        packet.append(Data(bytes: &index, count: 4))

        let values = [pitch, roll, yaw] + Array(repeating: Float(0), count: 5)
        for value in values {
            var v = value
            packet.append(Data(bytes: &v, count: 4))
        }

        connection.send(content: packet, completion: .contentProcessed { _ in
            connection.cancel()
        })
    }

    func sendThrottle(value: Float, host: String, port: UInt16 = 49000) {
        guard let ip = IPv4Address(host) else { return }

        let connection = NWConnection(host: NWEndpoint.Host(ip.debugDescription),
                                       port: NWEndpoint.Port(rawValue: port)!,
                                       using: .udp)
        connection.start(queue: .global())

        var packet = Data()
        packet.append(contentsOf: "DATA\0".utf8)

        var index: Int32 = 25
        packet.append(Data(bytes: &index, count: 4))

        let values = [value, value, value, value] + Array(repeating: Float(0), count: 4)
        for var v in values {
            packet.append(Data(bytes: &v, count: 4))
        }

        connection.send(content: packet, completion: .contentProcessed { _ in
            connection.cancel()
        })
    }
    
    func sendBrakes(host: String, port: UInt16 = 49000, status: Bool) {
        guard let ip = IPv4Address(host) else { return }

        let connection = NWConnection(host: NWEndpoint.Host(ip.debugDescription),
                                      port: NWEndpoint.Port(rawValue: port)!,
                                      using: .udp)
        connection.start(queue: .global())

        var packet = Data()
        packet.append(contentsOf: "DATA\0".utf8)

        var index: Int32 = 14 // Brakes data index
        packet.append(Data(bytes: &index, count: 4))

        let brakeValue: Float = status ? 1.0 : 0.0
        let values = [brakeValue, brakeValue, 0.0] + Array(repeating: Float(0), count: 5)
        for var v in values {
            packet.append(Data(bytes: &v, count: 4))
        }

        connection.send(content: packet, completion: .contentProcessed { _ in
            connection.cancel()
        })
    }

    func sendReversers(host: String, port: UInt16 = 49000, status: Bool) {
        guard let ip = IPv4Address(host) else { return }
    
        let connection = NWConnection(host: NWEndpoint.Host(ip.debugDescription),
                                      port: NWEndpoint.Port(rawValue: port)!,
                                      using: .udp)
        connection.start(queue: .global())
    
        var packet = Data()
        packet.append(contentsOf: "DATA\0".utf8)
    
        var index: Int32 = 12 // Reversers data index
        packet.append(Data(bytes: &index, count: 4))
    
        let reverserValue: Float = status ? 1.0 : 0.0
        let values = [reverserValue, reverserValue, reverserValue, reverserValue] + Array(repeating:    Float(0), count: 4)
        for var v in values {
            packet.append(Data(bytes: &v, count: 4))
        }
    
        connection.send(content: packet, completion: .contentProcessed { _ in
            connection.cancel()
        })
    }

    func requestBrakesStatus(host: String, port: UInt16 = 49000) {
        guard let ip = IPv4Address(host) else { return }

        let connection = NWConnection(host: NWEndpoint.Host(ip.debugDescription),
                                      port: NWEndpoint.Port(rawValue: port)!,
                                      using: .udp)
        connection.start(queue: .global())

        var packet = Data()
        packet.append(contentsOf: "DREQ\0".utf8)
        var index: Int32 = 14
        packet.append(Data(bytes: &index, count: 4))

        connection.send(content: packet, completion: .contentProcessed { _ in
            connection.cancel()
        })
    }

    func ping(host: String, port: UInt16 = 49000, completion: @escaping (Bool) -> Void) {
        guard let ip = IPv4Address(host) else {
            completion(false)
            return
        }
        let connection = NWConnection(host: NWEndpoint.Host(ip.debugDescription),
                                      port: NWEndpoint.Port(rawValue: port)!,
                                      using: .udp)
        connection.stateUpdateHandler = { state in
            if case .ready = state {
                var packet = Data()
                packet.append(contentsOf: "PING\0".utf8)
                connection.send(content: packet, completion: .contentProcessed { _ in })
                connection.receive(minimumIncompleteLength: 1, maximumLength: 1024) { data, _, _, _ in
                    let isAlive = (data != nil && !data!.isEmpty)
                    completion(isAlive)
                    connection.cancel()
                }
            }
        }
        connection.start(queue: .global())
    }
}

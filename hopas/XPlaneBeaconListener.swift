//
//  XPlaneBeaconListener.swift
//  hopas
//
//  Created by Connor Link on 5/15/25.
//

import SwiftUI
import Network

class XPlaneBeaconListener: ObservableObject {
    @Published var detectedInstances: [XPlaneInstance] = []
    private var listener: NWListener?

    struct XPlaneInstance: Identifiable {
        let id = UUID()
        let ipAddress: String
        let port: UInt16 = 49000
    }

    func startListening() {
        do {
            let parameters = NWParameters.udp
            listener = try NWListener(using: parameters, on: 49707)
            listener?.newConnectionHandler = { [weak self] connection in
                self?.handleConnection(connection)
            }
            listener?.start(queue: .main)
        } catch {
            print("Failed to start listener: \(error)")
        }
    }

    func stopListening() {
        listener?.cancel()
        listener = nil
    }

    private func handleConnection(_ connection: NWConnection) {
        connection.start(queue: .main)
        connection.receiveMessage { [weak self] data, _, _, _ in
            guard let self = self, let data = data else { return }
            
            // if possible, try to extract the IP address and port from the connection
            if case let .hostPort(host, port) = connection.endpoint {
                let ipAddress = host.debugDescription.trimmingCharacters(in: CharacterSet(charactersIn: "\""))
                let portValue = port.rawValue
                self.parseBeaconData(data, ipAddress: ipAddress, port: portValue)
            }
        }
    }

    private func parseBeaconData(_ data: Data, ipAddress: String, port: UInt16) {
        // verify that at least a header is present
        guard data.count >= 5 else { return }
        
        let header = String(data: data.prefix(5), encoding: .utf8)
        guard header == "BECN\0" else { return }

        DispatchQueue.main.async {
            let instance = XPlaneInstance(ipAddress: ipAddress)
            if !self.detectedInstances.contains(where: { $0.ipAddress == ipAddress }) {
                self.detectedInstances.append(instance)
            }
        }
    }
}

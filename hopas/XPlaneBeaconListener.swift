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
        let port: UInt16
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
            self.parseBeaconData(data)
        }
    }

    private func parseBeaconData(_ data: Data) {
        guard data.count >= 11 else { return } // At least header (5) + IP (4) + Port (2)
        
        let header = String(data: data.prefix(5), encoding: .utf8)
        guard header == "BECN\0" else { return }

        // Extract IP address (bytes 5...8)
        let ipBytes = data[5...8]
        let ipAddress = ipBytes.map { String($0) }.joined(separator: ".")

        // Extract port (bytes 9 and 10, big-endian)
        let port = (UInt16(data[9]) << 8) | UInt16(data[10])

        DispatchQueue.main.async {
            let instance = XPlaneInstance(ipAddress: ipAddress, port: port)
            if !self.detectedInstances.contains(where: { $0.ipAddress == ipAddress && $0.port == port }) {
                self.detectedInstances.append(instance)
            }
        }
    }
}

import SwiftUI
import CoreMotion
import Network

// MARK: - MotionManager
class MotionManager: ObservableObject {
    private let motionManager = CMMotionManager()
    @Published var pitch: Float = 0
    @Published var roll: Float = 0
    @Published var yaw: Float = 0

    private var referenceAttitude: CMAttitude?

    func startUpdates() {
        guard motionManager.isDeviceMotionAvailable else { return }
    
        motionManager.deviceMotionUpdateInterval = 0.05
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in
            guard let self = self, let data = motion else { return }
    
            if let reference = self.referenceAttitude {
                // Transform the current attitude relative to the reference attitude
                data.attitude.multiply(byInverseOf: reference)
            }
    
            // Correctly assign pitch, roll, and yaw based on the transformed attitude
            self.pitch = 2.0 * Float(data.attitude.roll) / .pi // Roll is mapped to pitch
            self.roll = 2.0 * Float(data.attitude.yaw) / .pi // Pitch is mapped to roll
            self.yaw = 2.0 * Float(data.attitude.pitch) / .pi    // Yaw remains the same
        }
    }

    func stopUpdates() {
        motionManager.stopDeviceMotionUpdates()
    }

    func calibrate() {
        // Save the current attitude as the reference
        if let currentAttitude = motionManager.deviceMotion?.attitude {
            referenceAttitude = currentAttitude
        }
    }

    func getCalibratedPitch() -> Float {
        return pitch
    }

    func getCalibratedRoll() -> Float {
        return roll
    }

    func getCalibratedYaw() -> Float {
        return yaw
    }
}

// MARK: - XPlaneUDPClient
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

        var values = [pitch, roll, yaw] + Array(repeating: Float(0), count: 5)
        for value in values {
            var v = value
            packet.append(Data(bytes: &v, count: 4))
        }

        connection.send(content: packet, completion: .contentProcessed { _ in
            connection.cancel()
        })
    }
}

// MARK: - ContentView
struct ContentView: View {
    @StateObject private var motion = MotionManager()
    private let client = XPlaneUDPClient()

    @State private var isTransmitting = false
    @State private var timer: Timer?
    @State private var ipAddress: String = "192.168.1.100"

    var body: some View {
        VStack(spacing: 20) {
            Text("X-Plane Controller").font(.largeTitle)
            VStack {
                Text("Pitch: \(motion.getCalibratedPitch(), specifier: "%.2f")")
                Text("Roll: \(motion.getCalibratedRoll(), specifier: "%.2f")")
                Text("Yaw: \(motion.getCalibratedYaw(), specifier: "%.2f")")
            }
            TextField("X-Plane IP Address", text: $ipAddress)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.decimalPad)
                .padding()

            Button(isTransmitting ? "Stop" : "Start") {
                toggleTransmission()
            }
            .padding()
            .background(isTransmitting ? Color.red : Color.green)
            .foregroundColor(.white)
            .cornerRadius(10)

            Button("Calibrate") {
                motion.calibrate()
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .padding()
        .onAppear { motion.startUpdates() }
        .onDisappear {
            motion.stopUpdates()
            timer?.invalidate()
        }
    }

    func toggleTransmission() {
        isTransmitting.toggle()

        if isTransmitting {
            timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
                client.sendControls(
                    pitch: motion.getCalibratedPitch(),
                    roll: motion.getCalibratedRoll(),
                    yaw: motion.getCalibratedYaw(),
                    to: ipAddress
                )
            }
        } else {
            timer?.invalidate()
            timer = nil
        }
    }
}

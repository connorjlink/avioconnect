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
                data.attitude.multiply(byInverseOf: reference)
            }

            self.pitch = 2.0 * Float(data.attitude.roll) / .pi
            self.roll = 2.0 * Float(data.attitude.yaw) / .pi
            self.yaw = 4.0 * Float(data.attitude.pitch) / .pi
        }
    }

    func stopUpdates() {
        motionManager.stopDeviceMotionUpdates()
    }

    func calibrate() {
        if let currentAttitude = motionManager.deviceMotion?.attitude {
            referenceAttitude = currentAttitude
        }
    }

    func getCalibratedPitch() -> Float {
        return min(max(pitch, 1.0), -1.0)
    }

    func getCalibratedRoll() -> Float {
        return -min(max(roll, 1.0), -1.0)
    }

    func getCalibratedYaw() -> Float {
        return -min(max(yaw, 1.0), -1.0)
    }
}

// MARK: - XPlaneBeaconListener
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
        guard data.count >= 5 else { return } // Minimum size for a valid beacon
        let header = String(data: data.prefix(5), encoding: .utf8)
        if header == "BECN\0" {
            let ipAddress = data[5...8].map { String($0) }.joined(separator: ".")
            let port = UInt16(data[9]) << 8 | UInt16(data[10])
            DispatchQueue.main.async {
                let instance = XPlaneInstance(ipAddress: ipAddress, port: port)
                if !self.detectedInstances.contains(where: { $0.ipAddress == ipAddress && $0.port == port }) {
                    self.detectedInstances.append(instance)
                }
            }
        }
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
}

// MARK: - ContentView
struct ContentView: View {
    @StateObject private var motion = MotionManager()
    private let client = XPlaneUDPClient()

    @StateObject private var beaconListener = XPlaneBeaconListener()
    @State private var selectedInstance: XPlaneBeaconListener.XPlaneInstance?

    @State private var isTransmitting = false
    @State private var isYawControlEnabled = true
    @State private var ipAddress: String = "10.49.168.206"
    @State private var transmittedPitch: Float = 0
    @State private var transmittedRoll: Float = 0
    @State private var transmittedYaw: Float = 0
    @State private var throttleValue: Float = 0.5 // Default throttle value

    @FocusState private var isTextFieldFocused: Bool // To manage keyboard focus

    var body: some View {
        HStack(spacing: 20) {
            VStack {
                Text("Detected X-Plane Instances")
                    .font(.headline)
    
                List(beaconListener.detectedInstances) { instance in
                    Button(action: {
                        selectedInstance = instance
                    }) {
                        Text("\(instance.ipAddress):\(instance.port)")
                    }
                }
    
                if let selectedInstance = selectedInstance {
                    Text("Selected Instance: \(selectedInstance.ipAddress):\(selectedInstance.port)")
                }
            }
            .onAppear {
                beaconListener.startListening()
            }
            .onDisappear {
                beaconListener.stopListening()
            }

            // Left Column: Throttle Slider
            VStack {
                Text("Throttle: \(throttleValue, specifier: "%.2f")")
                Slider(value: $throttleValue, in: 0...1)
                    .rotationEffect(.degrees(-90)) // Rotate slider vertically
                    .frame(height: 200) // Adjust height for vertical slider
                    .onChange(of: throttleValue) { newValue in
                        client.sendThrottle(value: newValue, host: ipAddress)
                    }
            }
            .padding()

            // Center Column: Indicators and Controls
            VStack(spacing: 20) {
                Text("X-Plane Controller").font(.largeTitle)

                // Roll and Pitch Box
                ZStack {
                    Rectangle()
                        .stroke(Color.gray, lineWidth: 2)
                        .frame(width: 200, height: 200)

                    Circle()
                        .fill(Color.red)
                        .frame(width: 20, height: 20)
                        .offset(
                            x: CGFloat(isTransmitting ? transmittedRoll * 100 : 0),
                            y: CGFloat(isTransmitting ? transmittedPitch * 100 : 0) // Inverted pitch
                        )
                }

                // Yaw Slider
                VStack {
                    Text("Yaw: \(isTransmitting ? transmittedYaw : 0, specifier: "%.2f")")
                    Slider(value: Binding(
                        get: { isTransmitting ? transmittedYaw : 0 },
                        set: { _ in }
                    ), in: -1...1)
                        .frame(width: 200) // Same width as the square
                        .disabled(true)
                }
                .padding()
            }

            // Right Column: Live Readouts and Controls
            VStack(spacing: 20) {
                // Toggle for Yaw Control
                Toggle("Enable Yaw Control", isOn: $isYawControlEnabled)
                    .padding()

                // Live Readouts
                VStack {
                    Text("Live Pitch: \(motion.getCalibratedPitch(), specifier: "%.2f")")
                    Text("Live Roll: \(motion.getCalibratedRoll(), specifier: "%.2f")")
                    Text("Live Yaw: \(motion.getCalibratedYaw(), specifier: "%.2f")")
                }

                Button("Calibrate and Transmit") {
                    // No action here, as calibration and transmission will be handled in the gesture
                }
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(10)
                .onLongPressGesture(
                    minimumDuration: 0.1,
                    pressing: { isPressing in
                        if isPressing {
                            if !isTransmitting {
                                motion.calibrate() // Calibrate once when the button is first pressed
                                isTransmitting = true
                                startTransmission()
                            }
                        } else {
                            stopTransmission() // Stop transmitting when the button is released
                        }
                    }
                ) {}

                // IP Address Input
                TextField("X-Plane IP Address", text: $ipAddress)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.decimalPad)
                    .focused($isTextFieldFocused) // Bind focus state
                    .padding()

                Button("Done") {
                    isTextFieldFocused = false // Dismiss keyboard
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
        }
        .padding()
        .onAppear { 
            motion.startUpdates()
            startThrottleTransmission() // Start throttle transmission
        }
        .onDisappear { 
            motion.stopUpdates()
        }
    }

    func startTransmission() {
        Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { timer in
            guard isTransmitting else {
                timer.invalidate()
                transmittedPitch = 0
                transmittedRoll = 0
                transmittedYaw = 0
                client.sendControls(pitch: 0, roll: 0, yaw: 0, to: ipAddress)
                return
            }

            transmittedPitch = motion.getCalibratedPitch() // Inverted pitch
            transmittedRoll = motion.getCalibratedRoll()
            transmittedYaw = isYawControlEnabled ? motion.getCalibratedYaw() : 0

            client.sendControls(
                pitch: transmittedPitch,
                roll: transmittedRoll,
                yaw: transmittedYaw,
                to: ipAddress
            )
        }
    }

    func startThrottleTransmission() {
        Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            client.sendThrottle(value: throttleValue, host: ipAddress)
        }
    }

    func stopTransmission() {
        isTransmitting = false
        transmittedPitch = 0
        transmittedRoll = 0
        transmittedYaw = 0
        client.sendControls(pitch: 0, roll: 0, yaw: 0, to: ipAddress) // Send zeroed controls
    }
}

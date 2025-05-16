import SwiftUI
import Network
import Combine

// MARK: - ContentView
struct ContentView: View {
    @StateObject private var motion = MotionManager()
    private let client = XPlaneUDPClient()

    @StateObject private var beaconListener = XPlaneBeaconListener()
    @State private var selectedInstance: XPlaneBeaconListener.XPlaneInstance?

    @StateObject private var orientationObserver = OrientationObserver()

    @State private var statusUpdateTimer: Timer?
    @State private var throttleTimer: Timer?
    
    @State private var isTransmitting = false
    @State private var isConnected = false
    @State private var isOpened = false
    @State private var isYawControlEnabled = true
    @State private var isPitchControlInverted = false
    @State private var transmitRate: Int = 10
    @State private var maxRollOrientation: Float = 1.0
    @State private var maxYawOrientation: Float = 1.0
    @State private var maxPitchOrientation: Float = 1.0
    @State private var ipAddress: String = "192.168.1.19"
    @State private var transmittedPitch: Float = 0
    @State private var transmittedRoll: Float = 0
    @State private var transmittedYaw: Float = 0
    @State private var throttleValue: Float = 0.0 // Default throttle value

    @State private var brakesActive: Bool = false
    @State private var reversersActive: Bool = false

    @State private var isReverseThrustEnabled = false

    @State private var brakesListener: NWListener?

    @State private var isShowingSettings = false

    @FocusState private var isTextFieldFocused: Bool // To manage keyboard focus

    var body: some View {
        ZStack {
            if orientationObserver.isLandscape {
                // Main app content
                ZStack {
                    if !isOpened {
                        ZStack(alignment: .topTrailing) {
                            VStack {
                                Text("Detected X-Plane Instances")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding(.top, 16)
                    
                                Text("Tap to connect to an instance")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                    
                                List(beaconListener.detectedInstances) { instance in
                                    Button(action: {
                                        selectedInstance = instance
                                        isOpened = true
                                        ipAddress = instance.ipAddress
                                    }) {
                                        Text("\(instance.ipAddress):\(instance.port)")
                                    }
                                }
                            }
                            .onAppear {
                                beaconListener.startListening()
                            }
                            .onDisappear {
                                beaconListener.stopListening()
                            }
                    
                            Button(action: {
                                isOpened = true
                            }) {
                                Image(systemName: "forward.fill")
                                    .imageScale(.large)
                                    .padding()
                            }
                            .accessibilityLabel("Skip")
                        }

                    } else {
                        VStack(spacing: 10) {
                            HStack {
                                // Connection Indicator
                                Text("X-Plane Controller — Host: \(ipAddress)")
                                
                                Circle()
                                    .fill(isConnected ? Color.green : Color.red)
                                    .frame(width: 10, height: 10)
                                
                                Spacer()

                                Button(action: { isShowingSettings = true }) {
                                    Image(systemName: "gearshape")
                                        .imageScale(.large)
                                        .padding()
                                }
                                .sheet(isPresented: $isShowingSettings) {
                                    SettingsView(
                                        isYawControlEnabled: $isYawControlEnabled,
                                        isPitchControlInverted: $isPitchControlInverted,
                                        ipAddress: $ipAddress,
                                        transmitRate: $transmitRate,
                                        maxRollOrientation: $maxRollOrientation,
                                        maxYawOrientation: $maxYawOrientation,
                                        maxPitchOrientation: $maxPitchOrientation
                                    )
                                }
                            }
                            
                            HStack {
                                // Left Column: Throttle Slider
                                VStack {
                                    Text("Throttle: \(throttleValue, specifier: "%.2f")")
                                    Slider(value: $throttleValue, in: 0...1)
                                        .rotationEffect(.degrees(-90)) // Rotate slider vertically
                                        .frame(height: 200) // Adjust height for vertical slider
                                        .onChange(of: throttleValue) { newValue in
                                            client.sendThrottle(value: newValue, host: ipAddress)
                                        }
                                    
                                    HStack {
                                        Button("Reversers") {
                                            reversersActive.toggle()
                                            client.sendReversers(host: ipAddress, status: reversersActive)
                                        }
                                        .padding()
                                        .background(reversersActive ? Color.red : Color.green)
                                        .foregroundColor(.white)
                                        .cornerRadius(10)

                                        Button("Brakes") {
                                            brakesActive.toggle()
                                            client.sendBrakes(host: ipAddress, status: brakesActive)
                                        }
                                        .padding()
                                        .background(brakesActive ? Color.red : Color.green)
                                        .foregroundColor(.white)
                                        .cornerRadius(10)
                                    }
                                }
                                .padding()

                                // Center Column: Indicators and Controls
                                VStack(spacing: 20) {
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
                                                y: CGFloat(isTransmitting ? transmittedPitch * 100 : 0)
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
                                    // Live Readouts
                                    GroupBox(label:
                                            Text("Live Readouts")
                                        ) {
                                        VStack {
                                            Text("Pitch: \(motion.getCalibratedPitch(), specifier: "%.2f")")
                                            Text("Roll: \(motion.getCalibratedRoll(), specifier: "%.2f")")
                                            Text("Yaw: \(motion.getCalibratedYaw(), specifier: "%.2f")")
                                        }
                                    }

                                    Button("Control") {
                                        // No action here, as calibration and transmission will be handled in the gesture
                                    }
                                    .padding()
                                    .background(Color.green)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                                    .disabled(!isConnected)
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
                                }
                            }
                        }
                        .onAppear { 
                            motion.startUpdates()
                            startThrottleTransmission()
                            startStatusUpdates()
                        }
                        .onDisappear { 
                            motion.stopUpdates()
                            stopThrottleTransmission()
                            stopStatusUpdates()
                        }
                    }
                }
                .padding()
                
            } else {
                // Message to rotate to landscape
                VStack {
                    Text("Please rotate your device to landscape orientation.")
                        .multilineTextAlignment(.center)
                        .padding()

                    Image(systemName: "rectangle.portrait.rotate")
                        .imageScale(.large)
                        .padding()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black.opacity(0.8))
                .foregroundColor(.white)
            }
        }
        .animation(.easeInOut, value: orientationObserver.isLandscape)
    }

    func startTransmission() {
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            guard isTransmitting else {
                timer.invalidate()
                transmittedPitch = 0
                transmittedRoll = 0
                transmittedYaw = 0
                client.sendControls(pitch: 0, roll: 0, yaw: 0, to: ipAddress)
                return
            }

            transmittedPitch = motion.getCalibratedPitch()
            transmittedPitch = isPitchControlInverted ? -transmittedPitch : transmittedPitch;
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

    func stopTransmission() {
        isTransmitting = false
        transmittedPitch = 0
        transmittedRoll = 0
        transmittedYaw = 0
        client.sendControls(pitch: 0, roll: 0, yaw: 0, to: ipAddress) // Send zeroed controls
    }

    func startThrottleTransmission() {
        throttleTimer?.invalidate() // Detén cualquier timer previo
        throttleTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            client.sendThrottle(value: throttleValue, host: ipAddress)
        }
    }
    
    func stopThrottleTransmission() {
        throttleTimer?.invalidate()
        throttleTimer = nil
    }

    func startBrakesStatusListener() {
        do {
            let parameters = NWParameters.udp
            let listener = try NWListener(using: parameters, on: 49001)
            brakesListener = listener
            listener.newConnectionHandler = { connection in
                connection.start(queue: .global())
                receiveBrakesStatus(connection: connection)
            }
            listener.start(queue: .global())
        } catch {
            print("Error initializing brakes listener: \(error)")
        }
    }

    func receiveBrakesStatus(connection: NWConnection) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 1024) { data, _, _,   _ in
            if let data = data, data.count >= 13 {
                let header = String(data: data.prefix(5), encoding: .utf8)
                if header == "DATA\0" {
                    let indexData = data.subdata(in: 5..<9)
                    let index = indexData.withUnsafeBytes { $0.load(as: Int32.self) }
                    if index == 14 {
                        // Brakes value
                        let brakeValueData = data.subdata(in: 9..<13)
                        let brakeValue = brakeValueData.withUnsafeBytes { $0.load(as: Float.self) }
                        DispatchQueue.main.async {
                            brakesActive = (brakeValue > 0.5)
                        }
                    } else if index == 17 {
                        // Weight on wheels value
                        let wowValueData = data.subdata(in: 9..<13)
                        let weightOnWheels = wowValueData.withUnsafeBytes { $0.load(as: Float.self) }
                        DispatchQueue.main.async {
                            isReverseThrustEnabled = (weightOnWheels > 0.5)
                        }
                    }
                }
            }
        }
    }

    func startStatusUpdates() {
        statusUpdateTimer?.invalidate()
        statusUpdateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            client.ping(host: ipAddress) { alive in
                DispatchQueue.main.async {
                    isConnected = alive
                }
            }
            client.requestBrakesStatus(host: ipAddress)
        }
    }

    func stopStatusUpdates() {
        statusUpdateTimer?.invalidate()
        statusUpdateTimer = nil
        brakesListener?.cancel()
        brakesListener = nil
        isConnected = false
    }
}

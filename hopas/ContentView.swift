import SwiftUI
import Network
import Combine
import Foundation

extension Comparable {
    func clamp(to limits: ClosedRange<Self>) -> Self {
        return min(max(self, limits.lowerBound), limits.upperBound)
    }
}

// MARK: - ContentView
struct ContentView: View {
    @StateObject private var motion = MotionManager()
    private static var defaultIpAddress = "192.168.1.19";
    private static var defaultPort: UInt16 = 49000;
    @State private var client = XPlaneUDPClient(host: defaultIpAddress, port: defaultPort)
    
    @StateObject private var beaconListener = XPlaneBeaconListener()
    @State private var selectedInstance: XPlaneBeaconListener.XPlaneInstance?

    @StateObject private var orientationObserver = OrientationObserver()
    
    @State private var isTransmitting = false
    @State private var isOpened = false
    @State private var isYawControlEnabled = true
    @State private var isPitchControlInverted = true
    @State private var isRollControlInverted = false
    @State private var isYawControlInverted = false
    @State private var transmitRate: Int = 10
    @State private var maxRollOrientation: Int = 90
    @State private var maxYawOrientation: Int = 90
    @State private var maxPitchOrientation: Int = 90
    @State private var ipAddress = defaultIpAddress
    @State private var port: String = "\(defaultPort)"
    @State private var transmittedPitch: Float = 0
    @State private var transmittedRoll: Float = 0
    @State private var transmittedYaw: Float = 0
    @State private var throttleValue: Float = 0.0
    @State private var speedbrakesValue: Float = 0.0
    @State private var flapsValue: Int = 0
    
    @State private var isReverseThrustEnabled = false
    @State private var isBrakesEnabled = false
    @State private var isGearDown = false
    @State private var isAutothrottleEnabled = false
    @State private var isAutopilotEnabled = false
    
    @State private var showReverseThrust = true
    @State private var showBrakes = true
    @State private var showGear = true
    @State private var showAutothrottle = true
    @State private var showAutopilot = true
    @State private var showFlaps = true
    @State private var showSpeedbrakes = true
    @State private var showThrottle = true
    @State private var showControls = true
    
    // default to the standard airbus flap configuration
    @State private var numberOfFlapsNotches: Int = 4
    
    @State private var isShowingSettings = false

    @FocusState private var isTextFieldFocused: Bool // To manage keyboard focus

    // must be of Double type for timer functions
    func computeReprate() -> Double {
        return 1.0 / Double(transmitRate)
    }

    func computeFlapHandle() -> Float {
        return Float(flapsValue) / Float(numberOfFlapsNotches)
    }
    
    func getLocalIPAddress() -> String? {
        var address: String?
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        if getifaddrs(&ifaddr) == 0 {
            var ptr = ifaddr
            while ptr != nil {
                defer { ptr = ptr?.pointee.ifa_next }
                guard let interface = ptr?.pointee else { continue }
                let addrFamily = interface.ifa_addr.pointee.sa_family
                if addrFamily == UInt8(AF_INET) {
                    let name = String(cString: interface.ifa_name)
                    if name == "en0" || name == "en1" { // Wi-Fi or Ethernet
                        var addr = interface.ifa_addr.pointee
                        var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                        getnameinfo(&addr, socklen_t(interface.ifa_addr.pointee.sa_len),
                                    &hostname, socklen_t(hostname.count),
                                    nil, socklen_t(0), NI_NUMERICHOST)
                        address = String(cString: hostname)
                        break
                    }
                }
            }
            freeifaddrs(ifaddr)
        }
        return address
    }
    
    var body: some View {
        ZStack {
            if orientationObserver.isLandscape {
                // Main app content
                ZStack {
                    if !isOpened {
                        ZStack(alignment: .topTrailing) {
                            VStack {
                                Text("Detected Simulator Instances")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding(.top, 16)
                    
                                Text("Tap to automatically connect")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                    
                                List(beaconListener.detectedInstances) { instance in
                                    Button(action: {
                                        selectedInstance = instance
                                        isOpened = true
                                        ipAddress = instance.ipAddress
                                        client.create(host: ipAddress, port: UInt16(port) ?? 49000)
                                    }) {
                                        Text("\(instance.ipAddress):\(String(instance.port))")
                                    }
                                }
                            }
                            .onAppear {
                                beaconListener.startListening()
                            }
                            .onDisappear {
                                beaconListener.stopListening()
                            }
                    
                            Button(action: { isOpened = true }) {
                                Image(systemName: "forward.fill")
                                    .imageScale(.large)
                                    .padding()
                            }
                            .accessibilityLabel("Skip")
                        }

                    } else {
                        VStack(spacing: 10) {
                            HStack {
                                // connection indicator (unreliable)
                                Text(client.isConnected ? "Connected" : "Disconnected")
                                Circle()
                                    .fill(client.isConnected ? Color.green : Color.red)
                                    .frame(width: 10, height: 10)
                                
                                Spacer()
                            
                                // try to reconnect to the same client
                                Button(action: { client.create(host: ipAddress, port: UInt16(port) ?? 49000) }) {
                                    Image(systemName: "arrow.trianglehead.counterclockwise")
                                        .imageScale(.large)
                                        .padding()
                                }
                                .accessibilityLabel("Reconnect")
                                
                                // go back to the beacon connection scanner screen
                                Button(action: { isOpened = false }) {
                                    Image(systemName: "link.icloud")
                                        .imageScale(.large)
                                        .padding()
                                }
                                .accessibilityLabel("Scan for instances")

                                // open the settings screen
                                Button(action: { isShowingSettings = true }) {
                                    Image(systemName: "gearshape")
                                        .imageScale(.large)
                                        .padding()
                                }
                                .sheet(isPresented: $isShowingSettings) {
                                    SettingsView(
                                        isYawControlEnabled: $isYawControlEnabled,
                                        isPitchControlInverted: $isPitchControlInverted,
                                        isRollControlInverted: $isRollControlInverted,
                                        isYawControlInverted: $isYawControlInverted,
                                        ipAddress: $ipAddress,
                                        port: $port,
                                        myIpAddress: getLocalIPAddress() ?? "Unknown",
                                        xPlaneUDPClient: $client,
                                        transmitRate: $transmitRate,
                                        maxRollOrientation: $maxRollOrientation,
                                        maxYawOrientation: $maxYawOrientation,
                                        maxPitchOrientation: $maxPitchOrientation,
                                        showReverseThrust: $showReverseThrust,
                                        showBrakes: $showBrakes,
                                        showGear: $showGear,
                                        showAutothrottle: $showAutothrottle,
                                        showAutopilot: $showAutopilot,
                                        showFlaps: $showFlaps,
                                        showSpeedbrakes: $showSpeedbrakes,
                                        showThrottle: $showThrottle,
                                        showControls: $showControls,
                                        numberOfFlapsNotches: $numberOfFlapsNotches
                                    )
                                }
                                .accessibilityLabel("Settings")
                            }
                            
                            HStack {
                                // leftmost column
                                HStack {
                                    // speedbrakes controls
                                    if (showSpeedbrakes) {
                                        VStack {
                                            Text("Speedbrakes: \(Int(speedbrakesValue * 100))%")
                                            Slider(value: $speedbrakesValue, in: 0...1)
                                                .frame(width: 150)
                                                .rotationEffect(.degrees(90))
                                                .onChange(of: speedbrakesValue) { newValue in
                                                    let fv = showFlaps ? computeFlapHandle() : 0.0
                                                    client.sendSpeedbrakesAndFlaps(speedbrakesValue: newValue, flapsValue: fv)
                                                }
                                        }
                                    }
                                    
                                    // thottle controls
                                    if (showThrottle) {
                                        VStack {
                                            Text("Thrust: \(Int(throttleValue * 100))%")
                                            Slider(value: $throttleValue, in: 0...1)
                                                .frame(width: 150)
                                                .rotationEffect(.degrees(-90))
                                                .disabled(isAutothrottleEnabled)
                                                .onChange(of: throttleValue) { newValue in
                                                    client.sendThrottle(value: newValue)
                                                }
                                        }
                                    }
                                    
                                    // flaps controls
                                    if (showFlaps) {
                                        VStack {
                                            Text("Flaps")
                                                .font(.headline)
                                                .bold()
                                            
                                            Button(action: {
                                                flapsValue = (flapsValue - 1).clamp(to: 0...numberOfFlapsNotches)
                                                sendFlapsAndSpeedbrakes()
                                            }) {
                                                Image(systemName: "arrowtriangle.up.square")
                                                    .imageScale(.large)
                                                    .padding()
                                            }
                                            .accessibilityLabel("Retract flaps one notch")
                                            
                                            Button(action: {
                                                flapsValue = (flapsValue + 1).clamp(to: 0...numberOfFlapsNotches)
                                                sendFlapsAndSpeedbrakes()
                                            }) {
                                                Image(systemName: "arrowtriangle.down.square")
                                                    .imageScale(.large)
                                                    .padding()
                                            }
                                            .accessibilityLabel("Extend flaps one notch")
                                        }
                                    }
                                }

                                // middle column
                                VStack {
                                    // transmitted roll and pitch box
                                    ZStack {
                                        Rectangle()
                                            .stroke(Color.gray, lineWidth: 2)
                                            .frame(width: 150, height: 150)

                                        Circle()
                                            .fill(Color.blue)
                                            .frame(width: 10, height: 10)
                                            .offset(
                                                x: CGFloat(isTransmitting ? transmittedRoll * 75 : 0),
                                                y: CGFloat(isTransmitting ? transmittedPitch * 75 : 0)
                                            )
                                    }

                                    // yaw slider
                                    ZStack {
                                        Rectangle()
                                            .stroke(Color.gray, lineWidth: 2)
                                            .frame(width: 150, height: 20)

                                        Circle()
                                            .fill(Color.blue)
                                            .frame(width: 10, height: 10)
                                            .offset(
                                                x: CGFloat(isTransmitting ? transmittedYaw * 75 : 0),
                                            )
                                    }
                                }

                                // rightmost column
                                VStack {
                                    VStack {
                                        Text("Live Readouts")
                                            .font(.headline)
                                            .bold()
                                        Text("Pitch: \(motion.getCalibratedPitch(), specifier: "%.2f")")
                                        Text("Roll: \(motion.getCalibratedRoll(), specifier: "%.2f")")
                                        Text("Yaw: \(motion.getCalibratedYaw(), specifier: "%.2f")")
                                    }
                                    .padding()

                                    Button("Control") {
                                        // no action here: calibration and transmission resolve the gesture handler
                                    }
                                    .padding()
                                    .background(isTransmitting ? Color.blue : Color.green)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                                    .disabled(!client.isConnected)
                                    .onLongPressGesture(
                                        minimumDuration: 0.1,
                                        pressing: { isPressing in
                                            if isPressing {
                                                if !isTransmitting {
                                                    motion.calibrate(newMaxPitch: maxPitchOrientation, newMaxRoll: maxRollOrientation, newMaxYaw: maxYawOrientation)
                                                    isTransmitting = true
                                                    startTransmission()
                                                }
                                            } else {
                                                isTransmitting = false
                                                stopTransmission()
                                            }
                                        }
                                    ) {
                                        // on gesture end
                                    }
                                }
                            }
                            
                            HStack {
                                if (showReverseThrust) {
                                    Toggle("Reversers", isOn: $isReverseThrustEnabled)
                                        .padding()
                                        .background(Color.gray.opacity(0.2))
                                        .cornerRadius(10)
                                        //.disabled(!hasReceivedReverseThrustStatus)
                                        .onChange(of: isReverseThrustEnabled) { newValue in
                                            client.sendReversers(status: newValue)
                                        }
                                }
                                
                                if (showBrakes) {
                                    Toggle("Brakes", isOn: $isBrakesEnabled)
                                        .padding()
                                        .background(Color.gray.opacity(0.2))
                                        .cornerRadius(10)
                                        .onChange(of: isBrakesEnabled) { newValue in
                                            client.sendBrakes(status: newValue)
                                        }
                                }
                                
                                if (showGear) {
                                    Toggle("Gear", isOn: $isGearDown)
                                        .padding()
                                        .background(Color.gray.opacity(0.2))
                                        .cornerRadius(10)
                                        .onChange(of: isGearDown) { newValue in
                                            client.sendGear(status: newValue)
                                        }
                                }
                                
                                if (showAutothrottle) {
                                    Toggle("A/T", isOn: $isAutothrottleEnabled)
                                        .padding()
                                        .background(Color.gray.opacity(0.2))
                                        .cornerRadius(10)
                                        .onChange(of: isAutothrottleEnabled) { newValue in
                                            client.sendAutothrottle(status: newValue)
                                        }
                                }
                                
                                if (showAutopilot) {
                                    Toggle("A/P", isOn: $isAutopilotEnabled)
                                        .padding()
                                        .background(Color.gray.opacity(0.2))
                                        .cornerRadius(10)
                                        .onChange(of: isAutopilotEnabled) { newValue in
                                            client.sendAutopilot(status: newValue)
                                        }
                                }
                            }
                        }
                        .onAppear { 
                            motion.startUpdates(interval: computeReprate())
                        }
                        .onDisappear { 
                            motion.stopUpdates()
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
        Timer.scheduledTimer(withTimeInterval: computeReprate(), repeats: true) { timer in
            guard isTransmitting else {
                timer.invalidate()
                transmittedPitch = 0
                transmittedRoll = 0
                transmittedYaw = 0
                client.sendControls(pitch: 0, roll: 0, yaw: 0)
                return
            }

            transmittedPitch = motion.getCalibratedPitch()
            transmittedPitch = isPitchControlInverted ? -transmittedPitch : transmittedPitch;
            transmittedRoll = motion.getCalibratedRoll()
            transmittedRoll = isRollControlInverted ? -transmittedRoll : transmittedRoll;
            transmittedYaw = isYawControlEnabled ? motion.getCalibratedYaw() : 0
            transmittedYaw = isYawControlInverted ? -transmittedYaw : transmittedYaw;

            client.sendControls(
                pitch: transmittedPitch,
                roll: transmittedRoll,
                yaw: transmittedYaw,
            )
        }
    }

    func stopTransmission() {
        isTransmitting = false
        transmittedPitch = 0
        transmittedRoll = 0
        transmittedYaw = 0
        // recenter the controls
        client.sendControls(pitch: 0, roll: 0, yaw: 0)
    }
    
    func sendFlapsAndSpeedbrakes() {
        let fv = showFlaps ? computeFlapHandle() : 0.0
        let sv = showSpeedbrakes ? speedbrakesValue : 0.0
        client.sendSpeedbrakesAndFlaps(speedbrakesValue: sv, flapsValue: fv)
    }
}

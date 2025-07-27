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
    @StateObject private var settings = SettingsModel()
    @StateObject private var client: SimulatorUDPClient

    init() {
        let settings = SettingsModel()
        settings.load()
        
        _settings = StateObject(wrappedValue: settings)
        _client = StateObject(wrappedValue: SimulatorUDPClient(settings: settings, host: SettingsModel.DEFAULT_IPADDRESS, port: SettingsModel.DEFAULT_PORT))
    }
    
    @StateObject private var beaconListener = SimulatorBeaconListener()
    @State private var selectedInstance: SimulatorBeaconListener.SimulatorInstance?

    @StateObject private var orientationObserver = OrientationObserver()
    
    @State private var isTransmitting = false
    @State private var isOpened = false
    
    // used to draw the control surfaces box
    @State private var transmittedPitch: Float = 0
    @State private var transmittedRoll: Float = 0
    @State private var transmittedYaw: Float = 0
    
    // from sliders and buttons
    @State private var throttleValue: Float = 0.0
    @State private var speedbrakesValue: Float = 0.0
    @State private var flapsValue: Int = 0
    @State private var trimValue: Float = 0.0
    
    // used fror the toggles
    @State private var isReverseThrustEnabled = false
    @State private var isBrakesEnabled = false
    @State private var isGearDown = false
    @State private var isAutothrottleEnabled = false
    @State private var isAutopilotEnabled = false
    
    @State private var isShowingSettings = false

    @FocusState private var isTextFieldFocused: Bool // To manage keyboard focus

    // used to manage the trim button long-press
    @State private var trimTimer: Timer?
    
    // must be of Double type for timer functions
    func computeReprate() -> Double {
        return 1.0 / Double(settings.transmitRate)
    }

    func computeFlapHandle() -> Float {
        return (Float(flapsValue) / Float(settings.numberOfFlapsNotches))
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
                                Text("Scanning for Simulator Instances")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding(.top, 16)
                    
                                Text("Tap to automatically connect")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                    
                                if (beaconListener.detectedInstances.isEmpty) {
                                    Text("No instances found. Please verify both devices are running on the same network.")
                                } else {
                                    List(beaconListener.detectedInstances) { instance in
                                        Button(action: {
                                            selectedInstance = instance
                                            isOpened = true
                                            client.create(host: settings.ipAddress, port: UInt16(settings.port) ?? 49000)
                                        }) {
                                            Text("\(instance.ipAddress):\(String(instance.port))")
                                        }
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
                        VStack {
                            HStack {
                                // connection indicator (unreliable)
                                Text(client.isConnected ? "Connected" : "Disconnected")
                                Circle()
                                    .fill(client.isConnected ? Color.green : Color.red)
                                    .frame(width: 10, height: 10)
                                
                                Spacer()
                            
                                // try to reconnect to the same client
                                Button(action: { client.create(host: settings.ipAddress, port: UInt16(settings.port) ?? 49000) }) {
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
                                        settings: settings,
                                        client: client,
                                        myIpAddress: getLocalIPAddress() ?? "Unknown",
                                    )
                                }
                                .accessibilityLabel("Settings")
                            }
                            
                            // main content area!!!!
                            ZStack {
                                // leftmost column
                                HStack {
                                    // trim controls
                                    if (settings.showTrim) {
                                        VStack {
                                            Text("TRIM")
                                                .font(.headline)
                                                .padding()
                                            
                                            VStack {
                                                Button(action: {
                                                    trimValue = (trimValue - 0.01).clamp(to: -1...1)
                                                    client.sendTrim(value: trimValue)
                                                }) {
                                                    Image(systemName: "arrowtriangle.up.square")
                                                        .font(.system(size: 48))
                                                }
                                                .accessibilityLabel("Pitch trim down one click")
                                                .disabled(trimValue <= -1.0)
                                                .onLongPressGesture(minimumDuration: 1.0, pressing: { isPressing in
                                                    if isPressing {
                                                        trimTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
                                                            if trimValue > -1.0 {
                                                                trimValue = (trimValue - 0.01).clamp(to: -1...1)
                                                                client.sendTrim(value: trimValue)
                                                            }
                                                        }
                                                    } else {
                                                        trimTimer?.invalidate()
                                                        trimTimer = nil
                                                    }
                                                }, perform: {})

                                                Button(action: {
                                                    trimValue = (trimValue + 0.01).clamp(to: -1...1)
                                                    client.sendTrim(value: trimValue)
                                                }) {
                                                    Image(systemName: "arrowtriangle.down.square")
                                                        .font(.system(size: 48))
                                                }
                                                .accessibilityLabel("Pitch trim up one notch")
                                                .disabled(trimValue >= 1.0)
                                                .onLongPressGesture(minimumDuration: 1.0, pressing: { isPressing in
                                                    if isPressing {
                                                        trimTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
                                                            if trimValue < 1.0 {
                                                                trimValue = (trimValue + 0.01).clamp(to: -1...1)
                                                                client.sendTrim(value: trimValue)
                                                            }
                                                        }
                                                    } else {
                                                        trimTimer?.invalidate()
                                                        trimTimer = nil
                                                    }
                                                }, perform: {})
                                            }
                                            .frame(height: 130)
                                            
                                            Text("\(Int(trimValue * 100))%")
                                                .padding()
                                        }
                                        .frame(width: 75)
                                    }
                                    
                                    // speedbrakes controls
                                    if (settings.showSpeedbrakes) {
                                        VStack {
                                            Text("SPDBRK")
                                                .font(.headline)
                                                .padding()
                                            
                                            ZStack {
                                                Slider(value: $speedbrakesValue, in: 0...1)
                                                    .frame(width: 130)
                                                    .rotationEffect(.degrees(90))
                                                    .onChange(of: speedbrakesValue) { newValue in
                                                        client.sendSpeedbrakes(value: newValue)
                                                    }
                                            }
                                            .frame(width: 40, height: 130)
                                            
                                            //.frame(width: 120, alignment: .center)
                                            Text("\(Int(speedbrakesValue * 100))%")
                                                .monospacedDigit()
                                                .frame(alignment: .center)
                                                .padding()
                                        }
                                    }
                                    
                                    // thottle controls
                                    if (settings.showThrottle) {
                                        VStack {
                                            Text("THR")
                                                .font(.headline)
                                                .padding()

                                            ZStack {
                                                Slider(value: $throttleValue, in: 0...1)
                                                    .frame(width: 130)
                                                    .rotationEffect(.degrees(-90))
                                                    .disabled(isAutothrottleEnabled)
                                                    .onChange(of: throttleValue) { newValue in
                                                        client.sendThrottle(value: newValue)
                                                    }
                                            }
                                            .frame(width: 40, height: 130)
                                            
                                            //.frame(width: 120, alignment: .center)
                                            Text("\(Int(throttleValue * 100))%")
                                                .monospacedDigit()
                                                .frame(alignment: .center)
                                                .padding()
                                        }
                                    }
                                    
                                    // align left
                                    Spacer()
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
                                HStack {
                                    // right align
                                    Spacer()
                                    
                                    // flaps controls
                                    if (settings.showFlaps) {
                                        VStack {
                                            Text("FLAP")
                                                .font(.headline)
                                                .padding()
                                            
                                            VStack {
                                                Button(action: {
                                                    flapsValue = (flapsValue - 1).clamp(to: 0...settings.numberOfFlapsNotches)
                                                    client.sendFlaps(value: computeFlapHandle())
                                                }) {
                                                    Image(systemName: "arrowtriangle.up.square")
                                                        .font(.system(size: 48))
                                                }
                                                .accessibilityLabel("Retract flaps one notch")
                                                .disabled(flapsValue <= 0)
                                                
                                                Button(action: {
                                                    flapsValue = (flapsValue + 1).clamp(to: 0...settings.numberOfFlapsNotches)
                                                    client.sendFlaps(value: computeFlapHandle())
                                                }) {
                                                    Image(systemName: "arrowtriangle.down.square")
                                                        .font(.system(size: 48))
                                                }
                                                .accessibilityLabel("Extend flaps one notch")
                                                .disabled(flapsValue >= settings.numberOfFlapsNotches)
                                            }
                                            .frame(height: 130)

                                            Text("F\(Int(flapsValue))")
                                                .padding()
                                        }
                                        .frame(width: 120)
                                    }
                                    
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
                                                        motion.calibrate(newMaxPitch: settings.maxPitchOrientation, newMaxRoll: settings.maxRollOrientation, newMaxYaw: settings.maxYawOrientation)
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
                            }
                            
                            HStack {
                                if (settings.showReverseThrust) {
                                    Toggle("REV", isOn: $isReverseThrustEnabled)
                                        .padding()
                                        .background(Color.gray.opacity(0.2))
                                        .cornerRadius(10)
                                        //.disabled(!hasReceivedReverseThrustStatus)
                                        .onChange(of: isReverseThrustEnabled) { newValue in
                                            client.sendReversers(status: newValue)
                                        }
                                }
                                
                                if (settings.showBrakes) {
                                    Toggle("BRK", isOn: $isBrakesEnabled)
                                        .padding()
                                        .background(Color.gray.opacity(0.2))
                                        .cornerRadius(10)
                                        .onChange(of: isBrakesEnabled) { newValue in
                                            client.sendBrakes(status: newValue)
                                        }
                                }
                                
                                if (settings.showGear) {
                                    Toggle("GEAR", isOn: $isGearDown)
                                        .padding()
                                        .background(Color.gray.opacity(0.2))
                                        .cornerRadius(10)
                                        .onChange(of: isGearDown) { newValue in
                                            client.sendGear(status: newValue)
                                        }
                                }
                                
                                if (settings.showAutothrottle) {
                                    Toggle("A/T", isOn: $isAutothrottleEnabled)
                                        .padding()
                                        .background(Color.gray.opacity(0.2))
                                        .cornerRadius(10)
                                        .onChange(of: isAutothrottleEnabled) { newValue in
                                            client.sendAutothrottle(status: newValue)
                                        }
                                }
                                
                                if (settings.showAutopilot) {
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
            transmittedPitch = settings.isPitchControlInverted ? -transmittedPitch : transmittedPitch;
            transmittedRoll = motion.getCalibratedRoll()
            transmittedRoll = settings.isRollControlInverted ? -transmittedRoll : transmittedRoll;
            transmittedYaw = settings.isYawControlEnabled ? motion.getCalibratedYaw() : 0
            transmittedYaw = settings.isYawControlInverted ? -transmittedYaw : transmittedYaw;

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
}

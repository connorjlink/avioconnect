//
//  SettingsView.swift
//  hopas
//
//  Created by Connor Link on 5/15/25.
//

import SwiftUI

struct SettingsView: View {
    @Binding var isYawControlEnabled: Bool
    
    @Binding var isPitchControlInverted: Bool
    @Binding var isRollControlInverted: Bool
    @Binding var isYawControlInverted: Bool
    
    @Binding var ipAddress: String
    @Binding var port: String
    var myIpAddress: String
    @ObservedObject var xPlaneUDPClient: XPlaneUDPClient
    @Binding var transmitRate: Int
    
    @Binding var maxRollOrientation: Int
    @Binding var maxYawOrientation: Int
    @Binding var maxPitchOrientation: Int
    
    @Binding var showReverseThrust: Bool
    @Binding var showBrakes: Bool
    @Binding var showGear: Bool
    @Binding var showAutothrottle: Bool
    @Binding var showAutopilot: Bool
    
    @Binding var showFlaps: Bool
    @Binding var showSpeedbrakes: Bool
    @Binding var showThrottle: Bool
    @Binding var showControls: Bool
    
    @Binding var numberOfFlapsNotches: Int
    
    var notModifiable = "This value cannot be modified"

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Control Settings")) {
                    Toggle("Enable Yaw Control", isOn: $isYawControlEnabled)
                    
                    Toggle("Invert Roll Control", isOn: $isRollControlInverted)
                    Toggle("Invert Pitch Control", isOn: $isPitchControlInverted)
                    Toggle("Invert Yaw Control", isOn: $isYawControlInverted)
                    
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Max Roll Orientation")
                            Spacer()
                            Text("\(maxRollOrientation)˚")
                                .foregroundColor(.gray)
                        }
                        Slider(value: Binding(
                            get: { Float(maxRollOrientation) },
                            set: { maxRollOrientation = Int($0) }
                        ), in: 1...90)
                    }

                    VStack(alignment: .leading) {
                        HStack {
                            Text("Max Pitch Orientation")
                            Spacer()
                            Text("\(maxPitchOrientation)˚")
                                .foregroundColor(.gray)
                        }
                        Slider(value: Binding(
                            get: { Float(maxPitchOrientation) },
                            set: { maxPitchOrientation = Int($0) }
                        ), in: 1...90)
                    }

                    VStack(alignment: .leading) {
                        HStack {
                            Text("Max Yaw Orientation")
                            Spacer()
                            Text("\(maxYawOrientation)˚")
                                .foregroundColor(.gray)
                        }
                        Slider(value: Binding(
                            get: { Float(maxYawOrientation) },
                            set: { maxYawOrientation = Int($0) }
                        ), in: 1...90)
                    }
                }
                
                Section(header: Text("Interface Settings")) {
                    Toggle("Enable Reverse Thrust Controls", isOn: $showReverseThrust)
                    if showReverseThrust {
                        HStack {
                            Text("Reverse Thrust Dataref")
                            Spacer()
                            TextField("Enter a valid dataref...", text: $xPlaneUDPClient.reverseThrustDataref)
                                .foregroundStyle(.gray)
                                .bold()
                                .multilineTextAlignment(.trailing)
                        }
                    }
                    
                    Toggle("Enable Brake Controls", isOn: $showBrakes)
                    if showBrakes {
                        HStack {
                            Text("Brakes Dataref")
                            Spacer()
                            TextField("Enter a valid dataref...", text: $xPlaneUDPClient.brakesDataref)
                                .foregroundStyle(.gray)
                                .bold()
                                .multilineTextAlignment(.trailing)
                        }
                    }
                    
                    Toggle("Enable Gear Controls", isOn: $showGear)
                    if showGear {
                        HStack {
                            Text("Gear Dataref")
                            Spacer()
                            TextField("Enter a valid dataref...", text: $xPlaneUDPClient.gearDataref)
                                .foregroundStyle(.gray)
                                .bold()
                                .multilineTextAlignment(.trailing)
                        }
                    }
                    
                    Toggle("Enable Autothrottle Controls", isOn: $showAutothrottle)
                    if showAutothrottle {
                        HStack {
                            Text("Autothrottle Command")
                            Spacer()
                            TextField("Enter a valid command...", text: $xPlaneUDPClient.autothrottleDataref)
                                .foregroundStyle(.gray)
                                .bold()
                                .multilineTextAlignment(.trailing)
                        }
                    }
                    
                    Toggle("Enable Autopilot Controls", isOn: $showAutopilot)
                    if showAutopilot {
                        HStack {
                            Text("Autopilot Command")
                            Spacer()
                            TextField("Enter a valid command...", text: $xPlaneUDPClient.autopilotCommand)
                                .foregroundStyle(.gray)
                                .bold()
                                .multilineTextAlignment(.trailing)
                        }
                    }
                    
                    Toggle("Enable Speedbrakes Controls", isOn: $showSpeedbrakes)
                    if showSpeedbrakes {
                        HStack {
                            Text("Speedbrakes Dataref")
                            Spacer()
                            TextField("Enter a valid dataref...", text: $xPlaneUDPClient.speedbrakesDataref)
                                .foregroundStyle(.gray)
                                .bold()
                                .multilineTextAlignment(.trailing)
                        }
                    }
                    
                    Toggle("Enable Throttle Controls", isOn: $showThrottle)
                    if showThrottle {
                        HStack {
                            Text("Throttle Dataref")
                            Spacer()
                            TextField("Enter a valid dataref...", text: .constant(notModifiable))
                                .disabled(true)
                                .foregroundStyle(.gray)
                                .multilineTextAlignment(.trailing)
                        }
                    }
                    
                    Toggle("Enable Control Surface Outputs", isOn: $showControls)
                    if showControls {
                        HStack {
                            Text("Control Surface Dataref")
                            Spacer()
                            TextField("Enter a valid dataref...", text: .constant(notModifiable))
                                .disabled(true)
                                .foregroundStyle(.gray)
                                .multilineTextAlignment(.trailing)
                        }
                    }
                    
                    Toggle("Enable Flaps Controls", isOn: $showFlaps)
                    if showFlaps {
                        HStack {
                            Text("Flaps Dataref")
                            Spacer()
                            TextField("Enter a valid dataref...", text: $xPlaneUDPClient.flapsDataref)
                                .foregroundStyle(.gray)
                                .bold()
                                .multilineTextAlignment(.trailing)
                        }
                    }
                    
                    if showFlaps {
                        VStack {
                            HStack {
                                Text("Number of Flaps Notches")
                                Spacer()
                                Text("\(numberOfFlapsNotches)")
                                    .foregroundColor(.gray)
                                    .bold()
                            }
                            Slider(value: Binding(
                                get: { Float(numberOfFlapsNotches) },
                                set: { numberOfFlapsNotches = Int($0) }
                            ), in: 1...10)
                        }
                    }
                    
                    Text("Many addon aircraft ignore some or many of the default datarefs to which these controls write. Please test compatibility and report any concerns to me and disable non-functional controls to declutter them from the interface.")
                        .font(.footnote)
                }
                
                Section(header: Text("Network Settings")) {
                    HStack {
                        Text("My IP Address")
                            .foregroundColor(.gray)
                        Spacer()
                        Text("\(myIpAddress)")
                            .foregroundColor(.gray)
                    }
                    
                    HStack {
                        Text("Simulator IP Address")
                        Spacer()
                        TextField("e.g. 192.168.1.100", text: $ipAddress)
                            .keyboardType(.decimalPad)
                            .frame(maxWidth: 180)
                            .multilineTextAlignment(.trailing)
                            .bold()
                    }
                    
                    HStack {
                        Text("Simulator Port")
                        Spacer()
                        TextField("e.g. 49000", text: $port)
                            .keyboardType(.decimalPad)
                            .frame(maxWidth: 180)
                            .multilineTextAlignment(.trailing)
                            .bold()
                    }
                    
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Transmit Rate (Hz)")
                            Spacer()
                            Text("\(transmitRate) Hz")
                                .foregroundColor(.gray)
                                .bold()
                        }
                        Slider(value: Binding(
                            get: { Float(transmitRate) },
                            set: { transmitRate = Int($0) }
                        ), in: 1...30)
                    }
                }
                Section(header: Text("About")) {
                    Text("connor@connorjlink.com")
                    Text("© 2025 Connor J. Link. All Rights Reserved.")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .onTapGesture {
                // ugly hack to close the decimal-pad keyboard whenever the user taps outside of it
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                xPlaneUDPClient.cleanup()
                xPlaneUDPClient.create(host: ipAddress, port: UInt16(port) ?? 49000)
            }
        }
    }
}

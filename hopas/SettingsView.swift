//
//  SettingsView.swift
//  hopas
//
//  Created by Connor Link on 5/15/25.
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings: SettingsModel
    @ObservedObject var client: SimulatorUDPClient
    
    private var myIpAddress: String
    
    init(settings: SettingsModel, client: SimulatorUDPClient, myIpAddress: String) {
        self.settings = settings
        self.client = client
        self.myIpAddress = myIpAddress
    }
    
    @State private var showSaveAlert = false
    @State private var showLoadAlert = false
    @State private var showLoadConfirm = false
    
    private var notModifiable = "This value cannot be modified"

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Control Settings")) {
                    Toggle("Enable Yaw Control", isOn: $settings.isYawControlEnabled)
                    
                    Toggle("Invert Roll Control", isOn: $settings.isRollControlInverted)
                    Toggle("Invert Pitch Control", isOn: $settings.isPitchControlInverted)
                    Toggle("Invert Yaw Control", isOn: $settings.isYawControlInverted)
                    
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Max Roll Orientation")
                            Spacer()
                            Text("\(settings.maxRollOrientation)˚")
                                .foregroundColor(.gray)
                        }
                        Slider(value: Binding(
                            get: { Float(settings.maxRollOrientation) },
                            set: { settings.maxRollOrientation = Int($0) }
                        ), in: 1...90)
                    }

                    VStack(alignment: .leading) {
                        HStack {
                            Text("Max Pitch Orientation")
                            Spacer()
                            Text("\(settings.maxPitchOrientation)˚")
                                .foregroundColor(.gray)
                        }
                        Slider(value: Binding(
                            get: { Float(settings.maxPitchOrientation) },
                            set: { settings.maxPitchOrientation = Int($0) }
                        ), in: 1...90)
                    }

                    VStack(alignment: .leading) {
                        HStack {
                            Text("Max Yaw Orientation")
                            Spacer()
                            Text("\(settings.maxYawOrientation)˚")
                                .foregroundColor(.gray)
                        }
                        Slider(value: Binding(
                            get: { Float(settings.maxYawOrientation) },
                            set: { settings.maxYawOrientation = Int($0) }
                        ), in: 1...90)
                    }
                }
                
                Section(header: Text("Interface Settings")) {
                    Toggle("Enable Reverse Thrust Controls", isOn: $settings.showReverseThrust)
                    if settings.showReverseThrust {
                        HStack {
                            Text("Reverse Thrust Dataref")
                            Spacer()
                            TextField("Enter a valid dataref...", text: $settings.reverseThrustDataref)
                                .foregroundStyle(.gray)
                                .bold()
                                .multilineTextAlignment(.trailing)
                        }
                    }
                    
                    Toggle("Enable Brake Controls", isOn: $settings.showBrakes)
                    if settings.showBrakes {
                        HStack {
                            Text("Brakes Dataref")
                            Spacer()
                            TextField("Enter a valid dataref...", text: $settings.brakesDataref)
                                .foregroundStyle(.gray)
                                .bold()
                                .multilineTextAlignment(.trailing)
                        }
                    }
                    
                    Toggle("Enable Gear Controls", isOn: $settings.showGear)
                    if settings.showGear {
                        HStack {
                            Text("Gear Dataref")
                            Spacer()
                            TextField("Enter a valid dataref...", text: $settings.gearDataref)
                                .foregroundStyle(.gray)
                                .bold()
                                .multilineTextAlignment(.trailing)
                        }
                    }
                    
                    Toggle("Enable Autothrottle Controls", isOn: $settings.showAutothrottle)
                    if settings.showAutothrottle {
                        HStack {
                            Text("Autothrottle Command")
                            Spacer()
                            TextField("Enter a valid command...", text: $settings.autothrottleDataref)
                                .foregroundStyle(.gray)
                                .bold()
                                .multilineTextAlignment(.trailing)
                        }
                    }
                    
                    Toggle("Enable Autopilot Controls", isOn: $settings.showAutopilot)
                    if settings.showAutopilot {
                        HStack {
                            Text("Autopilot Command")
                            Spacer()
                            TextField("Enter a valid command...", text: $settings.autopilotCommand)
                                .foregroundStyle(.gray)
                                .bold()
                                .multilineTextAlignment(.trailing)
                        }
                    }
                    
                    Toggle("Enable Speedbrakes Controls", isOn: $settings.showSpeedbrakes)
                    if settings.showSpeedbrakes {
                        HStack {
                            Text("Speedbrakes Dataref")
                            Spacer()
                            TextField("Enter a valid dataref...", text: $settings.speedbrakesDataref)
                                .foregroundStyle(.gray)
                                .bold()
                                .multilineTextAlignment(.trailing)
                        }
                    }
                    
                    Toggle("Enable Throttle Controls", isOn: $settings.showThrottle)
                    if settings.showThrottle {
                        HStack {
                            Text("Throttle Dataref")
                            Spacer()
                            TextField("Enter a valid dataref...", text: .constant(notModifiable))
                                .disabled(true)
                                .foregroundStyle(.gray)
                                .multilineTextAlignment(.trailing)
                        }
                    }
                    
                    Toggle("Enable Control Surface Outputs", isOn: $settings.showControls)
                    if settings.showControls {
                        HStack {
                            Text("Control Surface Dataref")
                            Spacer()
                            TextField("Enter a valid dataref...", text: .constant(notModifiable))
                                .disabled(true)
                                .foregroundStyle(.gray)
                                .multilineTextAlignment(.trailing)
                        }
                    }
                    
                    Toggle("Enable Flaps Controls", isOn: $settings.showFlaps)
                    if settings.showFlaps {
                        HStack {
                            Text("Flaps Dataref")
                            Spacer()
                            TextField("Enter a valid dataref...", text: $settings .flapsDataref)
                                .foregroundStyle(.gray)
                                .bold()
                                .multilineTextAlignment(.trailing)
                        }
                    }
                    
                    if settings.showFlaps {
                        VStack {
                            HStack {
                                Text("Number of Flaps Notches")
                                Spacer()
                                Text("\(settings.numberOfFlapsNotches)")
                                    .foregroundColor(.gray)
                                    .bold()
                            }
                            Slider(value: Binding(
                                get: { Float(settings.numberOfFlapsNotches) },
                                set: { settings.numberOfFlapsNotches = Int($0) }
                            ), in: 1...10)
                        }
                    }
                    
                    Text("Many addon aircraft ignore some or many of the default datarefs to which these controls write. Please refer to their documentation for the appropriate datarefs to update above for best support.")
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
                        TextField("e.g. 192.168.1.100", text: $settings.ipAddress)
                            .keyboardType(.decimalPad)
                            .frame(maxWidth: 180)
                            .multilineTextAlignment(.trailing)
                            .bold()
                    }
                    
                    HStack {
                        Text("Simulator Port")
                        Spacer()
                        TextField("e.g. 49000", text: $settings.port)
                            .keyboardType(.decimalPad)
                            .frame(maxWidth: 180)
                            .multilineTextAlignment(.trailing)
                            .bold()
                    }
                    
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Transmit Rate (Hz)")
                            Spacer()
                            Text("\(settings.transmitRate) Hz")
                                .foregroundColor(.gray)
                                .bold()
                        }
                        Slider(value: Binding(
                            get: { Float(settings.transmitRate) },
                            set: { settings.transmitRate = Int($0) }
                        ), in: 1...30)
                    }
                }
                Section(header: Text("Application Setup")) {
                    HStack {
                        Text("Load Configuration")
                        Text("Performed automatically at app startup")
                            .foregroundStyle(.gray)
                        Spacer()
                        Button(action: {
                            showLoadConfirm = true
                        }) {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundColor(.blue)
                                .imageScale(.large)
                        }
                        .confirmationDialog("Forcibly reload settings? This will overwrite any unsaved changes.", isPresented: $showLoadConfirm) {
                            Button("Load", role: .destructive) {
                                settings.load()
                                showLoadAlert = true
                            }
                            Button("Cancel", role: .cancel) { }
                        }
                        .alert("Settings Loaded Successfully", isPresented: $showLoadAlert) {
                            Button("OK", role: .cancel) { }
                        }
                    }
                    
                    HStack {
                        Text("Save Configuration")
                        Text("Performed automatically at app shutdown")
                            .foregroundStyle(.gray)
                        Spacer()
                        Button(action: {
                            settings.save()
                            showSaveAlert = true
                        }) {
                            Image(systemName: "square.and.arrow.down")
                                .foregroundColor(.blue)
                                .imageScale(.large)
                        }
                        .alert("Settings Saved Successfully", isPresented: $showSaveAlert) {
                            Button("OK", role: .cancel) { }
                        }
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
                client.cleanup()
                client.create(host: settings.ipAddress, port: UInt16(settings.port) ?? 49000)
            }
        }
    }
}

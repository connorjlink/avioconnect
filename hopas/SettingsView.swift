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
    @Binding var ipAddress: String
    @Binding var xPlaneUDPClient: XPlaneUDPClient
    @Binding var transmitRate: Int
    
    @Binding var maxRollOrientation: Float
    @Binding var maxYawOrientation: Float
    @Binding var maxPitchOrientation: Float

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Control Settings")) {
                    Toggle("Enable Yaw Control", isOn: $isYawControlEnabled)
                    Toggle("Invert Pitch Control", isOn: $isPitchControlInverted)

                    VStack(alignment: .leading) {
                        HStack {
                            Text("Max Roll Orientation")
                            Spacer()
                            Text("\(maxRollOrientation, specifier: "%.2f")")
                                .foregroundColor(.gray)
                        }
                        Slider(value: Binding(
                            get: { maxRollOrientation },
                            set: { maxRollOrientation = $0 }
                        ), in: 0...1)
                    }

                    VStack(alignment: .leading) {
                        HStack {
                            Text("Max Pitch Orientation")
                            Spacer()
                            Text("\(maxPitchOrientation, specifier: "%.2f")")
                                .foregroundColor(.gray)
                        }
                        Slider(value: Binding(
                            get: { maxPitchOrientation },
                            set: { maxPitchOrientation = $0 }
                        ), in: 0...1)
                    }

                    VStack(alignment: .leading) {
                        HStack {
                            Text("Max Yaw Orientation")
                            Spacer()
                            Text("\(maxYawOrientation, specifier: "%.2f")")
                                .foregroundColor(.gray)
                        }
                        Slider(value: Binding(
                            get: { maxYawOrientation },
                            set: { maxYawOrientation = $0 }
                        ), in: 0...1)
                    }
                }
                Section(header: Text("Network Settings")) {
                    HStack {
                        Text("X-Plane IP Address")
                        Spacer()
                        TextField("e.g. 192.168.1.100", text: $ipAddress)
                            .keyboardType(.decimalPad)
                            .frame(maxWidth: 180)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Transmit Rate (Hz)")
                            Spacer()
                            Text("\(transmitRate) Hz")
                                .foregroundColor(.gray)
                        }
                        Slider(value: Binding(
                            get: { Float(transmitRate) },
                            set: { transmitRate = Int($0) }
                        ), in: 1...20)
                    }
                }
                Section(header: Text("About")) {
                    HStack {
                        Text("© 2025 Connor J. Link. All Rights Reserved.")
                        // todo add in-app purchase here
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .onTapGesture {
                // ugly hack to close the decimal-pad keyboard whenever the user taps outside of it
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                xPlaneUDPClient = XPlaneUDPClient(host: ipAddress, port: 49000)
            }
        }
    }
}

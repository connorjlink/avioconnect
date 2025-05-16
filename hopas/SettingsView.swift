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

                    Slider(value: Binding(
                        get: { maxRollOrientation },
                        set: { maxRollOrientation = $0 }
                    ), in: 0...1, label: {
                        Text("Max Roll Orientation")
                    })

                    Slider(value: Binding(
                        get: { maxPitchOrientation },
                        set: { maxPitchOrientation = $0 }
                    ), in: 0...1, label: {
                        Text("Max Pitch Orientation")
                    })

                    Slider(value: Binding(
                        get: { maxYawOrientation },
                        set: { maxYawOrientation = $0 }
                    ), in: 0...1, label: {
                        Text("Max Yaw Orientation")
                    })
                }
                Section(header: Text("Network Settings")) {
                    TextField("X-Plane IP Address", text: $ipAddress)
                        .keyboardType(.decimalPad)
                    
                    Slider(value: Binding(
                        get: { Float(transmitRate) },
                        set: { transmitRate = Int($0) }
                    ), in: 1...20, label: {
                        Text("Transmit Rate (Hz)")
                    })
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .onTapGesture {
                // ugly hack to close the decimal-pad keyboard whenever the user taps outside of it
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
        }
    }
}

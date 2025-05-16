//
//  MotionManager.swift
//  hopas
//
//  Created by Connor Link on 5/15/25.
//

import CoreMotion
import Combine

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

    // clamp to valid values since the device CAN output more than [-1, 1]
    
    func getCalibratedPitch() -> Float {
        return max(-1.0, min(pitch, 1.0))
    }

    func getCalibratedRoll() -> Float {
        return -max(-1.0, min(roll, 1.0))
    }

    func getCalibratedYaw() -> Float {
        return -max(-1.0, min(yaw, 1.0))
    }
}

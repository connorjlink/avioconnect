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
    
    var maxPitch: Int = 90
    var maxRoll: Int = 90
    var maxYaw: Int = 90

    private var referenceAttitude: CMAttitude?

    func startUpdates(interval: Double) {
        guard motionManager.isDeviceMotionAvailable else { return }

        motionManager.deviceMotionUpdateInterval = interval
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

    func calibrate(newMaxPitch: Int, newMaxRoll: Int, newMaxYaw: Int) {
        maxPitch = newMaxPitch
        maxRoll = newMaxRoll
        maxYaw = newMaxYaw
        
        if let currentAttitude = motionManager.deviceMotion?.attitude {
            referenceAttitude = currentAttitude
        }
    }

    // clamp to valid values since the device CAN output more than [-1, 1]
    
    private func getClamped(angle: Float) -> Float {
        return -max(-1.0, min(angle, 1.0))
    }
    
    func getCalibratedPitch() -> Float {
        return getClamped(angle: pitch * (90.0 / Float(maxPitch)))
    }
    
    func getCalibratedRoll() -> Float {
        return getClamped(angle: roll * (90.0 / Float(maxRoll)))
    }
    
    func getCalibratedYaw() -> Float {
        return getClamped(angle: yaw * (90.0 / Float(maxYaw)))
    }
}

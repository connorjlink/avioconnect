//
//  OrientationObserver.swift
//  hopas
//
//  Created by Connor Link on 5/15/25.
//

import SwiftUI
import Combine

class OrientationObserver: ObservableObject {
    @Published var isLandscape: Bool = UIDevice.current.orientation.isLandscape
    @Published var isLeft: Bool = false

    private var cancellable: AnyCancellable?

    init() {
        cancellable = NotificationCenter.default
            .publisher(for: UIDevice.orientationDidChangeNotification)
            .sink { _ in
                let orientation = UIDevice.current.orientation
                // Only update for valid orientations (not .unknown, .faceUp, etc.)
                if orientation.isValidInterfaceOrientation {
                    self.isLandscape = orientation.isLandscape
                    self.isLeft = orientation == .landscapeLeft
                }
            }
    }
}

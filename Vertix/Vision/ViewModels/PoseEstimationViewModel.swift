//
//  PoseEstimationViewModel.swift
//  Vertix
//
//  Created by Felicia Sword on 25/04/26.
//

//  PoseEstimationViewModel.swift
//  Vertix

import Foundation
import SwiftUI
import Combine

class PoseEstimationViewModel: ObservableObject {

    @Published var postureResult: PostureResult = PostureResult(
        neckAngle: 0.0,
        shoulderTilt: 0.0,
        spineAngle: 0.0,
        isGoodPosture: false,
        feedback: "Waiting for camera..."
    )
}

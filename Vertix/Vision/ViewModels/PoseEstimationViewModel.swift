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
// Placeholder — full MediaPipe code added in Step 3
class PoseEstimationViewModel: ObservableObject {

    @Published var postureResult: PostureResult = PostureResult(
        status: .unknown,
        confidence: 0.0,
        message: "Waiting for camera..."
    )
}

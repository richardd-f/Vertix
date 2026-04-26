//
//  PostureModel.swift
//  Vertix
//
//  Created by Felicia Sword on 25/04/26.
//

//  PostureModel.swift
//  Vertix

import Foundation

// Posture status options
enum PostureStatus {
    case good
    case bad
    case unknown
}

// Stores result of one posture check
struct PostureResult {
    let status: PostureStatus
    let confidence: Double      // 0.0 to 1.0
    let message: String         // e.g. "Sit up straight!"
}

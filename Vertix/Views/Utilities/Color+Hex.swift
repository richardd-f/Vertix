//
//  Color+Hex.swift
//  Vertix
//
//  Created by Clarice Harijanto on 03/05/26.
//

import SwiftUI

// Lets us write Color(hex: "2D5A3D") anywhere in the app
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8) & 0xFF) / 255
        let b = Double(int & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}

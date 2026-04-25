//
//  CameraPreviewView.swift
//  Vertix
//
//  Created by Felicia Sword on 25/04/26.
//

import SwiftUI

struct FocusModeView: View {
    @StateObject private var camera = CameraViewModel()
    var body: some View {
        ZStack {
//            camera fills whole background
            CameraPreviewView(session: camera.session)
                .ignoresSafeArea()
            VStack {
                Spacer()
                Text("Camera Action")
                    .foregroundColor(.white)
                    .padding()
            }
        }
        .onAppear {
            camera.startSession() // start camera when screen opens
        }
        .onDisappear {
            camera.stopSession() // stop camera when screen closes
        }
    }
}

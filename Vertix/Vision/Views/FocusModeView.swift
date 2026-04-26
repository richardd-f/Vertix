//
//  FocusModeView.swift
//  Vertix
//
//  Created by Felicia Sword on 26/04/26.
//

//  FocusModeView.swift
//  Vertix

import SwiftUI

struct FocusModeView: View {

    @StateObject private var camera = CameraViewModel()

    var body: some View {
        ZStack {
            // Camera feed fills background
            CameraPreviewView(session: camera.session)
                .ignoresSafeArea()

            // Temporary label to confirm camera is working
            VStack {
                Spacer()
                Text("📷 Camera Active")
                    .foregroundColor(.white)
                    .font(.headline)
                    .padding()
                    .background(Color.black.opacity(0.5))
                    .cornerRadius(10)
                    .padding(.bottom, 40)
            }
        }
        .onAppear {
            camera.startSession()
        }
        .onDisappear {
            camera.stopSession()
        }
    }
}

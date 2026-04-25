//
//  CameraViewModel.swift
//  Vertix
//
//  Created by Felicia Sword on 25/04/26.
//

import AVFoundation
import SwiftUI

class CameraViewModel: NSObject, ObservableObject {
    //    main camera controller
    let session = AVCaptureSession()
    
    //    the output that streams video frames
    private let videoOutput = AVCaptureVideoDataOutput()
    
    override init() {
        super.init( )
        setupCamera()
    }
    
    private func setupCamera () {
        session.beginConfiguration()
        session.sessionPreset = .high // HD quality
        
        //        1. get front facing camera
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video,
                                                   position: .front // front camera for posture detection
        ) else {
            print("No front camera available")
            return
        }
        
        //        2. connect the camera hardware to the session
        guard let input = try? AVCaptureDeviceInput(device: device) else {
            print("Could not create camera input")
            return
        }
        
        if session.canAddInput(input) {
            session.addInput(input)
        }
        
        //        3. set up video output (each frame gets sent here)
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue") // runs on bg thread
        )
        if session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)
        }
        
        //        4. mirror the front camera so it feels like a mirror
        videoOutput.connections.first?.isVideoMirrored = true
        
        session.commitConfiguration()
    }
    
    //    call this when ur study screen appears
    func startSession() {
        DispatchQueue.global(qos: .userInitiated).async {
            self.session.startRunning()
        }
    }
    
    //    call this when study screen DISAPPEARS
    func stopSession() {
        session.stopRunning()
    }
}

// this extension receives each video frame
// right now its empty -- in step 4, vision code goes here
extension CameraViewModel: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didDrop sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
//        step 4 here;
    }
}

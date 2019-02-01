//
//  RecordARDelegate.swift
//  AR Video
//
//  Created by Ahmed Bekhit on 10/18/17.
//  Copyright © 2017 Ahmed Fathi Bekhit. All rights reserved.
//

@available(iOS 11.0, *)
// Delegate method for ARRecorder
@objc public protocol ARRecorderDelegate {
    // Returns a path to the recorded video,
    // noError will be false if error occurred while recording
    // should handle deleting broken video at path
    func recorder(didEndRecording path: URL, with noError: Bool)
    // Gets called if some error ocurred at any time
    // May get called concurrently with didEndRecording
    func recorder(didFailRecording error: Error?)
}

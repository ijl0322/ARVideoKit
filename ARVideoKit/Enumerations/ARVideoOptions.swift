//
//  ARVideoOptions.swift
//  AR Video
//
//  Created by Ahmed Bekhit on 10/18/17.
//  Copyright © 2017 Ahmed Fathi Bekhit. All rights reserved.
//

import Foundation
/// An object that returns the AR recorder current status.
@objc public enum RecordARStatus: Int {
    /// The current status of the recorder is unknown.
    case unknown
    /// The current recorder is ready to record.
    case readyToRecord
    /// The current recorder is recording.
    case recording
    /// The current recorder is paused.
    case paused
}

/// An object that returns the current Microphone status.
@objc public enum RecordARMicrophoneStatus: Int {
    // The current status of the Microphone access is unknown.
    case unknown
    // The current status of the Microphone access is enabled.
    case enabled
    // The current status of the Microphone access is disabled.
    case disabled
}

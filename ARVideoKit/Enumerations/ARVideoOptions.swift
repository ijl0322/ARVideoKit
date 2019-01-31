//
//  ARVideoOptions.swift
//  AR Video
//
//  Created by Ahmed Bekhit on 10/18/17.
//  Copyright © 2017 Ahmed Fathi Bekhit. All rights reserved.
//

import Foundation
/// An object that returns the AR recorder current status.
@objc public enum ARRecorderStatus: Int {
    case unknown
    case readyToRecord
    case recording
    case paused
}

/// An object that returns the current Microphone status.
@objc public enum ARRecorderMicrophoneStatus: Int {
    case unknown
    case enabled
    case disabled
}

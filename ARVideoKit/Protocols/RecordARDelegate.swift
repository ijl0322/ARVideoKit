//
//  RecordARDelegate.swift
//  AR Video
//
//  Created by Ahmed Bekhit on 10/18/17.
//  Copyright © 2017 Ahmed Fathi Bekhit. All rights reserved.
//

import Foundation
import CoreVideo
import CoreMedia
import ARKit

/**
 The recorder protocol.
 
 - Author: Ahmed Fathi Bekhit
 * [Github](http://github.com/AFathi)
 * [Website](http://ahmedbekhit.com)
 * [Twitter](http://twitter.com/iAFapps)
 * [Email](mailto:me@ahmedbekhit.com)
 */
@available(iOS 11.0, *)
@objc public protocol ARRecorderDelegate {
    func recorder(didEndRecording path: URL, with noError: Bool)
    func recorder(didFailRecording error: Error?)
}

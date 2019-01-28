//
//  ARInputViewOptions.swift
//  AR Video
//
//  Created by Ahmed Bekhit on 10/18/17.
//  Copyright © 2017 Ahmed Fathi Bekhit. All rights reserved.
//

import UIKit


/// Allows specifying which subviews will rotate in a `UIViewController` with AR scenes.
public enum ARInputViewOrientationMode {
    /// The framework automatically detects and rotates key objects in a `UIViewController`.
    case auto
    /// Rotates all objects in a `UIViewController`.
    case all
    /// Rotates manually specified `UIView` subviews in a `UIViewController`.
    case manual(subviews:[UIView])
    /// Disables rotating any objects in a `UIViewController`.
    case disabled
}


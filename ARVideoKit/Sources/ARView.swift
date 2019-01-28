//
//  ARView.swift
//  ARVideoKit
//
//  Created by Ahmed Bekhit on 10/14/17.
//  Copyright © 2017 Ahmed Fathi Bekhit. All rights reserved.
//

import UIKit
import ARKit

/**
 A class that configures the Augmented Reality View orientations.
 
 - Author: Ahmed Fathi Bekhit
 * [Github](http://github.com/AFathi)
 * [Website](http://ahmedbekhit.com)
 * [Twitter](http://twitter.com/iAFapps)
 * [Email](mailto:me@ahmedbekhit.com)
 */
@available(iOS 11.0, *)
@objc public class ARView: NSObject {
    private var parentVC: UIViewController?
    private var recentAngle = 0
    
    private var ivom: ARInputViewOrientationMode = .auto
    /// An object that allow customizing which subviews will rotate in a `UIViewController` that contains Augmented Reality scenes.
    public var inputViewOrientationMode: ARInputViewOrientationMode {
        get{
            return ivom
        }
        set{
            ivom = newValue
        }
    }
    
    
    @objc init?(ARSceneKit: ARSCNView) {
        super.init()
        
        let value = UIInterfaceOrientation.portrait.rawValue
        UIDevice.current.setValue(value, forKey: "orientation")
        
        ViewAR.orientation = .portrait
        
        guard let vc = ARSceneKit.parent else {
            return
        }
        
        parentVC = vc
    }
}

//
//  RenderAR.swift
//  ARVideoKit
//
//  Created by Ahmed Bekhit on 1/7/18.
//  Copyright © 2018 Ahmed Fathit Bekhit. All rights reserved.
//

import Foundation
import ARKit

@available(iOS 11.0, *)
//Use SCNRenderer to generate CVPixelBuffer from current SCNScene
struct ARSCNBufferRenderer {
    private var view: Any?
    private var renderEngine: SCNRenderer!
    init(_ ARview: Any?, renderer: SCNRenderer) {
        view = ARview
        renderEngine = renderer
    }
    
    let pixelsQueue = DispatchQueue(label: "com.littlstar.ARPixelsQueue", attributes: .concurrent)
    var time: CFTimeInterval { return CACurrentMediaTime()}
    var rawBuffer: CVPixelBuffer? {
        if let view = view as? ARSCNView {
            guard let rawBuffer = view.session.currentFrame?.capturedImage else { return nil }
            return rawBuffer
        }
        return nil
    }
    
    var bufferSize: CGSize? {
        guard rawBuffer != nil else { return nil }
        // Aspect Fill Videos
        let width = Int(UIScreen.main.nativeBounds.width)
        let height = Int(UIScreen.main.nativeBounds.height)
      
        // Take device orientation change into account
        if width > height {
            return CGSize(width: height, height: width)
        } else {
            return CGSize(width: width, height: height)
        }
    }
    
    var buffer: CVPixelBuffer? {
        if view is ARSCNView {
            guard let size = bufferSize else { return nil }
            var renderedFrame: UIImage?
            pixelsQueue.sync {
                renderedFrame = renderEngine.snapshot(atTime: self.time, with: size, antialiasingMode: .none)
            }
            if renderedFrame != nil {
              return renderedFrame!.buffer
            }
        }
        return nil
    }
}

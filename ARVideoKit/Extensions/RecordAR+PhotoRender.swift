//
//  RecordAR+PhotoRender.swift
//  AR Video
//
//  Created by Ahmed Bekhit on 10/27/17.
//  Copyright © 2017 Ahmed Fathi Bekhit. All rights reserved.
//

import AVFoundation
import Photos

@available(iOS 11.0, *)
extension RecordAR {
    
    func adjustTime(current: CMTime, resume: CMTime, pause: CMTime) -> CMTime {
        return CMTimeSubtract(current, CMTimeSubtract(resume, pause))
    }
    
    func imageFromBuffer(buffer: CVPixelBuffer) -> UIImage {
        let coreImg = CIImage(cvPixelBuffer: buffer)
        let context = CIContext()
        let cgImg = context.createCGImage(coreImg, from: coreImg.extent)
        let rotationAngle: CGFloat = 0
        return UIImage(cgImage: cgImg!).rotate(by: rotationAngle, flip: false)
    }
    
    @objc func appWillEnterBackground() {
        delegate?.recorder(willEnterBackground: status)
    }
}

extension FloatingPoint {
    var degreesToRadians: Self { return self * .pi / 180 }
}

//
//  RecordAR.swift
//  ARVideoKit
//
//  Created by Ahmed Bekhit on 10/18/17.
//  Copyright © 2017 Ahmed Fathi Bekhit. All rights reserved.
//

import UIKit
import Metal
import ARKit
import Photos
import PhotosUI

@available(iOS 11.0, *)
@objc public class ARRecorder: NSObject {
    @objc public weak var delegate: ARRecorderDelegate?
    @objc public internal(set)var status: ARRecorderStatus = .unknown
    @objc public internal(set)var micStatus: ARRecorderMicrophoneStatus = .unknown
    private var view: Any?
    private var renderEngine: SCNRenderer!
    private var gpuLoop: CADisplayLink!
    private var isResting = false
    private var renderer: ARSCNBufferRenderer!
  
    @objc public init?(ARSceneKit: ARSCNView) {
        super.init()
        view = ARSceneKit
        setup()
    }
  
    let writerQueue = DispatchQueue(label:"com.littlstar.ARWriterQueue")
    let audioSessionQueue = DispatchQueue(label: "com.littlstar.ARAudioSessionQueue", attributes: .concurrent)
  
    private var scnView: SCNView!
    var isRecording = false
    var currentVideoPath: URL?
    var writer: ARAssetWriter?
  
    //Generate a video path in Temp directory
    //Video may be delete by system after app termination.
    var newVideoPath: URL {
        return URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true).appendingPathComponent(UUID().uuidString).appendingPathExtension("mp4")
    }
  
    func setup() {
        if let view = view as? ARSCNView {
            guard let mtlDevice = MTLCreateSystemDefaultDevice() else {
                return
            }
            renderEngine = SCNRenderer(device: mtlDevice, options: nil)
            renderEngine.scene = view.scene
            renderEngine.autoenablesDefaultLighting = true
            
            gpuLoop = CADisplayLink(target: self, selector: #selector(renderFrame))
            gpuLoop.preferredFramesPerSecond = 0 // Let GPU decide what framerate to use
            gpuLoop.add(to: .main, forMode: .commonModes)
            status = .readyToRecord
        }
        renderer = ARSCNBufferRenderer(view, renderer: renderEngine)
    }
  
    @objc public func record() {
        writerQueue.sync {
            if micStatus == .unknown {
                self.requestMicrophonePermission { _ in
                    self.isRecording = true
                    self.status = .recording
                }
            } else {
                self.isRecording = true
                self.status = .recording
            }
        }
    }

    @objc public func stop(_ finished:((_ videoPath: URL) -> Swift.Void)? = nil) {
        writerQueue.sync {
            isRecording = false            
            DispatchQueue.main.async {
                self.writer?.end {
                    if let path = self.currentVideoPath {
                        finished?(path)
                        self.delegate?.recorder(didEndRecording: path, with: true)
                        self.status = .readyToRecord
                    } else {
                        self.status = .readyToRecord
                        self.delegate?.recorder(didFailRecording: errSecDecode as? Error)
                    }
                    self.writer = nil
                }
            }
        }
    }

    @objc public func requestMicrophonePermission(_ finished: ((_ status: Bool) -> Swift.Void)? = nil) {
        AVAudioSession.sharedInstance().requestRecordPermission({ permitted in
            finished?(permitted)
            if permitted {
                self.micStatus = .enabled
            } else {
                self.micStatus = .disabled
            }
        })
    }
}

//MARK: - Public methods for setting up UIViewController orientations
@available(iOS 11.0, *)
@objc public extension ARRecorder {
    /**
     A method that prepares the video recorder with `ARConfiguration` 📝.
     
     Recommended to use in the `UIViewController`'s method `func viewWillAppear(_ animated: Bool)`
     - parameter configuration: An object that defines motion and scene tracking behaviors for the session.
    */
    @objc public func prepare(_ configuration: ARConfiguration? = nil) {
        if let view = view as? ARSCNView {
            
            //try resetting anchors for the initial landscape orientation issue.
            guard let config = configuration else { return }
            view.session.run(config)
        }
    }
}

//MARK: - AR Video Frames Rendering
@available(iOS 11.0, *)
extension ARRecorder {
    @objc func renderFrame() {
        guard let buffer = renderer.buffer else { return }
        guard let size = renderer.bufferSize else { return }

        self.writerQueue.sync {
            var time: CMTime { return CMTimeMakeWithSeconds(renderer.time, 1000000) }
            if self.isRecording {
                // Have a writer already, continue writing to previous writer
                if let frameWriter = self.writer {
                    let finalFrameTime = time
                    frameWriter.insert(pixel: buffer, with: finalFrameTime)
                    
                    guard let isWriting = frameWriter.isWritingWithoutError else { return }
                    if !isWriting {
                        self.isRecording = false
                        self.status = .readyToRecord
                        self.delegate?.recorder(didFailRecording: errSecDecode as? Error)
                        // failed to write video buffer, pass video path to delegate to handle removing video
                        self.delegate?.recorder(didEndRecording: self.currentVideoPath!, with: false)
                    }
                } else {
                    self.currentVideoPath = self.newVideoPath
                    self.writer = ARAssetWriter(output: self.currentVideoPath!, width: Int(size.width), height: Int(size.height), queue: self.writerQueue)
                    self.writer?.delegate = self.delegate
                }
            }
        }
    }
}

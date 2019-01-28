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

private var view: Any?
private var renderEngine: SCNRenderer!
private var gpuLoop: CADisplayLink!
private var isResting = false
@available(iOS 11.0, *)
private var renderer: RenderAR!
/**
 This class renders the `ARSCNView` or `ARSKView` content with the device's camera stream to generate a video 📹, photo 🌄, live photo 🎇 or GIF 🎆.

 - Author: 🤓 Ahmed Fathi Bekhit © 2017
 * [Github](http://github.com/AFathi)
 * [Website](http://ahmedbekhit.com)
 * [Twitter](http://twitter.com/iAFapps)
 * [Email](mailto:me@ahmedbekhit.com)
 */
@available(iOS 11.0, *)
@objc public class RecordAR: NSObject {
    //MARK: - Public objects to configure RecordAR
    /**
     An object that passes the AR recorder errors and status in the protocol methods.
     */
    @objc public weak var delegate: RecordARDelegate?
    /**
     An object that passes the AR rendered content in the protocol method.
     */
    @objc public weak var renderAR: RenderARDelegate?
    /**
     An object that returns the AR recorder current status.
     */
    @objc public internal(set)var status: RecordARStatus = .unknown
    /**
     An object that returns the current Microphone status.
     */
    @objc public internal(set)var micStatus: RecordARMicrophoneStatus = .unknown

    /**
     A boolean that enables or disables adjusting captured GIFs for sharing online. Default is `true`.
     */
    
    //MARK: - Public initialization methods
    /**
     Initialize 🌞🍳 `RecordAR` with an `ARSCNView` 🚀.
     */
    @objc public init?(ARSceneKit: ARSCNView) {
        super.init()
        view = ARSceneKit
        setup()
    }
    
    //MARK: - threads
    let writerQueue = DispatchQueue(label:"com.ahmedbekhit.WriterQueue")
    let audioSessionQueue = DispatchQueue(label: "com.ahmedbekhit.AudioSessionQueue", attributes: .concurrent)
    
    //MARK: - Objects
    private var scnView: SCNView!
    private var fileCount = 0

    var isRecording = false
    //Used to locate the path of the video recording
    var currentVideoPath: URL?
    //Used to locate the path of the audio recording
    var currentAudioPath: URL?
    //Used to initialize the video writer
    var writer: WritAR?
    //Used to generate a new video path
    var newVideoPath: URL {
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documentsDirectory = paths[0]
        
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .full
        formatter.dateFormat = "yyyy-MM-dd'@'HH-mm-ssZZZZ"

        let date = Date(timeIntervalSince1970: Date().timeIntervalSince1970)
        
        let vidPath = "\(documentsDirectory)/\(formatter.string(from: date))ARVideo.mp4"
        return URL(fileURLWithPath: vidPath, isDirectory: false)
    }
    
    //MARK: - Video Setup
    func setup() {
        if let view = view as? ARSCNView {
            guard let mtlDevice = MTLCreateSystemDefaultDevice() else {
                logAR.message("ERROR:- This device does not support Metal")
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
      
        
        renderer = RenderAR(view, renderer: renderEngine)

        NotificationCenter.default.addObserver(self, selector: #selector(appWillEnterBackground), name: Notification.Name.UIApplicationWillResignActive, object: nil)
    }
  

    ///A method that starts or resumes ⏯ recording a video 📹.
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

    /**
     A method that pauses recording a video ⏸📹.
     
     In order to resume recording, simply call the `record()` method.
     */

    /**
     A method that stops ⏹ recording a video 📹 and exports it to the Photo Library 📲💾.
     
     - parameter finished: A block that will be called when the export process is complete.
     
        The block returns the following parameters:
     
        `videoPath`
        A `URL` object that contains the local file path of the video to allow manual exporting or preview of the video.
     
        `permissionStatus`
        A `PHAuthorizationStatus` object that returns the current application's status for exporting media to the Photo Library.
     
        `exported`
        A boolean that returns `true` when a video is successfully exported to the Photo Library. Otherwise, it returns `false`.
     */
    @objc public func stopAndExport(_ finished: ((_ videoPath: URL, _ permissionStatus: PHAuthorizationStatus, _ exported: Bool) -> Swift.Void)? = nil) {
        writerQueue.sync {
            self.isRecording = false
            self.writer?.end {
                if let path = self.currentVideoPath {
                    self.export(video: path) { exported, status in
                        finished?(path, status, exported)
                    }
                    self.delegate?.recorder(didEndRecording: path, with: true)
                    self.status = .readyToRecord
                } else {
                    finished?(self.currentVideoPath!, .notDetermined, false)
                    self.status = .readyToRecord
                    self.delegate?.recorder(didFailRecording: errSecDecode as? Error, and: "An error occured while stopping your video.")
                }
                self.writer = nil
            }
        }
    }
    /**
     A method that stops ⏹ recording a video 📹 and returns the video path in the completion handler.
     
     - parameter finished: A block that will be called when the specified `duration` has ended.
     
        The block returns the following parameter:
     
        `videoPath`
        A `URL` object that contains the local file path of the video to allow manual exporting or preview of the video.
     */
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
                        self.delegate?.recorder(didFailRecording: errSecDecode as? Error, and: "An error occured while stopping your video.")
                    }
                    self.writer = nil
                }
            }
        }
    }
    /**
     A method that exports a video 📹 file path to the Photo Library 📲💾.
     
     - parameter path: A `URL` object that can be set to a local video file path to export to the Photo Library.

     - parameter finished: A block that will be called when the export process is complete.
     
        The block returns the following parameters:
     
        `exported`
        A boolean that returns `true` when a video is successfully exported to the Photo Library. Otherwise, it returns `false`.
     
        `permissionStatus`
        A `PHAuthorizationStatus` object that returns the current application's status for exporting media to the Photo Library.
     */
    @objc public func export(video path: URL, _ finished: ((_ exported: Bool, _ permissionStatus: PHAuthorizationStatus) -> Void)? = nil) {
        audioSessionQueue.async {
            let status = PHPhotoLibrary.authorizationStatus()
            if status == .notDetermined {
                PHPhotoLibrary.requestAuthorization() { status in
                    // Recursive call after authorization request
                    self.export(video: path, finished)
                }
            } else if status == .authorized {
                PHPhotoLibrary.shared().performChanges({
                    PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: path)
                }) { saved, error in
                    if saved {
                        logAR.remove(from: path)
                    }
                    finished?(saved, status)
                }
            } else if status == .denied || status == .restricted {
                finished?(false, status)
            }
        }
    }
    /**
     A method that exports any image 🌄/🎆 (including gif, jpeg, and png) to the Photo Library 📲💾.
     
     - parameter path: A `URL` object that can be set to a local image file path to export to the Photo Library.
     - parameter UIImage: A `UIImage` object.
     - parameter finished: A block that will be called when the export process is complete.
     
        The block returns the following parameters:
     
        `exported`
        A boolean that returns `true` when an image is successfully exported to the Photo Library. Otherwise, it returns `false`.
     
        `permissionStatus`
        A `PHAuthorizationStatus` object that returns the current application's status for exporting media to the Photo Library.
     */
    @objc public func export(image path: URL? = nil, UIImage: UIImage? = nil, _ finished: ((_ exported: Bool, _ permissionStatus: PHAuthorizationStatus) -> Void)? = nil) {
        let status = PHPhotoLibrary.authorizationStatus()
        if status == .notDetermined {
            PHPhotoLibrary.requestAuthorization() { status in
                // Recursive call after authorization request
                self.export(image: path, UIImage: UIImage, finished)
            }
        } else if status == .authorized {
            PHPhotoLibrary.shared().performChanges({
                if let path = path {
                    PHAssetChangeRequest.creationRequestForAssetFromImage(atFileURL: path)
                } else if let image = UIImage {
                    PHAssetChangeRequest.creationRequestForAsset(from: image)
                }
            }) { saved, error in
                if saved {
                    if let path = path {
                        logAR.remove(from: path)
                    }
                }
                finished?(saved, status)
            }
        } else if status == .denied || status == .restricted {
            finished?(false, status)
        }
    }

    
    /**
     A method that requsts microphone 🎙 permission manually, if micPermission is set to `manual`.
     - parameter finished: A block that will be called when the audio permission is requested.
     
     The block returns the following parameter:
     
     `status`
     A boolean that returns `true` when a the Microphone access is permitted. Otherwise, it returns `false`.
     */
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
@objc public extension RecordAR {
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
extension RecordAR {
    @objc func renderFrame() {
        //frame rendering

        guard let buffer = renderer.buffer else { return }
        guard let rawBuffer = renderer.rawBuffer else {
            logAR.message("ERROR:- An error occurred while rendering the camera's main buffers.")
            return
        }
        guard let size = renderer.bufferSize else {
            logAR.message("ERROR:- An error occurred while rendering the camera buffer.")
            return
        }

        self.writerQueue.sync {
            var time: CMTime { return CMTimeMakeWithSeconds(renderer.time, 1000000) }
            
            self.renderAR?.frame(didRender: buffer, with: time, using: rawBuffer)
            
            //frame writing
            if self.isRecording {
                if let frameWriter = self.writer {
                    let finalFrameTime = time
                    frameWriter.insert(pixel: buffer, with: finalFrameTime)
                    
                    guard let isWriting = frameWriter.isWritingWithoutError else { return }
                    if !isWriting {
                        self.isRecording = false
                        
                        self.status = .readyToRecord
                        self.delegate?.recorder(didFailRecording: errSecDecode as? Error, and: "An error occured while recording your video.")
                        self.delegate?.recorder(didEndRecording: self.currentVideoPath!, with: false)
                    }
                } else {
                    self.currentVideoPath = self.newVideoPath
                    
                    self.writer = WritAR(output: self.currentVideoPath!, width: Int(size.width), height: Int(size.height), queue: self.writerQueue)
                    self.writer?.delegate = self.delegate
                }
            }
        }
    }
}

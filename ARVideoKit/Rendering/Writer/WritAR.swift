//
//  WritAR.swift
//  AR Video
//
//  Created by Ahmed Bekhit on 10/19/17.
//  Copyright © 2017 Ahmed Fathi Bekhit. All rights reserved.
//

import AVFoundation
import CoreImage
import UIKit

@available(iOS 11.0, *)
class ARAssetWriter: NSObject, AVCaptureAudioDataOutputSampleBufferDelegate {
    private var assetWriter: AVAssetWriter!
    private var videoInput: AVAssetWriterInput!
    private var audioInput: AVAssetWriterInput!
    private var session: AVCaptureSession!
    
    private var pixelBufferInput: AVAssetWriterInputPixelBufferAdaptor!
    private var videoOutputSettings: Dictionary<String, AnyObject>!
    private var audioSettings: [String: Any]?

    let audioBufferQueue = DispatchQueue(label: "com.littlstar.ARAudioBufferQueue")

    private var isRecording: Bool = false
    
    var delegate: ARRecorderDelegate?

    init(output: URL, width: Int, height: Int, queue: DispatchQueue) {
        super.init()
        do {
            assetWriter = try AVAssetWriter(outputURL: output, fileType: AVFileType.mp4)
        } catch {
          print("An error occurred while intializing an AVAssetWriter")
          return
        }
      
        // Enable background audio recording
        // Need this configuration for recording sounds from HCAP nodes!!
        let audioOptions: AVAudioSessionCategoryOptions = [.mixWithOthers , .allowBluetooth, .defaultToSpeaker, .interruptSpokenAudioAndMixWithOthers]
        try? AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayAndRecord, with: audioOptions)
        try? AVAudioSession.sharedInstance().setActive(true)
        AVAudioSession.sharedInstance().requestRecordPermission({ permitted in
          if permitted {
            self.prepareAudioDevice(with: queue)
          }
        })
        
        videoOutputSettings = [
            AVVideoCodecKey: AVVideoCodecType.h264 as AnyObject,
            AVVideoWidthKey: width as AnyObject,
            AVVideoHeightKey: height as AnyObject
        ]
      
        videoInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoOutputSettings)

        videoInput.expectsMediaDataInRealTime = true
        pixelBufferInput = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: videoInput, sourcePixelBufferAttributes: nil)
      
        let t = CGAffineTransform.identity
        videoInput.transform = t
        
        if assetWriter.canAdd(videoInput) {
            assetWriter.add(videoInput)
        } else {
            delegate?.recorder(didFailRecording: assetWriter.error)
            isWritingWithoutError = false
        }
    }
    
    func prepareAudioDevice(with queue: DispatchQueue) {
        let device: AVCaptureDevice = AVCaptureDevice.default(for: .audio)!
        var audioDeviceInput: AVCaptureDeviceInput?
        do {
            audioDeviceInput = try AVCaptureDeviceInput(device: device)
        } catch {
            audioDeviceInput = nil
        }
        
        let audioDataOutput = AVCaptureAudioDataOutput()
        audioDataOutput.setSampleBufferDelegate(self, queue: queue)

        session = AVCaptureSession()
        session.sessionPreset = .medium
        session.usesApplicationAudioSession = true
        session.automaticallyConfiguresApplicationAudioSession = false
        
        if session.canAddInput(audioDeviceInput!) {
            session.addInput(audioDeviceInput!)
        }
        
        if session.canAddOutput(audioDataOutput) {
            session.addOutput(audioDataOutput)
        }
      
        audioSettings = audioDataOutput.recommendedAudioSettingsForAssetWriter(writingTo: .m4v) as? [String: Any]
        
        audioInput = AVAssetWriterInput(mediaType: .audio, outputSettings: audioSettings)
        audioInput.expectsMediaDataInRealTime = true
        
        audioBufferQueue.async {
            self.session.startRunning()
        }
        
        if assetWriter.canAdd(audioInput) {
            assetWriter.add(audioInput)
        }
    }
    
    var startingVideoTime: CMTime?
    var isWritingWithoutError: Bool?
    
    func insert(pixel buffer: CVPixelBuffer, with intervals: CFTimeInterval) {
        let time: CMTime = CMTimeMakeWithSeconds(intervals, 1000000)
        if assetWriter.status == .unknown {
            guard startingVideoTime == nil else {
                isWritingWithoutError = false
                return
            }
            startingVideoTime = time
            if assetWriter.startWriting() {
                assetWriter.startSession(atSourceTime: startingVideoTime!)
                session.startRunning()
                isRecording = true
                isWritingWithoutError = true
            } else {
                delegate?.recorder(didFailRecording: assetWriter.error)
                isWritingWithoutError = false
            }
        } else if assetWriter.status == .failed {
            delegate?.recorder(didFailRecording: assetWriter.error)
            print("An error occurred while recording the video, status: \(assetWriter.status.rawValue), error: \(assetWriter.error!.localizedDescription)")
            isWritingWithoutError = false
            return
        }
        if videoInput.isReadyForMoreMediaData {
            append(pixel: buffer, with: time)
            isWritingWithoutError = true
        }
    }
    
    func insert(pixel buffer: CVPixelBuffer, with time: CMTime) {
        if assetWriter.status == .unknown {
            guard startingVideoTime == nil else {
                isWritingWithoutError = false
                return
            }
            startingVideoTime = time
            if assetWriter.startWriting() {
                assetWriter.startSession(atSourceTime: startingVideoTime!)
                isRecording = true
                isWritingWithoutError = true
            } else {
                delegate?.recorder(didFailRecording: assetWriter.error)
                isRecording = false
                isWritingWithoutError = false
            }
        } else if assetWriter.status == .failed {
            delegate?.recorder(didFailRecording: assetWriter.error)
            print("An error occurred while recording the video, status: \(assetWriter.status.rawValue), error: \(assetWriter.error!.localizedDescription)")
            isRecording = false
            isWritingWithoutError = false
            return
        }
        
        if videoInput.isReadyForMoreMediaData {
            append(pixel: buffer, with: time)
            isRecording = true
            isWritingWithoutError = true
        }
    }

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if let input = audioInput {
            audioBufferQueue.async { [weak self] in
                if input.isReadyForMoreMediaData && (self?.isRecording)! {
                    input.append(sampleBuffer)
                }
            }
        }
    }
        
    func end(writing finished: @escaping () -> Void){
        if let session = session {
            if session.isRunning {
                session.stopRunning()
            }
        }
        assetWriter.finishWriting(completionHandler: finished)
    }
  
    private func append(pixel buffer: CVPixelBuffer, with time: CMTime) {
      pixelBufferInput.append(buffer, withPresentationTime: time)
    }
}

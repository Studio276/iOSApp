//
//  RenderWings.swift
//  WhatLiftsYou
//
//  Created by Jessie Albarian on 3/9/17.
//  Copyright © 2017 Montague Art, LLC. All rights reserved.
//

import Foundation
import UIKit
import YYImage
import ImageIO
import MobileCoreServices
import CoreGraphics
import CoreImage
import AVFoundation



typealias CXEMovieMakerCompletion = (URL) -> Void
typealias CXEMovieMakerUIImageExtractor = (AnyObject) -> UIImage?

public class CXEImagesToVideo: NSObject{
    var assetWriter:AVAssetWriter!
    var writeInput:AVAssetWriterInput!
    var bufferAdapter:AVAssetWriterInputPixelBufferAdaptor!
    var videoSettings:[String : Any]!
    var frameTime:CMTime!
    var fileURL:URL!
    
    var completionBlock: CXEMovieMakerCompletion?
    var movieMakerUIImageExtractor:CXEMovieMakerUIImageExtractor?
    
    
    public class func videoSettings(codec:String, width:Int, height:Int) -> [String: Any]{
        if(Int(width) % 16 != 0){
        }
        
        let videoSettings:[String: Any] = [AVVideoCodecKey: codec,
                                           AVVideoWidthKey: width,
                                           AVVideoHeightKey: height]
        
        return videoSettings
    }
    
    public init(videoSettings: [String: Any]) {
        super.init()
        
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let tempPath = paths[0] + "/export.mp4"
        if(FileManager.default.fileExists(atPath: tempPath)){
            guard (try? FileManager.default.removeItem(atPath: tempPath)) != nil else {
//                print("remove path failed")
                return
            }
        }
        
        self.fileURL = URL(fileURLWithPath: tempPath)
        self.assetWriter = try! AVAssetWriter(url: self.fileURL, fileType: AVFileTypeQuickTimeMovie)
        
        self.videoSettings = videoSettings
        self.writeInput = AVAssetWriterInput(mediaType: AVMediaTypeVideo, outputSettings: videoSettings)
        assert(self.assetWriter.canAdd(self.writeInput), "add failed")
        
        self.assetWriter.add(self.writeInput)
        let bufferAttributes:[String: Any] = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32ARGB)]
        self.bufferAdapter = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: self.writeInput, sourcePixelBufferAttributes: bufferAttributes)
        self.frameTime = CMTimeMake(1, 10)
    }
    
    func createMovieFrom(urls: [URL], withCompletion: @escaping CXEMovieMakerCompletion){
        self.createMovieFromSource(images: urls as [AnyObject], extractor:{(inputObject:AnyObject) ->UIImage? in
            return UIImage(data: try! Data(contentsOf: inputObject as! URL))}, withCompletion: withCompletion)
    }
    
    func createMovieFrom(images: [UIImage], withCompletion: @escaping CXEMovieMakerCompletion){
        self.createMovieFromSource(images: images, extractor: {(inputObject:AnyObject) -> UIImage? in
            return inputObject as? UIImage}, withCompletion: withCompletion)
    }
    
    func createMovieFromSource(images: [AnyObject], extractor: @escaping CXEMovieMakerUIImageExtractor, withCompletion: @escaping CXEMovieMakerCompletion){
        self.completionBlock = withCompletion
        
        self.assetWriter.startWriting()
        self.assetWriter.startSession(atSourceTime: kCMTimeZero)
        
        let mediaInputQueue = DispatchQueue(label: "mediaInputQueue")
        var i = 0
        let frameNumber = images.count
        
        self.writeInput.requestMediaDataWhenReady(on: mediaInputQueue){
            while(true){
                if(i >= frameNumber){
                    break
                }
                
                if (self.writeInput.isReadyForMoreMediaData){
                    var sampleBuffer:CVPixelBuffer?
                    autoreleasepool{
                        let img = extractor(images[i])
                        if img == nil{
                            i += 1
//                            print("Warning: counld not extract one of the frames")
                            //continue
                        }
                        sampleBuffer = self.newPixelBufferFrom(cgImage: img!.cgImage!)
                    }
                    if (sampleBuffer != nil){
                        if(i == 0){
                            self.bufferAdapter.append(sampleBuffer!, withPresentationTime: kCMTimeZero)
                        }else{
                            let value = i - 1
                            let lastTime = CMTimeMake(Int64(value), self.frameTime.timescale)
                            let presentTime = CMTimeAdd(lastTime, self.frameTime)
                            self.bufferAdapter.append(sampleBuffer!, withPresentationTime: presentTime)
                        }
                        i = i + 1
                    }
                }
            }
            self.writeInput.markAsFinished()
            self.assetWriter.finishWriting {
                DispatchQueue.main.sync {
                    self.completionBlock!(self.fileURL)
                }
            }
        }
    }
    
    func newPixelBufferFrom(cgImage:CGImage) -> CVPixelBuffer?{
        let options:[String: Any] = [kCVPixelBufferCGImageCompatibilityKey as String: true, kCVPixelBufferCGBitmapContextCompatibilityKey as String: true]
        var pxbuffer:CVPixelBuffer?
        let frameWidth = self.videoSettings[AVVideoWidthKey] as! Int
        
        
        let frameHeight = self.videoSettings[AVVideoHeightKey] as! Int
    
        let status = CVPixelBufferCreate(kCFAllocatorDefault, frameWidth, frameHeight, kCVPixelFormatType_32ARGB, options as CFDictionary?, &pxbuffer)
        assert(status == kCVReturnSuccess && pxbuffer != nil, "newPixelBuffer failed")
        
        CVPixelBufferLockBaseAddress(pxbuffer!, CVPixelBufferLockFlags(rawValue: 0))
        let pxdata = CVPixelBufferGetBaseAddress(pxbuffer!)
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(data: pxdata, width: frameWidth, height: frameHeight, bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(pxbuffer!), space: rgbColorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue)
//        CGImageAlphaInfo.noneSkipFirst.rawValue
        assert(context != nil, "context is nil")
        
        context!.concatenate(CGAffineTransform.identity)
        context!.draw(cgImage, in: CGRect(x: 0, y: 0, width: cgImage.width, height: cgImage.height))
        CVPixelBufferUnlockBaseAddress(pxbuffer!, CVPixelBufferLockFlags(rawValue: 0))
        return pxbuffer
    }
}


/**
 * Takes a path to a local gif containing an animation for a set of wings
 * and renders a new gif of them composited over the background image.
 * Returns the path to the rendered gif.
 */

//let globalQueue = DispatchQueue.main
//let globalQueue = DispatchQueue.global(qos: .background)

func render(wingsAtUrl: URL, over backgroundImage: UIImageView, with wingsView: WingsView, completionHandler: @escaping ((_ data: [UIImage]) -> Void)) {
    var uiImages = [UIImage]()
    if let gifData = NSData(contentsOf: wingsAtUrl) as Data? {
        let decoder = YYImageDecoder(data: gifData, scale: 1)!
        
        // Hide movers on wings view
        let wereWingMoversHidden = wingsView.areWingMoversHidden
        let currentWingsImage = wingsView.wingsImage
        wingsView.areWingMoversHidden = true
        
        for frameNumber in 0 ... decoder.frameCount - 1 {
            
            var renderedFrame = UIImage()
            
            // decode the frame of the animation from the source and render it onto the image
            let frame = decoder.frame(at: frameNumber, decodeForDisplay: true)!.image
            
            wingsView.wingsImage = frame
            renderedFrame = render(uiView: backgroundImage)
            
            
            // Add frames to array for movie creation
            uiImages.append(renderedFrame)
        }
        
        uiImages = uiImages + uiImages
        // restore wings view state
        wingsView.areWingMoversHidden = wereWingMoversHidden
        wingsView.wingsImage = currentWingsImage
        
        completionHandler(uiImages)
    }
}



/**
 * Renders the given UIView as a UIImage
 */
func render(uiView: UIView) -> UIImage {
    var renderedImage = UIImage()
    if #available(iOS 10.0, *) {
        let renderer = UIGraphicsImageRenderer(size: uiView.bounds.size)
        renderedImage = renderer.image { ctx in
            uiView.drawHierarchy(in: uiView.bounds, afterScreenUpdates: true)
        }
    } else {
        // Fallback on earlier versions
        UIGraphicsBeginImageContextWithOptions(uiView.bounds.size, false, 0.0)
        uiView.drawHierarchy(in: uiView.bounds, afterScreenUpdates: true)
        renderedImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
    }
    return renderedImage
}


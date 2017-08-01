//
//  ViewController.swift
//  WhatLiftsYou
//
//  Created by Jessie Albarian on 3/6/17.
//  Copyright © 2017 Montague Art, LLC. All rights reserved.
//

import UIKit
import AVFoundation
import Photos
import MobileCoreServices


class CameraViewController: UIViewController, UIGestureRecognizerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    
    var captureSession = AVCaptureSession()
    var stillImageOutput: AVCaptureStillImageOutput?
    var previewLayer = AVCaptureVideoPreviewLayer()
    var input: AVCaptureDeviceInput?
    @IBOutlet weak var bottomView: UIView!
    var prevZoomFactor: CGFloat = 1
    @IBOutlet weak var frontCamera: UIImageView!
    @IBOutlet weak var capturePhotoBtn: UIImageView!
    let imagePicker = UIImagePickerController()
    
    
    var camera = true
    var check = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        NotificationCenter.default.addObserver(self, selector: #selector(willEnterForeground), name: .UIApplicationWillEnterForeground, object: nil)
        
        // CAMERA ZOOMING PINCH RECOGNIZER
        let pinchRecognizer = UIPinchGestureRecognizer(target: self, action:#selector(pinch(pinch:)))
        pinchRecognizer.delegate = self
        self.view.addGestureRecognizer(pinchRecognizer)
        
        // SWITCH CAMERA TO SELFIE MODE
        let tapSwitchCamera = UITapGestureRecognizer(target:self, action:#selector(switchCamera))
        frontCamera.isUserInteractionEnabled = true
        frontCamera.addGestureRecognizer(tapSwitchCamera)
        
        // CAPTURE PHOTO
        let capture = UITapGestureRecognizer(target:self, action:#selector(capturePhoto))
        capturePhotoBtn.isUserInteractionEnabled = true
        capturePhotoBtn.addGestureRecognizer(capture)
        
//        willEnterForeground()
        
        imagePicker.delegate = self
        self.checkCamera(completionHandler: { () -> Void in
            self.checkGallery()
            self.startCamera()
        })
    }
    
    func willEnterForeground() {
        // Check authorization
//        DispatchQueue.main.async{
            self.checkCamera(completionHandler: { () -> Void in
                self.checkGallery()
                self.startCamera()
            })
//        }
//        DispatchQueue.main.async(execute: {
//            self.startCamera()
//        })
    }
    
//    override func viewWillAppear(_ animated: Bool) {
//        super.viewWillAppear(animated)
//        
//        self.checkCamera(completionHandler: { () -> Void in
//            self.checkGallery()
//            self.startCamera()
//        })
//        
//    }
    

    
    @IBAction func showAlbums(_ sender: Any) {
        
        imagePicker.sourceType = UIImagePickerControllerSourceType.photoLibrary
        imagePicker.mediaTypes = [(kUTTypeImage as NSString) as String]
        imagePicker.allowsEditing = true
        
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.photoLibrary) {
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.sourceType = UIImagePickerControllerSourceType.photoLibrary;
            imagePicker.allowsEditing = true
            self.present(imagePicker, animated: true, completion: nil)
        }
    }

    
    //---------------------
    // User cancels gallery
    //---------------------
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        self.dismiss(animated: true, completion: nil)
    }
    
    
    //-------------
    // Image picker
    //-------------
    //NOT GETTING IN HERE
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String: Any]) {
        let VC1 = self.storyboard!.instantiateViewController(withIdentifier: "wings") as! WingsViewController
        let navController = UINavigationController(rootViewController: VC1)
        if let image = info[UIImagePickerControllerEditedImage] as? UIImage {
            VC1.selectedImage = image
        } else{
            print("Something went wrong")
        }

        // Dismiss the picker.
        dismiss(animated: true, completion: nil)
        self.present(navController, animated: true, completion: nil)
    }
    
    
    //------------------------------
    // Check if camera is authorized
    //------------------------------
    func checkCamera(completionHandler: @escaping () -> Void) {
        
        let authStatus = AVCaptureDevice.authorizationStatus(forMediaType: AVMediaTypeVideo)
        
        switch authStatus {
        case .authorized:
            completionHandler()
            break
            
        case .denied:
            let alert = UIAlertController(
                title: "IMPORTANT",
                message: "Camera access is required for capturing images",
                preferredStyle: UIAlertControllerStyle.alert
            )
            alert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: {(alert) -> Void in
                completionHandler()
            }))
            
            /*
             let settingsAction = UIAlertAction(title: "Settings", style: .Default) { (alertAction) in
             
             // THIS IS WHERE THE MAGIC HAPPENS!!!!
             if let appSettings = NSURL(string: UIApplicationOpenSettingsURLString) {
             UIApplication.sharedApplication().openURL(appSettings)
             }
             }*/
            
            alert.addAction(UIAlertAction(title: "Allow Camera", style: .cancel, handler: { (alert) -> Void in
                
                
                if let appSettings = NSURL(string: UIApplicationOpenSettingsURLString) {
                    if #available(iOS 10.0, *) {
                        print("10")
                        UIApplication.shared.open(appSettings as URL, options: [:], completionHandler: nil)
                    } else {
                        // Fallback on earlier versions
                        UIApplication.shared.openURL(appSettings as URL)
                    }
                }
            }))
            self.present(alert, animated: true, completion: nil)
            
        case .notDetermined:
            if AVCaptureDevice.devices(withMediaType: AVMediaTypeVideo).count > 0 {
                AVCaptureDevice.requestAccess(forMediaType: AVMediaTypeVideo) { granted in
                    self.checkCamera(completionHandler: {() -> Void in
                        completionHandler()
                    })
                }
            }
            
        default:
            let alert = UIAlertController(
                title: "IMPORTANT",
                message: "Please allow camera access for capturing images",
                preferredStyle: UIAlertControllerStyle.alert
            )
            alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel) { alert in
                if AVCaptureDevice.devices(withMediaType: AVMediaTypeVideo).count > 0 {
                    AVCaptureDevice.requestAccess(forMediaType: AVMediaTypeVideo) { granted in
                        self.checkCamera(completionHandler: { () -> Void in
                            completionHandler()
                        })
                        
                    }
                }
            })
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    
    //----------------------------
    // Check gallery authorization
    //----------------------------
    func checkGallery() {
        PHPhotoLibrary.requestAuthorization({(status:PHAuthorizationStatus) in
            switch status {
                
            case .authorized:
                break
                
            case .denied:
                
                DispatchQueue.main.async(execute: {
                    let alert = UIAlertController(
                        title: "IMPORTANT",
                        message: "Photo gallery access is required for capturing images",
                        preferredStyle: UIAlertControllerStyle.alert
                    )
                    
                    alert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: nil))
                    
                    alert.addAction(UIAlertAction(title: "Allow Gallery", style: .cancel, handler: { (alert) -> Void in
                        UIApplication.shared.openURL(NSURL(string: UIApplicationOpenSettingsURLString)! as URL)
                    }))
                    
                    self.present(alert, animated: true, completion: nil)
                })
                break
                
            default:
                break
            }
        })
    }
    
    
    
    func switchCamera(){
        camera = !camera
        startCamera()
    }
    
    
    //------------------
    // START CAMERA VIEW
    //------------------
    func startCamera(){
//        captureSession.stopRunning()
//        previewLayer.removeFromSuperlayer()
//        captureSession.removeInput(input)
        
        // camera loading code
        captureSession = AVCaptureSession()
        captureSession.sessionPreset = AVCaptureSessionPresetPhoto
        var captureDevice:AVCaptureDevice! = nil
        
        if (camera == false) {
            let videoDevices = AVCaptureDevice.devices(withMediaType: AVMediaTypeVideo)
            
            for device in videoDevices!{
                let device = device as! AVCaptureDevice
                if device.position == AVCaptureDevicePosition.front {
                    captureDevice = device
                    break
                }
            }
        } else {
            captureDevice = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo)
        }
        
        let error : NSError? = nil
        do {
            input = try AVCaptureDeviceInput(device: captureDevice)
            
        } catch {
            print(error)
        }
        
        if error == nil && captureSession.canAddInput(input) {
            captureSession.addInput(input)
            stillImageOutput = AVCaptureStillImageOutput()
            stillImageOutput!.outputSettings = [AVVideoCodecKey: AVVideoCodecJPEG]
            if captureSession.canAddOutput(stillImageOutput) {
                captureSession.addOutput(stillImageOutput)
                
//                previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
//                previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
//                previewLayer.connection?.videoOrientation = AVCaptureVideoOrientation.portrait
//                previewLayer.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height - bottomView.bounds.height)
//                previewLayer.zPosition = -1;
//                view.layer.addSublayer(previewLayer)
                DispatchQueue.global().async {
                    
                    self.captureSession.startRunning()
                    
                    DispatchQueue.main.async {
                        self.previewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
                        self.previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
                        self.previewLayer.connection?.videoOrientation = AVCaptureVideoOrientation.portrait
                        self.previewLayer.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height - self.bottomView.bounds.height)
                        self.previewLayer.zPosition = -1;
                        self.view.layer.addSublayer(self.previewLayer)
                    }
                }
            }
        }
    }
    
    
    //---------------
    // CAMERA ZOOMING
    //---------------
    func pinch(pinch: UIPinchGestureRecognizer) {
        
        var device: AVCaptureDevice = (self.input?.device)!
        var zoomFactor = pinch.scale * prevZoomFactor
        zoomFactor = zoomFactor < 1 ? 1 : zoomFactor
        
        if pinch.state == .ended {
            prevZoomFactor = zoomFactor >= 1 ? zoomFactor : 1
        }
        
        var error:NSError!
        do{
            try device.lockForConfiguration()
            defer {device.unlockForConfiguration()
            }
            
            if (zoomFactor <= device.activeFormat.videoMaxZoomFactor){
                
                device.videoZoomFactor = zoomFactor
                
            }else{
                
                NSLog("Unable to set videoZoom: (max %f, asked %f)", device.activeFormat.videoMaxZoomFactor, zoomFactor);
            }
            
        }catch error as NSError{
            
            NSLog("Unable to set videoZoom: %@", error.localizedDescription);
        }catch _{
            
            print("Pinch zoom failed")
        }
    }
    
    func capturePhoto(){
        if let videoConnection = stillImageOutput!.connection(withMediaType: AVMediaTypeVideo) {
            stillImageOutput?.captureStillImageAsynchronously(from: videoConnection, completionHandler: { (sampleBuffer, error) -> Void in
                if sampleBuffer != nil {
                    let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(sampleBuffer)
                    let dataProvider = CGDataProvider(data: imageData! as CFData)
                    let cgImageRef = CGImage(jpegDataProviderSource: dataProvider!, decode: nil, shouldInterpolate: true, intent: .defaultIntent)
                    let image : UIImage?
                    if self.camera == true {
                        image = UIImage(cgImage: cgImageRef!, scale: 1.0, orientation: UIImageOrientation.right)
                    } else {
                        image = UIImage(cgImage: cgImageRef!, scale: 1.0, orientation: UIImageOrientation.leftMirrored)
                    }
                    
                    let VC1 = self.storyboard!.instantiateViewController(withIdentifier: "wings") as! WingsViewController
                    let navController = UINavigationController(rootViewController: VC1)
                    VC1.selectedImage = image!
                    self.present(navController, animated: true, completion: nil)
                }
            })
        }
    }
    
    @IBAction func unwindToCamera(_ segue: UIStoryboardSegue){
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }


}


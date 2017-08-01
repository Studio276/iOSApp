//
//  ShareViewController.swift
//  WhatLiftsYou
//
//  Created by Jessie Albarian on 3/9/17.
//  Copyright © 2017 Montague Art, LLC. All rights reserved.
//

import UIKit
import AVFoundation
import MediaPlayer
import AssetsLibrary
import Social
import Photos
import FacebookShare
import TwitterKit
import Social
import SwiftSpinner
import Accounts
import FacebookCore
import FBSDKCoreKit



struct Services{
    static let saveToLibrary = "savetolib"
    static let facebook = "facebook"
    static let twitter = "twitter"
    static let instagram = "instagram"
}

class ShareViewController: UIViewController, TWTRComposerViewControllerDelegate, TwitterViewDelegate {


    
//    var wingObject = WingData(newName: "", newHash: "", newGif: "")
    var wingObject: WingData? = nil
    var videoURL: URL?
    var player:AVPlayer!
    var avPlayerLayer:AVPlayerLayer!
    
    var twitterView:TwitterView?
    
    // Saving/Sharing images
    @IBOutlet weak var saveToGallery: UIImageView!
    var savedImageId:String = ""
    var imageSavedImage = UIImageView()
    var imageSharedImage = UIImageView()
    @IBOutlet weak var facebook: UIImageView!
    @IBOutlet weak var share: UIImageView!
    @IBOutlet weak var insta: UIImageView!
    @IBOutlet weak var twitter: UIImageView!
    @IBOutlet weak var bottomView: UIView!
    
    let fbTap = UITapGestureRecognizer()
    let galleryTap = UITapGestureRecognizer()
    let twitterTap = UITapGestureRecognizer()
    let instaTap = UITapGestureRecognizer()
    
    var accountStore:ACAccountStore?
    var accountType:ACAccountType?
    
    var bottomViewHeight = NSLayoutConstraint()
    
    @IBOutlet weak var bottomViewHeightContraint: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        bottomViewHeightContraint = bottomViewHeight
        
        let playerFrame = CGRect(x: 0, y: self.navigationController!.navigationBar.frame.height + 5, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height - bottomView.frame.height - self.navigationController!.navigationBar.frame.height)
        
        player = AVPlayer(url: videoURL!)
        
        avPlayerLayer = AVPlayerLayer(player: player)
        avPlayerLayer.backgroundColor = UIColor.white.cgColor
        avPlayerLayer.frame = playerFrame
//        avPlayerLayer.videoGravity = AVLayerVideoGravityResize
        view.layer.addSublayer(avPlayerLayer)
        player.play()
//        NotificationCenter.default.addObserver(self, selector: #selector(playVideo), name: Notification.Name(rawValue: "com.whatliftsyou.continueVideo"), object: nil)
        
//        NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: self.player.currentItem, queue: nil, using: { (_) in
//            DispatchQueue.main.async {
//                self.player?.seek(to: kCMTimeZero)
//                self.player?.play()
//            }
//        })
        
        // Custom redo button
        let backBtn = UIButton(frame: CGRect(x: 0, y: 0, width: 70, height: 40))
        backBtn.setImage(UIImage(named: "backBtn"), for: UIControlState.normal)
        backBtn.imageView?.contentMode = UIViewContentMode.scaleAspectFit
        backBtn.addTarget(self, action: #selector(ShareViewController.redo), for: .touchUpInside)
        let item = UIBarButtonItem(customView: backBtn)
        self.navigationItem.leftBarButtonItem = item
        
        // Custom next button
        let nextBtn = UIButton(frame: CGRect(x: 0, y: 0, width: 120, height: 60))
        nextBtn.setImage(UIImage(named: "newCreationBtn"), for: UIControlState.normal)
        nextBtn.imageView?.contentMode = UIViewContentMode.scaleAspectFit
        nextBtn.addTarget(self, action: #selector(ShareViewController.startOver), for: .touchUpInside)
        let item2 = UIBarButtonItem(customView: nextBtn)
        self.navigationItem.rightBarButtonItem = item2
        

        
        // FB Share
        fbTap.addTarget(self, action: #selector(ShareViewController.handleFBTap))
        facebook.addGestureRecognizer(fbTap)
        
        // Twitter Share
        twitterTap.addTarget(self, action: #selector(ShareViewController.handleTwitterTap))
        twitter.addGestureRecognizer(twitterTap)
        
        // Instagram Share
        instaTap.addTarget(self, action: #selector(ShareViewController.handleInstagramTap))
        insta.addGestureRecognizer(instaTap)
        
        // Save to Gallery
        galleryTap.addTarget(self, action: #selector(ShareViewController.save))
        saveToGallery.addGestureRecognizer(galleryTap)
    }
    
    
    //--------
    // Go back
    //--------
    func redo() {
        _ = navigationController?.popViewController(animated: true)
    }
    
    //-----------
    // Start over
    //-----------
    func startOver() {
        self.dismiss(animated: true, completion: nil)
    }
    
    //----------------
    // Save to gallery
    //----------------
    func save() {
        saveImage(Services.saveToLibrary)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func applicationDidBecomeActive(application: UIApplication) {
        player.play()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated);
        savedImageId = ""
        NotificationCenter.default.addObserver(self, selector: #selector(playVideo), name: Notification.Name(rawValue: "com.whatliftsyou.continueVideo"), object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(false)
        NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: self.player.currentItem, queue: nil, using: { (_) in
            DispatchQueue.main.async {
                self.player?.seek(to: kCMTimeZero)
                self.player?.play()
            }
        })
    }
    
    func playVideo(){
        player.play()
    }
    
    func saveImage(_ service:String){
        
        PHPhotoLibrary.shared().performChanges({
            
            let assetReq = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: self.videoURL!)
            self.savedImageId = (assetReq?.placeholderForCreatedAsset?.localIdentifier)!
            
        }) { (success, error) in
            
            if(success){
                
                switch service{
                    
                case Services.facebook:
                    DispatchQueue.main.async{
                        self.showFacebook()
                    }
//                case Services.twitter:
//                    DispatchQueue.main.async{
////                        self.showTwitter()
//                    }
//                    
                case Services.instagram:
                    DispatchQueue.main.async{
                        self.showInstagram()
                    }
                default:
                    DispatchQueue.main.async{
                        self.showSavedImage()
                    }
                }
                
            }else{
                
                print("Error \(String(describing: error))")
                
                let alert = UIAlertController(title: "Error!", message: "There was an error saving to your photo library: \(String(describing: error?.localizedDescription))", preferredStyle: UIAlertControllerStyle.alert)
                alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
        }
    }
    
    //---------------------
    // Handle FB Button Tap
    //---------------------
    func handleFBTap(sender: UITapGestureRecognizer? = nil) {

        if UIApplication.shared.canOpenURL(NSURL(string: "fb://")! as URL) {
            if(savedImageId != ""){
                showFacebook()
            }else{
                saveImage(Services.facebook)
            }
            
        } else {
            let alert = UIAlertController(title: "Hey!", message: "You don't have Facebook installed.", preferredStyle: UIAlertControllerStyle.alert)
            if let popoverController = alert.popoverPresentationController {
                popoverController.sourceView = self.facebook
                popoverController.sourceRect = self.facebook.frame
            }
            alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    
    func showFacebook(){
        
        let idSplit = savedImageId.components(separatedBy: "/")
        
        let assetURLString: String =  "assets-library://asset/asset.MOV?id=\(idSplit[0])&ext=MOV"
        
        let assetURL: URL = URL(string: assetURLString)!;
        
        let video = Video(url: assetURL)
        
        var content = VideoShareContent(video: video)
        content.hashtag = Hashtag((wingObject?.hashtag)!)
        
        let shareDialog = ShareDialog(content: content)
        shareDialog.mode = .native
        shareDialog.completion = { result in
            // This shows even if the person discards the Facebook post
//            self.showSharedImage()
        }
        do {
            try shareDialog.show()
        } catch {
            let alert = UIAlertController(title: "Hey!", message: "There seems to be an error with sharing to Facebook.", preferredStyle: UIAlertControllerStyle.alert)
            if let popoverController = alert.popoverPresentationController {
                popoverController.sourceView = self.facebook
                popoverController.sourceRect = self.facebook.frame
            }
            alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
    

    //--------------------------
    // Handle Twitter Button Tap
    //--------------------------
    func handleTwitterTap(sender: UITapGestureRecognizer? = nil) {
    
        if(SocialVideoHelper.userHasAccessToTwitter()) {
            
            accountStore = ACAccountStore.init()
            accountType = accountStore?.accountType(withAccountTypeIdentifier: ACAccountTypeIdentifierTwitter)
            
            accountStore?.requestAccessToAccounts(with: accountType, options: nil, completion: { (granted, error) in
                
                if(granted){
                    
                    DispatchQueue.main.async{
                        self.twitterView = Bundle.main.loadNibNamed("TwitterView", owner: nil, options: nil)?[0] as? TwitterView
                        self.twitterView?.twitterTextView.text = self.wingObject?.hashtag
                        self.view.addSubview(self.twitterView!)
                        self.twitterView?.delegate = self;
                    }
                    
                }else{
                    
                    let alertController = UIAlertController(title: "Hey!", message: "You need to allow access to Twitter", preferredStyle: UIAlertControllerStyle.alert)
                    if let popoverController = alertController.popoverPresentationController {
                        popoverController.sourceView = self.twitter
                        popoverController.sourceRect = self.twitter.frame
                    }
                    alertController.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil))
                    self.present(alertController, animated: true, completion: nil)
                }
            })
            
        }else{
            let alert = UIAlertController(title: "Oops!", message: "You don't have Twitter installed.", preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil))
            
            if let popoverController = alert.popoverPresentationController {
                popoverController.sourceView = self.twitter
                popoverController.sourceRect = self.twitter.frame
            }
            present(alert, animated: true, completion: nil)
            
        }
    }
    
    func sendTweet(button:UIButton){
        
        let path = videoURL?.path
        let data:Data = FileManager.default.contents(atPath: path!)!
        let accounts = accountStore?.accounts(with: accountType)
        
        if((accounts?.count)! > 0){
            
            let account = accounts?[0]
//            let comment = twitterView?.tweetText.text
            let comment = wingObject?.hashtag
            
            self.twitterView?.removeFromSuperview();
            self.twitterView = nil
            
            SwiftSpinner.show("Posting to Twitter...")
            player.pause()
            SocialVideoHelper.uploadTwitterVideo(data, comment: comment, account: account as! ACAccount!, withCompletion:{ (VideoUploadCompletion) in
                SwiftSpinner.hide()
                self.player.play()
                self.showSharedImage()
            })
        }
    }
    
    func cancelTweet(button:UIButton){
        twitterView?.removeFromSuperview();
        twitterView = nil
    }
    
    //----------------------------
    // Handle Instagram Button Tap
    //----------------------------
    func handleInstagramTap(sender: UITapGestureRecognizer? = nil) {
        
        if UIApplication.shared.canOpenURL( URL(string:"instagram://")!){
//                showInstagram()
            if(savedImageId != ""){
                
                showInstagram()
                
            }else{
                saveImage(Services.instagram)
            }
            
        }else{
            
            let alert = UIAlertController(title: "Hey!", message: "You don't have Instagram installed.", preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func showInstagram(){
        
        let escapedString:String = savedImageId.addingPercentEncoding(withAllowedCharacters: CharacterSet.alphanumerics)!
        let instgramURL:URL = URL(string: "instagram://library?AssetPath=\(escapedString)")!
        UIApplication.shared.openURL(instgramURL)
    }
    
    //--------------------------------
    // Show saved image for 3 seconds
    //--------------------------------
    func showSavedImage() {
        self.imageSavedImage.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: UIScreen.main.bounds.size.height)
        self.imageSavedImage.contentMode = UIViewContentMode.scaleAspectFill
        self.imageSavedImage.image = UIImage(named: "saved")
        self.view.addSubview(self.imageSavedImage)
        self.view.bringSubview(toFront: self.imageSavedImage)
        self.navigationController?.isNavigationBarHidden = true
        self.share.isHidden = true
        self.insta.isHidden = true
        self.twitter.isHidden = true
        self.facebook.isHidden = true
        self.saveToGallery.isHidden = true
        self.avPlayerLayer.isHidden = true
        Timer.scheduledTimer(timeInterval: 1.3, target: self, selector: #selector(ShareViewController.dismissSavedImage), userInfo: nil, repeats: false)
    }
    
    
    //---------------------------
    // After saved image is shown
    //---------------------------
    func dismissSavedImage(){
        imageSavedImage.removeFromSuperview()
        self.navigationController?.isNavigationBarHidden = false
        self.share.isHidden = false
        self.insta.isHidden = false
        self.twitter.isHidden = false
        self.facebook.isHidden = false
        self.saveToGallery.isHidden = false
        self.avPlayerLayer.isHidden = false
    }
    
    //--------------------------------
    // Show shared image for 3 seconds
    //--------------------------------
    func showSharedImage() {
        self.imageSharedImage.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: UIScreen.main.bounds.size.height)
        self.imageSharedImage.contentMode = UIViewContentMode.scaleAspectFill
        self.imageSharedImage.image = UIImage(named: "shared")
        self.view.addSubview(self.imageSharedImage)
        self.view.bringSubview(toFront: self.imageSharedImage)
        self.navigationController?.isNavigationBarHidden = true
        self.share.isHidden = true
        self.insta.isHidden = true
        self.twitter.isHidden = true
        self.facebook.isHidden = true
        self.saveToGallery.isHidden = true
        self.avPlayerLayer.isHidden = true
        Timer.scheduledTimer(timeInterval: 1.3, target: self, selector: #selector(ShareViewController.dismissSharedImage), userInfo: nil, repeats: false)
    }
    
    func dismissSharedImage(){
        imageSharedImage.removeFromSuperview()
        self.navigationController?.isNavigationBarHidden = false
        self.share.isHidden = false
        self.insta.isHidden = false
        self.twitter.isHidden = false
        self.facebook.isHidden = false
        self.saveToGallery.isHidden = false
        self.avPlayerLayer.isHidden = false
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

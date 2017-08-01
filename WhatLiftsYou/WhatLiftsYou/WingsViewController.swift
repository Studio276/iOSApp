//
//  WingsViewController.swift
//  
//
//  Created by Jessie Albarian on 3/8/17.
//
//

import UIKit
import Firebase
import FirebaseStorage
import SwiftSpinner
import FirebaseDatabase
import AVFoundation
import Foundation
import YYImage
import ImageIO
import MobileCoreServices
import CoreGraphics
import CoreImage
import SystemConfiguration




class WingsViewController: UIViewController, UIGestureRecognizerDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UIScrollViewDelegate {

    
    var selectedImage = UIImage()
    
    // Firebase
    let storage = FIRStorage.storage()
    var temp: FIRDataSnapshot!
    
    // Wing data
    var wings: [WingData] = []
    var downloadedWingImages = [String: UIImage]()
    let defaultHash: String = ""
    let imageName: String = ""
    let gif: String = ""
    var wingObject = WingData(newName: "", newHash: "", newGif: "")
    var wingsView: WingsView?
    let wingPan = UIPanGestureRecognizer()
    let wingRotate = UIRotationGestureRecognizer()
    let wingPinch = UIPinchGestureRecognizer()
    var selectedWingData: WingData? = nil
    var wingList = [String: WingData]()
    
    var cvWidth: CGFloat?
    var cvHeight: CGFloat?
    var cellWidth: CGFloat?
    var selectedImageName : String?
    
    var wingsLoaded = false
    // Selected wing
    var selectedCell: UICollectionViewCell?
    var selectedImageIndex: Int = 0
    
    // Outlets
    @IBOutlet weak var selectedImageView: UIImageView!
    @IBOutlet weak var wingsCollectionView: UICollectionView!
    @IBOutlet weak var tool: UIToolbar!
    @IBOutlet weak var bottomView: UIView!
    
    var exitBtn = UIImageView()
    
    @IBOutlet weak var bottomViewHeightContraint: NSLayoutConstraint!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.navigationBar.isHidden = true
        
        let overlay = UIView()
        overlay.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
        overlay.backgroundColor = UIColor.white
        overlay.tag = 1
        view.addSubview(overlay)
        
        // Add gestures
        wingPan.delegate = self
        wingRotate.delegate = self
        wingPinch.delegate = self

        
        selectedImageView.addGestureRecognizer(wingPan)
        selectedImageView.addGestureRecognizer(wingRotate)
        selectedImageView.addGestureRecognizer(wingPinch)
        
        selectedImageView.isUserInteractionEnabled = true
        selectedImageView.isMultipleTouchEnabled = true
        
        wingsCollectionView.delegate = self
        wingsCollectionView.allowsMultipleSelection = false
        
        
        cvHeight = wingsCollectionView.frame.height
        cvWidth = self.view.frame.width
        
        
        // Collectionview layout
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: view.frame.size.width/3, height: view.frame.size.width/3)
        layout.minimumLineSpacing = -2
        wingsCollectionView!.collectionViewLayout = layout
        
        
        // Custom redo button
        let backBtn = UIButton(frame: CGRect(x: 0, y: 0, width: 70, height: 40))
        backBtn.setImage(UIImage(named: "backBtn"), for: UIControlState.normal)
        backBtn.imageView?.contentMode = UIViewContentMode.scaleAspectFit
        backBtn.addTarget(self, action: #selector(WingsViewController.redo), for: .touchUpInside)
        let item = UIBarButtonItem(customView: backBtn)
        self.navigationItem.leftBarButtonItem = item
        
        // Custom next button
        let nextBtn = UIButton(frame: CGRect(x: 0, y: 0, width: 70, height: 40))
        nextBtn.setImage(UIImage(named: "nextBtn"), for: UIControlState.normal)
        nextBtn.imageView?.contentMode = UIViewContentMode.scaleAspectFit
        nextBtn.addTarget(self, action: #selector(WingsViewController.nextPage), for: .touchUpInside)
        let item2 = UIBarButtonItem(customView: nextBtn)
        self.navigationItem.rightBarButtonItem = item2
        
    
    }
    
    
    //------------------
    // Select first cell
    //------------------
    func selectFirstCell() {
        let firstCellIndexPath = IndexPath(row: 0, section: 0)
        self.wingsCollectionView.selectItem(at: firstCellIndexPath, animated: true, scrollPosition: .top)
        self.collectionView(self.wingsCollectionView, didSelectItemAt: firstCellIndexPath)
    }
    
    
    //--------------
    // ViewDidAppear
    //--------------
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(false)
        
        // Set main image
        selectedImageView.image = selectedImage
        
        // Internet available
        if (Reachability.isConnectedToNetwork() == true && wingsLoaded == false)
        {
            // Add loading screen
            SwiftSpinner.sharedInstance.outerColor = UIColor(red: 102/255, green: 204/255, blue: 255/255, alpha: 1)
//            SwiftSpinner.show("Getting wings...").addTapHandler({
//                self.dismiss(animated: true, completion: nil)
//                SwiftSpinner.hide()
//            })
            SwiftSpinner.show("Getting wings...")
                
            // Add cancel button
            exitBtn.image = UIImage(named: "exitBtn")
            exitBtn.frame = CGRect(x: UIScreen.main.bounds.maxX - 50, y: 0, width: 35, height: 35)
            
//            UIScreen.main.bringSubview(toFront: exitBtn)
            
            SwiftSpinner.show(delay: 4.0, title: "Connecting to the internet...")
            self.getWingData(completionHandler: { (data: [String: WingData]) -> Void in
                self.getImages(completionHandler: { (data: [String : UIImage]) -> Void in
                    
                    if let overlayToDelete = self.view.viewWithTag(1) {
                        overlayToDelete.removeFromSuperview()
                    }
                    self.navigationController?.navigationBar.isHidden = false
                    self.resetWingsView()
                    self.selectedImageView.image = self.selectedImage
                    self.wingsView?.areWingMoversHidden = false
                    SwiftSpinner.hide()
                    self.wingsLoaded = true
                    self.wingsCollectionView.reloadData()
                    let delay = 0.2 // time in seconds
                    Timer.scheduledTimer(timeInterval: delay, target: self, selector: #selector(self.selectFirstCell), userInfo: nil, repeats: false)
                })
            })
            // Internet not available
        } else if Reachability.isConnectedToNetwork() == false {
            SwiftSpinner.sharedInstance.outerColor = UIColor.red.withAlphaComponent(0.5)
            SwiftSpinner.show("Failed to connect to internet", animated: false)
            
            let delay = DispatchTime.now() + 2
            DispatchQueue.main.asyncAfter(deadline: delay) {
                self.dismiss(animated: true, completion: nil)
                SwiftSpinner.hide()
            }
            //            SwiftSpinner.show(delay: 3.0, completion: {
            //                SwiftSpinner.sharedInstance.outerColor = UIColor.red.withAlphaComponent(0.5)
            //                SwiftSpinner.show("Failed to connect to internet", animated: false)
            //                self.dismiss(animated: true, completion: nil)
            //                SwiftSpinner.hide()
            //            })
        }
        
        
    }
    
    
    
    //-------------------------------
    // Multiple gestures at same time
    //-------------------------------
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldRecognizeSimultaneouslyWith
        otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    
    
    //--------
    // Go back
    //--------
    func redo() {
        self.dismiss(animated: true, completion: nil)
    }
    
    
    //----------
    // Next step
    //----------
    func nextPage() {
        // Add loading screen
        SwiftSpinner.show("Animating your creation...")
        
        // default gif until all gifs are ready
        let gifName = self.selectedWingData!.gif
        
        
        let storageRef = storage.reference(forURL: "gs://what-lifts-you-2.appspot.com")
        
        // set file name to selected wing image
        let wingRef = storageRef.child("gifs/" + gifName)
        
        wingRef.downloadURL { url, error in
            
            if error != nil {
                print(error!)
            } else {
                
                render(
                    wingsAtUrl: url!,
                    over: (self.selectedImageView)!,
                    with: (self.wingsView!),
                    
                    completionHandler: { (data: [UIImage]) -> Void in
                        
                        DispatchQueue.global().async {
                            
                            let settings = CXEImagesToVideo.videoSettings(codec: AVVideoCodecH264, width: (data[0].cgImage?.width)!, height: (data[0].cgImage?.height)!)
//                            AVVideoCodecH264
//                            AVVideoCodecJPEG
//                            AVVideoQualityKey
                            let movieMaker = CXEImagesToVideo(videoSettings: settings)
                            movieMaker.createMovieFrom(images: data){ (fileURL: URL?) in
                                
                                DispatchQueue.main.async {
                                    if fileURL != nil {
                                        let saveVC = self.storyboard!.instantiateViewController(withIdentifier: "share") as! ShareViewController
                                        saveVC.wingObject = self.selectedWingData!
                                        saveVC.videoURL = fileURL
                                        saveVC.bottomViewHeight = self.bottomViewHeightContraint
                                        self.navigationController?.pushViewController(saveVC, animated: true)
                                        SwiftSpinner.hide()
                                    } else {
                                        SwiftSpinner.show("An error has occured. Please try again.", animated: false)
                                        let delay2 = DispatchTime.now() + 2
                                        DispatchQueue.main.asyncAfter(deadline: delay2) {
                                            SwiftSpinner.hide()
                                        }
                                    }
                                }
                                
                            }
                        }
                })
            }
        }
    }
    
    
    
    //----------------------------
    // Get wing data from Firebase
    //----------------------------
    func getWingData(completionHandler: @escaping ((_ data: [String: WingData]) -> Void)) {
        let ref = FIRDatabase.database().reference(withPath: "wings")
        ref.observeSingleEvent(of: .value, with: { snapshot in
            
            let wingInfo = snapshot.value as! [String: [String : String]]
            
            for each in wingInfo {
                let defaultHash = each.value["hashtag"]
                let imageName = each.key + ".png"
                let gif = each.key + ".gif"

                self.wingList[imageName] = WingData(newName: imageName, newHash: defaultHash!, newGif: gif)
            }
            
            if self.wingList.count == wingInfo.count {
                completionHandler(self.wingList)
            }
        })
    }
    
    
    
    //--------------------------------------
    // Get wing images from Firebase storage
    //--------------------------------------
    func getImages(completionHandler: @escaping ((_ data: [String : UIImage]) -> Void)) {
        var completionHandlerCalled = false
        let storageRef = storage.reference(forURL: "gs://what-lifts-you-2.appspot.com")
        var xPosition = 0.0
        
        for (name, wingData) in wingList {
            let myImageView: UIImageView = UIImageView()
            
            let pic = storageRef.child("pngs/" + name)
            pic.data(withMaxSize: 1 * 600 * 600) {
                (data, error) -> Void in
                if (error != nil) {
                    print(error!)
                } else {
                    let wingImage = UIImage(data: data!)!
                    
                    wingImage.accessibilityIdentifier = name
                    myImageView.image = wingImage
                    myImageView.frame.size.width = 113
                    myImageView.frame.size.height = 70
                    myImageView.frame.origin.x = CGFloat(xPosition)
                    xPosition += 120
                    myImageView.frame.origin.y = 10
                    myImageView.contentMode = UIViewContentMode.scaleAspectFit
                    
                    // Add to image data container
                    self.downloadedWingImages[name] = myImageView.image
                    self.wings.append(wingData)
                    
                    if completionHandlerCalled == false && self.downloadedWingImages.count == self.wingList.count {
                        completionHandler(self.downloadedWingImages)
                        completionHandlerCalled = true
                    }
                }
            }
        }
    }
    
    
    
    /***************
     Collection View
     **************/
    
    
    
    //-------------------
    // Number of sections
    //-------------------
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    
    
    //---------------------------
    // Number of items in section
    //---------------------------
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if downloadedWingImages.count != 0 {
            return downloadedWingImages.count
        } else {
            return 0
        }
    }
    
    
    //-------------------
    // Configure the cell
    //-------------------
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! WingsCollectionViewCell
        cell.wingsImage.image = downloadedWingImages[wings[indexPath.row].imageName]
        return cell
    }
    
    
    
    //----------
    // Cell size
    //----------
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        cellWidth = 125
        return CGSize(width: cellWidth!, height: cvHeight!)
    }
    
    
    
    //--------------
    // Deselect cell
    //--------------
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
    }
    
    @IBAction func reset(_ sender: Any) {
        resetWingsView()
    }
    
    func resetWingsView() {
        let selectedImageName = wings[selectedImageIndex].imageName
        let imageSize = self.downloadedWingImages[selectedImageName]!.size;
        let wingsViewSize = CGSize(
            width: self.selectedImageView.frame.width,
            height: imageSize.height * self.selectedImageView.frame.width / imageSize.width
        )
        
        self.wingsView?.removeFromSuperview()
        
        self.wingsView = WingsView(frame: CGRect(
            origin: CGPoint(
                x: 0,
                y: (UIScreen.main.bounds.height - wingsViewSize.height) * 0.5
            ),
            size: wingsViewSize
        ))
        self.wingPan.addTarget(self.wingsView!, action: #selector(WingsView.panHandler))
        self.wingRotate.addTarget(self.wingsView!, action: #selector(WingsView.rotateHandler))
        self.wingPinch.addTarget(self.wingsView!, action: #selector(WingsView.pinchHandler))
        
        self.wingsView = WingsView(withAutomaticFrameSizeForParent: self.selectedImageView,
                                   andImageSize: self.downloadedWingImages[selectedImageName]!.size)
        
        self.wingPan.addTarget(self.wingsView!, action: #selector(WingsView.panHandler))
        self.wingRotate.addTarget(self.wingsView!, action: #selector(WingsView.rotateHandler))
        self.wingPinch.addTarget(self.wingsView!, action: #selector(WingsView.pinchHandler))
        
        
        self.wingsView!.wingsImage = self.downloadedWingImages[selectedImageName]
        
        self.selectedImageView.addSubview(self.wingsView!)
        self.selectedImageView.bringSubview(toFront: self.wingsView!)
        
    }
    
    //--------------
    // Selects image
    //--------------
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        wingsView!.wingsImage = downloadedWingImages[wings[indexPath.row].imageName]
        selectedWingData = self.wingList[self.wings[indexPath.row].imageName]
        selectedImageIndex = indexPath.row
    }
    
    
    @IBAction func unwindToWingsView(_ segue: UIStoryboardSegue){}
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}


public class Reachability {
    
    class func isConnectedToNetwork() -> Bool {
        
        var zeroAddress = sockaddr_in(sin_len: 0, sin_family: 0, sin_port: 0, sin_addr: in_addr(s_addr: 0), sin_zero: (0, 0, 0, 0, 0, 0, 0, 0))
        zeroAddress.sin_len = UInt8(MemoryLayout.size(ofValue: zeroAddress))
        zeroAddress.sin_family = sa_family_t(AF_INET)
        
        let defaultRouteReachability = withUnsafePointer(to: &zeroAddress) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {zeroSockAddress in
                SCNetworkReachabilityCreateWithAddress(nil, zeroSockAddress)
            }
        }
        
        var flags: SCNetworkReachabilityFlags = SCNetworkReachabilityFlags(rawValue: 0)
        if SCNetworkReachabilityGetFlags(defaultRouteReachability!, &flags) == false {
            return false
        }
        
        /* Only Working for WIFI
         let isReachable = flags == .reachable
         let needsConnection = flags == .connectionRequired
         
         return isReachable && !needsConnection
         */
        
        // Working for Cellular and WIFI
        let isReachable = (flags.rawValue & UInt32(kSCNetworkFlagsReachable)) != 0
        let needsConnection = (flags.rawValue & UInt32(kSCNetworkFlagsConnectionRequired)) != 0
        let ret = (isReachable && !needsConnection)
        
        return ret
        
    }
}

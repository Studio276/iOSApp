//
//  GalleryViewController.swift
//  WhatLiftsYou
//
//  Created by Jessie Albarian on 3/6/17.
//  Copyright © 2017 Montague Art, LLC. All rights reserved.
//

import UIKit
import Photos
import AssetsLibrary
import MobileCoreServices

class GalleryViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UICollectionViewDelegate, UICollectionViewDataSource {

    @IBOutlet weak var scrollView: UIScrollView!{
        didSet{
            scrollView.delegate = self
            scrollView.minimumZoomScale = 1.0
            scrollView.maximumZoomScale = 10.0
        }
    }
    var lastContentOffset: CGFloat = 0.0
    var minGalleryHeight = CGFloat(0)
    var maxGalleryHeight = CGFloat(0)
    var firstLayout = true
    
    @IBOutlet weak var aspectRatio: NSLayoutConstraint!
    @IBOutlet weak var galleryCollectionviewHeight: NSLayoutConstraint!
    
    @IBOutlet weak var toolbar: UIToolbar!
    @IBOutlet weak var mainImage: UIImageView!
    
    @IBOutlet weak var mainImageWidth: NSLayoutConstraint!
    @IBOutlet weak var mainImageHeight: NSLayoutConstraint!
    var images = [AnyObject]()
    var assetCollection: PHAssetCollection!
    var photosAsset: PHFetchResult<AnyObject>!
    var assetThumbnailSize: CGSize!
    let requestOptions = PHImageRequestOptions()
    let fetchOptions = PHFetchOptions()
    let imagePicker = UIImagePickerController()
    var imageChosen = false
    @IBOutlet weak var galleryCollectionView: UICollectionView!
    var selectedIndex = 0
    var isAutoScrolling = false
    
    var galleryHeight = CGFloat()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        galleryCollectionView.delegate = self
        galleryCollectionView.allowsMultipleSelection = false

        galleryHeight = galleryCollectionviewHeight.constant
        
        imagePicker.delegate = self
        
        scrollView.zoomScale = 1
        
        navigationController?.navigationBar.barTintColor = UIColor(red: 198/255, green: 198/255, blue: 198/255, alpha: 1)
        
        // Custom albums button
        let albumsBtn = UIButton(frame: CGRect(x: 0, y: 0, width: 100, height: 40))
        albumsBtn.setImage(UIImage(named: "albumsBtn"), for: UIControlState.normal)
        albumsBtn.imageView?.contentMode = UIViewContentMode.scaleAspectFit
        albumsBtn.addTarget(self, action: #selector(GalleryViewController.showAlbums), for: .touchUpInside)
        let item = UIBarButtonItem(customView: albumsBtn)
        self.navigationItem.leftBarButtonItem = item
        
        // Custom accept button
        let acceptBtn = UIButton(frame: CGRect(x: 0, y: 0, width: 100, height: 40))
        acceptBtn.setImage(UIImage(named: "acceptBtn"), for: UIControlState.normal)
        acceptBtn.imageView?.contentMode = UIViewContentMode.scaleAspectFit
        acceptBtn.addTarget(self, action: #selector(GalleryViewController.acceptImage), for: .touchUpInside)
        let item2 = UIBarButtonItem(customView: acceptBtn)
        self.navigationItem.rightBarButtonItem = item2
        
        
        // Fetch photos
        fetchOptions.includeAssetSourceTypes = .typeUserLibrary
        // TODO - CHECK ON SOOS PHONE
        let collection: PHFetchResult = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .smartAlbumRecentlyAdded, options: fetchOptions)
        if let first_Obj: AnyObject = collection.firstObject {
            //found the album
            self.assetCollection = first_Obj as! PHAssetCollection
            
        } else {
            
            self.assetCollection = collection.firstObject
        }

        layout()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        scrollView.zoomScale = 1
        // Give 1st item overlay
        if galleryCollectionView != nil {
            galleryCollectionView.selectItem(at: NSIndexPath(item: 0, section: 0) as IndexPath, animated: true, scrollPosition: [])
        }
    }
    
    func setImageToCrop(image:UIImage){
        mainImage.image = image
        mainImageWidth.constant = image.size.width
        mainImageHeight.constant = image.size.height
        let scaleHeight = scrollView.frame.size.width/image.size.width
        let scaleWidth = scrollView.frame.size.height/image.size.height
        let maxScale = max(scaleWidth, scaleHeight)
        scrollView.minimumZoomScale = maxScale
        scrollView.zoomScale = maxScale
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return mainImage
    }
    
    private func setImage(img:UIImage){
        
//        self.mainImage.clipsToBounds = true
        self.mainImage.image = img
        
    }

    override func viewDidLayoutSubviews() {
        
        super.viewDidLayoutSubviews()
        
        if (firstLayout) {
            
            firstLayout = false
            
            //compute sizes for screen
            let rootViewHeight = view.frame.height
            let rootViewWidth = view.frame.width
//            let imageAspectRatio:CGFloat = 375/464 //firstImageAspectRatioConstraint.multiplier
            let imageAspectRatio:CGFloat = aspectRatio.multiplier
            let maxImageHeight = rootViewWidth / imageAspectRatio
            let statusBarHeight = UIApplication.shared.statusBarFrame.height
            let navBarHeight: CGFloat = navigationController?.navigationBar.frame.height ?? 0
            let toolBarHeight: CGFloat = toolbar.frame.height
//            let toolBarHeight: CGFloat = tabBarController?.tabBar.frame.height ?? 0
            
            maxGalleryHeight = rootViewHeight - navBarHeight - statusBarHeight - toolBarHeight
            minGalleryHeight = maxGalleryHeight - maxImageHeight
            
            galleryCollectionviewHeight.constant = minGalleryHeight
            
            view.layoutIfNeeded()
        }
    }
    
    /**************
     *   SCROLL VIEW
     **************/
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        isAutoScrolling = false
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let scrollOffset = galleryCollectionView.contentOffset.y
        
        if !isAutoScrolling {
            if scrollOffset > lastContentOffset {
                galleryCollectionView.contentOffset = handleScrollDown(
                    scrollOffset - lastContentOffset,
                    contentOffset: galleryCollectionView.contentOffset
                )
            } else if scrollOffset < lastContentOffset {
                galleryCollectionView.contentOffset = handleScrollUp(
                    scrollOffset - lastContentOffset,
                    contentOffset: galleryCollectionView.contentOffset
                )
            }
        }
        lastContentOffset = galleryCollectionView.contentOffset.y
    }
    
    private func handleScrollDown(_ dy: CGFloat, contentOffset: CGPoint) -> CGPoint {
        if contentOffset.y <= 0 {
            return contentOffset
        }
        
        let lastHeight = galleryCollectionviewHeight.constant
        let newHeight = min(galleryCollectionviewHeight.constant + dy, maxGalleryHeight)
        let heightChange = abs(newHeight - lastHeight)
        
        galleryCollectionviewHeight.constant = newHeight
        
        return heightChange > 0 ? CGPoint(x: contentOffset.x, y: lastContentOffset) : contentOffset
    }
    
    private func handleScrollUp(_ dy: CGFloat, contentOffset: CGPoint) -> CGPoint {
        if contentOffset.y > 0 {
            return contentOffset
        }
        
        let lastHeight = galleryCollectionviewHeight.constant
        let newHeight = max(galleryCollectionviewHeight.constant + dy, minGalleryHeight)
        let heightChange = abs(newHeight - lastHeight)
        
        galleryCollectionviewHeight.constant = newHeight
        
        return heightChange > 0 ? CGPoint(x: contentOffset.x, y: lastContentOffset) : contentOffset
    }
    
//    func scrollViewDidScroll(_ scrollView: UIScrollView) {
//        if lastContentOffset > galleryCollectionView.contentOffset.y {
//            print("Scrolling Up")
//            
//            if galleryCollectionView.contentOffset.y >= 100.0 {
//                
//                UIView.animate(withDuration: 0.6, delay: 0.0, options: UIViewAnimationOptions.curveLinear, animations: {
//                    self.galleryCollectionView.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height - self.toolbar.bounds.height)
//                }, completion: nil )
//            }
//        }
//        else if lastContentOffset < galleryCollectionView.contentOffset.y {
//            print("Scrolling Down")
//            if galleryCollectionView.contentOffset.y == 0.0 {
//                UIView.animate(withDuration: 0.6, delay: 0.0, options: UIViewAnimationOptions.curveLinear, animations: {
//                    self.galleryCollectionviewHeight.constant = self.galleryHeight
//                }, completion: nil )
//            
//        }
//        
//        lastContentOffset = galleryCollectionView.contentOffset.y
//    }

    
    func layout(){
        
        var noPhotos = false
        
        if (self.assetCollection == nil) {
            
            noPhotos = true
            
        } else {
            
            // Get size of the collectionView cell for thumbnail image
            if self.galleryCollectionView!.collectionViewLayout is UICollectionViewFlowLayout && self.galleryCollectionView != nil {
                
                self.assetThumbnailSize = CGSize(width: mainImage.frame.size.width, height: mainImage.frame.size.height)
            }
            
            requestOptions.deliveryMode = .highQualityFormat
            
            //fetch the photos from collection
            fetchOptions.includeAssetSourceTypes = .typeUserLibrary
            
            
            // THE BELOW COMMENTED OUT LINES DECREASE THE NUMBER OF IMAGES IN THE COLLECTION VIEW BY A LOT
            fetchOptions.sortDescriptors = [NSSortDescriptor(key:"creationDate", ascending: false)]
//            fetchOptions.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.image.rawValue)
            
            self.photosAsset = (PHAsset.fetchAssets(in: self.assetCollection, options: fetchOptions) as AnyObject!) as! PHFetchResult<AnyObject>!
            
            if photosAsset.count > 0 {
                
                let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
                layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
                layout.itemSize = CGSize(width: view.frame.size.width / 4, height: view.frame.size.width / 4)
                layout.minimumInteritemSpacing = 0
                layout.minimumLineSpacing = 0
                galleryCollectionView!.collectionViewLayout = layout
                
                // Set first image to index 0
                let asset: PHAsset = self.photosAsset[selectedIndex] as! PHAsset
                
                PHImageManager.default().requestImage(for: asset, targetSize: self.assetThumbnailSize,
                                                      contentMode: .aspectFit, options: requestOptions,
                                                      resultHandler: { (result, info) in
                                                        if result != nil {
                                                            
                                                            self.setImage(img: result!)
                                                        }
                })
                
                self.galleryCollectionView!.reloadData()
                
            } else {
                
                noPhotos = true
            }
        }
        
        if noPhotos {
            
            self.photosAsset = nil
            self.navigationController?.isNavigationBarHidden = true
            self.galleryCollectionView = nil
            
            let alert = UIAlertController(title: "Hey!", message: "You don't have any photos yet.", preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: { action in
                self.tabBarController?.selectedIndex = 0
            }))
            
            self.present(alert, animated: true, completion: nil)
        }
    }

    func acceptImage() {
        let scale : CGFloat = mainImage.image!.size.width / mainImage.frame.width
//        let scale:CGFloat = 1/scrollView.zoomScale
        let x:CGFloat = scrollView.contentOffset.x * scale
        let y:CGFloat = scrollView.contentOffset.y * scale
        let width:CGFloat = scrollView.bounds.size.width * scale
        let height:CGFloat = scrollView.bounds.size.height * scale
        let croppedCGImage = mainImage.image?.cgImage?.cropping(to: CGRect(x: x, y: y, width: width, height: height))
        let croppedImage = UIImage(cgImage: croppedCGImage!)
//        setImageToCrop(image: croppedImage)
        
        let VC1 = self.storyboard!.instantiateViewController(withIdentifier: "wings") as! WingsViewController
        let navController = UINavigationController(rootViewController: VC1)
//        VC1.selectedImage = mainImage.image!
        VC1.selectedImage = croppedImage
        self.present(navController, animated:true, completion: { finished in
            self.scrollView.zoomScale = 1
        })
        
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
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String: Any]) {
        
        
        if let image = info[UIImagePickerControllerEditedImage] as? UIImage {
            mainImage.image = image
        } else{
            print("Something went wrong")
        }
        
//        var selectedImage = UIImage()
//        // GET EDITED IMAGE
//        selectedImage = info[UIImagePickerControllerEditedImage] as! UIImage
//        imageChosen = true
//        // SET MAIN IMAGE
//        mainImage.image = selectedImage
        // Dismiss the picker.
        dismiss(animated: true, completion: nil)
        
        // Present Wings Controller
//        let VC1 = self.storyboard!.instantiateViewController(withIdentifier: "wings") as! WingsViewController
//        let navController = UINavigationController(rootViewController: VC1) // Creating a navigation controller with VC1 at the root of the navigation stack.
//        VC1.selectedImage = selectedImage
//        self.present(navController, animated: true, completion: nil)
//        self.performSegue(withIdentifier: "showWingsView", sender: self)
        imageChosen = false
    }
    
    func showAlbums() {
        
        imagePicker.sourceType = UIImagePickerControllerSourceType.photoLibrary
        imagePicker.mediaTypes = [(kUTTypeImage as NSString) as String]
        imagePicker.allowsEditing = true
        
        if imageChosen == false {
            if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.photoLibrary) {
                let imagePicker = UIImagePickerController()
                imagePicker.delegate = self
                imagePicker.sourceType = UIImagePickerControllerSourceType.photoLibrary;
                
                imagePicker.allowsEditing = true
                self.present(imagePicker, animated: true, completion: nil)
            }
        }
    }

    
    /******************
     *  COLLECTION VIEW
     *****************/
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
        // Put max on collection view to avoid crashing
        if self.photosAsset != nil {
            if self.photosAsset.count < 60 {
                return self.photosAsset.count
            } else {
                return 60
            }
        } else {
            return 0
        }
    }
    
    //---------------------------
    // Create Cell for Index Path
    //---------------------------
    let selectedTag = 1
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CellIdentifier", for: indexPath) as! GalleryCollectionViewCell
        
        // Configure the cell
        let asset: PHAsset = self.photosAsset[indexPath.row] as! PHAsset
        PHImageManager.default().requestImage(for: asset, targetSize: self.assetThumbnailSize, contentMode: .aspectFill, options: nil, resultHandler: { (result, info) in
            if result != nil {
                cell.galleryImage.image = result
            }
        })
        
        if selectedIndex == indexPath.row && cell.tag != selectedTag {
            let overlay = UIView(frame: self.view.frame)
            overlay.backgroundColor = UIColor.white
            overlay.alpha = 0.25
            cell.addSubview(overlay)
            cell.insertSubview(overlay, aboveSubview: (cell.subviews[0]))
            cell.backgroundColor = UIColor.white
            cell.tag = selectedTag
        } else if selectedIndex != indexPath.row && cell.tag == selectedTag {
            cell.backgroundColor = UIColor.black
            cell.subviews[1].removeFromSuperview();
            cell.tag = 0
        }
        
        return cell
    }
    
    //--------------
    // Selects image
    //--------------
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        let cell = collectionView.cellForItem(at: indexPath)
        
        if collectionView.contentOffset.y - cell!.frame.origin.y != 0 {
            isAutoScrolling = true
            collectionView.scrollToItem(at: indexPath, at: UICollectionViewScrollPosition.top, animated: true)
        }
        
        view.layoutIfNeeded()
        galleryCollectionviewHeight.constant = minGalleryHeight
        
        UIView.animate(
            withDuration: 0.5,
            delay: 0,
            options: UIViewAnimationOptions.curveEaseOut,
            animations: {
                self.view.layoutIfNeeded()
        },
            completion: nil
        )
        

        scrollView.zoomScale = 1
        let asset: PHAsset = self.photosAsset[indexPath.row] as! PHAsset
        
        PHImageManager.default().requestImage(for: asset, targetSize: self.assetThumbnailSize, contentMode: .aspectFit, options: nil, resultHandler: { (result, info) in
            if result != nil {
                
                self.setImage(img: result!)
            }
        })
        
        if selectedIndex == indexPath.row {
            return
        }
        
        let previouslySelectedIndexPath = IndexPath(row: selectedIndex, section: 0)
        selectedIndex = indexPath.row
        UIView.setAnimationsEnabled(false)
        collectionView.performBatchUpdates({
            collectionView.reloadItems(at: [previouslySelectedIndexPath, indexPath])
        }, completion: { (finished) in
            UIView.setAnimationsEnabled(true)
        })

    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAtIndex section: Int) -> CGFloat {
        return 0.0
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAtIndex section: Int) -> CGFloat {
        return 0.0
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {

        return CGSize(width: UIScreen.main.bounds.width/4, height: UIScreen.main.bounds.height/4)
        
    }
    
//    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//        // Get the new view controller using segue.destinationViewController.
//        // Pass the selected object to the new view controller.
////        self.performSegue(withIdentifier: "showWingsView", sender: self)
//    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}

//
//  IntroViewController.swift
//  WhatLiftsYou
//
//  Created by Jessie Albarian on 3/6/17.
//  Copyright © 2017 Montague Art, LLC. All rights reserved.
//

import UIKit
import Gifu


class IntroViewController: UIViewController {
    
    @IBOutlet var mainImage: UIImageView!
    var imageName = ""
    var index = 0
    @IBOutlet var pageControl: UIPageControl!
    @IBOutlet var exitBtn: UIImageView!
    @IBOutlet weak var createBtn: UIImageView!
    var wingsImage = UIImageView()
    let gifImage = GIFImageView(image: nil)
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        wingsImage.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
        wingsImage.contentMode = UIViewContentMode.scaleAspectFit
    
        
//        // Set user defaults and enable exit buttons
//        if UserDefaults.standard.bool(forKey: "Walkthrough") {
//            // Terms have been accepted, proceed as normal
//            exit()
//        } else {
//            configurePageControl()
//            mainImage.image = UIImage(named: imageName)
//            pageControl.currentPage = index
//            
//            if (index == 0 || index == 1 || index == 2) {
//                exitBtn.image = nil
//                createBtn.image = nil
//            } else {
//                
//                exitBtn.image = UIImage(named: "exitBtn")
//                
//                let tapGestureRecognizer = UITapGestureRecognizer(target:self, action:#selector(IntroViewController.exit))
//                let tapGestureRecognizer2 = UITapGestureRecognizer(target:self, action:#selector(IntroViewController.exit))
//                // Add tap gesture to exit button
//                exitBtn.isUserInteractionEnabled = true
//                exitBtn.addGestureRecognizer(tapGestureRecognizer2)
//                
//                // Add tap gesture to create button
//                createBtn.image = UIImage(named: "createBtn")
//                createBtn.isUserInteractionEnabled = true
//                createBtn.addGestureRecognizer(tapGestureRecognizer)
//            }
//        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        // Set user defaults and enable exit buttons
        if UserDefaults.standard.bool(forKey: "Walkthrough") {
            // Terms have been accepted, proceed as normal
            exit()
        } else {
            configurePageControl()
            mainImage.image = UIImage(named: imageName)
            pageControl.currentPage = index
            
            if (index == 0 || index == 1 || index == 2) {
                exitBtn.image = nil
                createBtn.image = nil
            } else {
                
                exitBtn.image = UIImage(named: "exitBtn")
                
                let tapGestureRecognizer = UITapGestureRecognizer(target:self, action:#selector(IntroViewController.exit))
                let tapGestureRecognizer2 = UITapGestureRecognizer(target:self, action:#selector(IntroViewController.exit))
                // Add tap gesture to exit button
                exitBtn.isUserInteractionEnabled = true
                exitBtn.addGestureRecognizer(tapGestureRecognizer2)
                
                // Add tap gesture to create button
                createBtn.image = UIImage(named: "createBtn")
                createBtn.isUserInteractionEnabled = true
                createBtn.addGestureRecognizer(tapGestureRecognizer)
            }
        }
        
        if (index == 1) {
            
            wingsImage.image = UIImage(named: "wingAnimationIntro")
            wingsImage.center.y -= 30
            self.mainImage.addSubview(wingsImage)
            
            UIView.animate(withDuration: 0.6, delay: 0.0, options: UIViewAnimationOptions.curveLinear, animations: {
                if UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad {
                    self.wingsImage.center.y += 60
                } else {
                    self.wingsImage.center.y += 30
                }
            }, completion: nil)
            
            
        } else if (index == 2) {
            
            wingsImage.image = UIImage(named: "wingAnimationIntro")
            wingsImage.transform = CGAffineTransform(scaleX: 1.5, y: 1.5)
            
            self.mainImage.addSubview(wingsImage)
            DispatchQueue.main.async {
                UIView.animate(withDuration: 0.6, delay: 0.0, options: UIViewAnimationOptions.curveLinear, animations: {
                    
                    self.wingsImage.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
                    
                }, completion: { finished in
                    
                    UIView.animate(withDuration: 0.4, delay: 0.0, options: UIViewAnimationOptions.curveLinear, animations: {
                        
                        self.wingsImage.transform = self.wingsImage.transform.rotated(by: CGFloat(-0.2))
                        
                    }, completion: {finished in
                        
                        UIView.animate(withDuration: 0.4, delay: 0.0, options: UIViewAnimationOptions.curveLinear, animations: {
                            
                            self.wingsImage.transform = self.wingsImage.transform.rotated(by: CGFloat(0.4))
                            
                        }, completion: { finished in
                            
                            UIView.animate(withDuration: 0.4, delay: 0.0, options: UIViewAnimationOptions.curveLinear, animations: {
                                
                                self.wingsImage.transform = self.wingsImage.transform.rotated(by: CGFloat(-0.2))
                                
                            }, completion: nil )
                        })
                    })
                })
            }
            
        } else if (index == 3){
            
            gifImage.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
            gifImage.animate(withGIFNamed: "tutorial4wings")
            mainImage.addSubview(self.gifImage)
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }
    
    // Exit intro walkthrough
    func exit(){
        UserDefaults.standard.set(true, forKey: "Walkthrough")
        let appDelegate = UIApplication.shared.delegate! as! AppDelegate
        let initialViewController = storyboard?.instantiateViewController(withIdentifier: "CameraViewController") as! CameraViewController
        
        appDelegate.window?.rootViewController = initialViewController
        appDelegate.window?.makeKeyAndVisible()
        
        self.performSegue(withIdentifier: "cameraSegue", sender: self)
//        self.present(initialViewController, animated: true, completion: nil)
        

    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func configurePageControl() {
        self.pageControl.numberOfPages = 4
        self.pageControl.currentPage = 0
        self.pageControl.tintColor = UIColor.white
        self.pageControl.pageIndicatorTintColor = UIColor.lightGray
        self.pageControl.currentPageIndicatorTintColor = UIColor.black
        self.view.addSubview(pageControl)
    }
}

//
//  PageViewController.swift
//  WhatLiftsYou
//
//  Created by Jessie Albarian on 3/6/17.
//  Copyright © 2017 Montague Art, LLC. All rights reserved.
//

import UIKit

class PageViewController: UIPageViewController, UIPageViewControllerDelegate {
    
    var images = ["intro1", "intro2", "intro3", "intro4"]
//    var texts = ["intro1text", "intro2text", "intro3text", "intro4text"]
    
    var index = 0
    var pageViewController : UIPageViewController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.dataSource = self
        
        if let startWalkthrough = self.viewControllerAtIndex(index: 0){
            setViewControllers([startWalkthrough], direction: .forward, animated: true, completion: nil)
        }
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func nextPageWithIndex(index : Int) {
        if let nextWalkthroughVC = self.viewControllerAtIndex(index: index + 1){
            setViewControllers([nextWalkthroughVC], direction: .forward, animated: true, completion: nil)
        }
    }
    
    func viewControllerAtIndex(index : Int) -> IntroViewController? {
        if index == NSNotFound || index < 0 || index >= self.images.count {
            return nil
        }
        if let introViewController = storyboard?.instantiateViewController(withIdentifier: "IntroViewController") as? IntroViewController {
            introViewController.imageName = images[index]
//            introViewController.textImageName = texts[index]
            introViewController.index = index
            return introViewController
        }
        
        return nil
    }
}

extension PageViewController : UIPageViewControllerDataSource {
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        
        var index = (viewController as! IntroViewController).index
        index -= 1
        return self.viewControllerAtIndex(index: index)
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        
        var index = (viewController as! IntroViewController).index
        index += 1
        
        
        return self.viewControllerAtIndex(index: index)
    }
    
}


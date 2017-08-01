//
//  WingsCollectionViewCell.swift
//  WhatLiftsYou
//
//  Created by Jessie Albarian on 3/8/17.
//  Copyright © 2017 Montague Art, LLC. All rights reserved.
//

import UIKit

class WingsCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var wingsImage: UIImageView!
    var cellWidth = 125
    // Need to unhardcode
    var cvHeight = 95
    
    var newPointY = 113
    var newLen = 85
    var counter = 0
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.layer.borderWidth = 2 //Default border width
        self.layer.borderColor = UIColor.black.cgColor // default border color
        
        let overlayView = UIView(frame: CGRect(x: 0, y: 0, width: cellWidth, height: cvHeight))
        overlayView.backgroundColor = UIColor.white
        overlayView.alpha = 0.0
        
        self.insertSubview(overlayView, aboveSubview: (self.subviews[0]))
        
        let newPointY = cvHeight - 8
        
        let lineView = UIView(frame: CGRect(x: cellWidth/2, y: newPointY, width: 0, height: 5))
        // Keep below line
        //        lineView.backgroundColor = UIColor(red: 102/255, green: 204/255, blue: 255/255, alpha: 1)
        lineView.backgroundColor = UIColor.black
        
        self.insertSubview(lineView, aboveSubview: self.subviews[1])
    }
    
    override var isSelected: Bool {
        
        didSet{
            
            if self.isSelected {
                
                self.layer.borderWidth = 4
                
                let overlayView = self.subviews[1]
                overlayView.alpha = 0.5
                
                let lineView = self.subviews[2]
                UIView.animate(withDuration: 0.5, delay: 0.0, options: UIViewAnimationOptions.curveEaseInOut,animations: {
                    lineView.frame = CGRect(x: 20, y: self.cvHeight - 8, width: self.newLen, height: 5)
                    
                })
            }
                
            else {
                
                self.layer.borderWidth = 2
                
                let overlayView = self.subviews[1]
                overlayView.alpha = 0.0
                
                let lineView = self.subviews[2]
                UIView.animate(withDuration: 0.2, animations: {
                    lineView.frame = CGRect(x: self.cellWidth/2, y: self.cvHeight - 4, width: 0, height: 5)
                })
            }
        }
    }

}

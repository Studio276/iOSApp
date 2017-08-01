//
//  WingsView.swift
//  WhatLiftsYou
//
//  Created by Jessie Albarian on 3/8/17.
//  Copyright © 2017 Montague Art, LLC. All rights reserved.
//


import UIKit


/**
 Describes the current state of the pinch handling.  The allowable state transitions are:
 
 Idle <-> Resizing
 Idle <-> Separating
 
 Note that the state is not intended to change from resizing to separating or vice-versa.
 This ensures that when a gesture starts, it does not switch function until a new gesture begins.
 
 - Idle: There is no pinch being processed at this time
 - Resizing: The current pinch gesture being processed is a resize.  Changes the size of the wings
 - Separating The current pinch gesture being processed is a separation.  Changes the distance between the wings
 */
enum PinchActionState {
    case Idle, Resizing, Separating
}



/// A view that allows users to position wings by moving, rotating, scaling, and separating them.
class WingsView: UIView {
    
    //-------------
    // Constructors
    //-------------
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initializeViews()
    }
    
    convenience init (withAutomaticFrameSizeForParent superView: UIView, andImageSize imageSize: CGSize) {
        let wingScale = CGFloat(1.25)   // scale them up a bit - the image frame is quite a bit larger than
        // most of the wings
        
        let wingsViewSize = CGSize(
            width: superView.frame.width * wingScale,
            height: (imageSize.height * superView.frame.width / imageSize.width) *
                wingScale * 2 * WingsView.moverVOffsetRatio
        )
        
        self.init(frame: CGRect(
            origin: CGPoint(
                x: (superView.frame.width - wingsViewSize.width) * 0.5,
                y: (superView.frame.height - wingsViewSize.height) * 0.5
            ),
            size: wingsViewSize
        ))
    }
    
    convenience init() {
        self.init(frame: CGRect.zero)
    }
    
    required init(coder decoder: NSCoder) {
        fatalError("This class does not support NSCoding")
    }
    
    private func initializeViews() {
        self.initialViewSize = self.bounds.size
        
        self.leftWing.contentMode = UIViewContentMode.scaleAspectFit
        self.rightWing.contentMode = UIViewContentMode.scaleAspectFit
        self.moverImage = UIImage(named: "wingMover")
        
        self.addSubview(leftWing)
        self.addSubview(leftWingMover)
        self.addSubview(rightWing)
        self.addSubview(rightWingMover)
    }
    
    //-----------
    // Properties
    //-----------
    
    /// The left wing image
    var leftWing = UIImageView()
    /// The right wing image
    var rightWing = UIImageView()
    /// An anchor that, if touched along with the right one, changes the spacing of the wings
    private var leftWingMover = UIImageView()
    /// An anchor that, if touched along with the left one, changes the spacing of the wings
    private var rightWingMover = UIImageView()
    
    /// The state of the pinch gesture handling as of the last call to the handler function
    private var lastPinchState = PinchActionState.Idle;
    /// The scale of the view, relative to when it was first created
    private var scale = CGFloat(1)
    /// The initial size of the view
    private var initialViewSize = CGSize.zero;
    /// The image currently displayed by the movers.  Changes with the state
    private var moverImage: UIImage? = nil {
        didSet {
            leftWingMover.image = moverImage
            rightWingMover.image = moverImage
        }
    }
    /// The images currently displayed by the wings.
    var wingsImage: UIImage? = nil {
        didSet {
            if let image = wingsImage {
                leftWing.image = cropToBounds(image: image,
                                              width: image.size.width,
                                              height: image.size.height,
                                              leftHalf: true)
                rightWing.image = cropToBounds(image: image,
                                               width: image.size.width,
                                               height: image.size.height,
                                               leftHalf: false)
            }
        }
    }
    /// Hides and shows the movers for rendering the final image
    var areWingMoversHidden = false {
        didSet {
            leftWingMover.isHidden = areWingMoversHidden
            rightWingMover.isHidden = areWingMoversHidden
        }
    }
    /// The space in between the wings
    var wingSpacing = CGFloat(0) {
        didSet {
            if (wingSpacing < 0) {
                wingSpacing = 0
            }
        }
    }
    
    /// The size of each wing view
    private var wingSize: CGSize {
        return CGSize(
            width: (self.bounds.width - wingSpacing) * 0.5,
            height: self.bounds.height / (WingsView.moverVOffsetRatio * 2)
        )
    }
    /// The size of the movers
    let wingMoverSize = CGSize(width: 54, height: 54)
    let moverHOffset = CGFloat(0.15)
    static let moverVOffsetRatio = CGFloat(0.67)
    private var moverVOffset: CGFloat {
        return wingSize.height * WingsView.moverVOffsetRatio -
            wingMoverSize.height * WingsView.moverVOffsetRatio
    }
    /// The size of the entire WingsView instance
    private var viewSize: CGSize {
        return CGSize(
            width: initialViewSize.width * scale + wingSpacing,
            height: initialViewSize.height * scale
        )
    }
    
    //--------
    // Methods
    //--------
    
    
    //----------------------------
    // Calculating Subview Layouts
    //----------------------------
    override func layoutSubviews() {
        if self.wingsImage != nil {
            layoutSelf()
            layoutLeftWing()
            layoutRightWing()
            layoutLeftWingMover()
            layoutRightWingMover()
        }
    }
    
    private func layoutSelf() {
        self.bounds = CGRect(
            origin: CGPoint.zero,
            size: viewSize
        )
    }
    
    func layoutLeftWing() {
        leftWing.frame = CGRect(origin: CGPoint.zero, size: wingSize)
    }
    
    func layoutRightWing() {
        rightWing.frame = CGRect(origin: CGPoint(x: wingSize.width + wingSpacing, y: 0), size: self.wingSize)
    }
    
    private func layoutLeftWingMover() {
        layoutWingMover(moverView: leftWingMover, horizontalOffset: -moverHOffset, spacingMultiplier: 0)
    }
    
    private func layoutRightWingMover() {
        layoutWingMover(moverView: rightWingMover, horizontalOffset: moverHOffset, spacingMultiplier: 1)
    }
    
    private func layoutWingMover(moverView: UIImageView, horizontalOffset: CGFloat, spacingMultiplier: CGFloat) {
        moverView.frame = CGRect(
            origin: CGPoint(
                x: wingSize.width * (1.0 + horizontalOffset) +
                    spacingMultiplier * wingSpacing - wingMoverSize.width * 0.5,
                y: moverVOffset
            ),
            size: wingMoverSize
        )
    }
    
    
    //------
    // Pinch
    //------
    func pinchHandler(sender: UIPinchGestureRecognizer) {
        // compute the new state
        let newActionState = calculateNewActionState(sender: sender, oldState: lastPinchState)
        
        // and react to it
        switch newActionState {
        case .Resizing:
            self.scale *= sender.scale;
        //            moverImage = UIImage(named: "wingmover_pinch")
        case .Separating:
            calculateNewSpacing(sender: sender)
            moverImage = UIImage(named: "wingmover_selected")
        case .Idle:
            moverImage = UIImage(named: "wingMover")
        }
        
        // save the current state for the next call
        lastPinchState = newActionState;
        
        // reset the scale
        sender.scale = 1;
        
        // update the layout
        layoutSubviews()
    }
    
    func calculateNewActionState(sender: UIPinchGestureRecognizer, oldState: PinchActionState) -> PinchActionState {
        if sender.state == .ended || sender.numberOfTouches < 2 {
            return .Idle // If pinch gesture is ending, we want the idle state
        } else if sender.numberOfTouches == 2 && oldState == .Idle { // only change to an active state if currently idle (ie. don't change from resizing to separating or vice-versa
            if isSeparationGesture(sender: sender) {
                return .Separating
            } else {
                return .Resizing
            }
        }
        
        return oldState // return old state if no new state can be calculated
    }
    
    func isSeparationGesture(sender: UIPinchGestureRecognizer) -> Bool {
        let touch1 = sender.location(ofTouch: 0, in: self)
        let touch2 = sender.location(ofTouch: 1, in: self)
        
        // If each wing mover is being touched, treat the gesture as a separation gesture.
        if leftWingMover.frame.contains(touch1) {
            return rightWingMover.frame.contains(touch2)
        } else if leftWingMover.frame.contains(touch2) {
            return rightWingMover.frame.contains(touch1)
        } else {
            return false
        }
    }
    
    func calculateNewSpacing(sender: UIPinchGestureRecognizer) {
        let touch1 = sender.location(ofTouch: 0, in: self)
        let touch2 = sender.location(ofTouch: 1, in: self)
        
        let fingerDistance = distance(point1: touch1, point2: touch2)
        
        // The space between the wings should be the space between the touches minus the space from the
        // centers of each mover to the inner edges of their respective wings, as illustrated below:
        //
        //                 |--------------------------------|
        //                            finger spacing
        //
        // mover spacing > |---|------------------------|---| < mover spacing
        //                             wing spacing
        //
        //
        self.wingSpacing = fingerDistance - (leftWing.frame.width - leftWingMover.center.x) * 2
    }
    
    
    //-------
    // Rotate
    //-------
    func rotateHandler(sender: UIRotationGestureRecognizer) {
        transform = transform.rotated(by: sender.rotation)
        sender.rotation = 0 // Reset rotation
    }
    
    
    
    //----
    // Pan
    //----
    func panHandler(sender: UIPanGestureRecognizer) {
        let translation = sender.translation(in: superview) //returns the new location
        center = CGPoint(x: center.x + translation.x, y: center.y + translation.y)
        sender.setTranslation(CGPoint(x: 0, y: 0), in: superview) //set the translation back to 0
        
        // Animates image movement with a slide if movement is swipe-like
        if sender.state == UIGestureRecognizerState.ended {
            //figure out the velocity
            let velocity = sender.velocity(in: self.superview)
            let magnitude = sqrt((velocity.x * velocity.x) + (velocity.y * velocity.y))
            let slideMultiplier = magnitude / 200
            
            //if the length is < 200, then decrease the base speed, otherwise increase it
            let slideFactor = 0.1 * slideMultiplier //increase for a greater slide
            
            //calculate a final point based on the velocity and the slideFactor
            var finalPoint = CGPoint(
                x: sender.view!.center.x + (velocity.x * slideFactor),
                y: center.y + (velocity.y * slideFactor)
            )
            
            //make sure the final point is within the view’s bounds
            finalPoint.x = min(max(finalPoint.x, 0), superview?.bounds.size.width ?? 0)
            finalPoint.y = min(max(finalPoint.y, 0), superview?.bounds.size.height ?? 0)
        }
    }
    
    
    
    //-------------------
    // Crop wings in half
    //-------------------
    func cropToBounds(image: UIImage, width: CGFloat, height: CGFloat, leftHalf: Bool) -> UIImage {
        
        let contextImage: UIImage = UIImage(cgImage: image.cgImage!)
        
        let contextSize: CGSize = contextImage.size
        
        var posX: CGFloat = 0.0
        var posY: CGFloat = 0.0
        var cgwidth: CGFloat = CGFloat(width)
        var cgheight: CGFloat = CGFloat(height)
        
        if (leftHalf == false) {
            // Right half, so make the x origin start at the middle half to crop from the center to the right edge
            posX = CGFloat(Double(width) / Double(2.0))
        } else {
            posX = 0
        }
        posY = 0
        cgwidth = (contextSize.width) / 2
        cgheight = contextSize.width
        let rect: CGRect = CGRect(x: posX, y: posY, width: cgwidth, height: cgheight)
        
        // Create bitmap image from context using the rect
        let imageRef: CGImage = contextImage.cgImage!.cropping(to: rect)!
        
        // Create a new image based on the imageRef and rotate back to the original orientation
        let image: UIImage = UIImage(cgImage: imageRef, scale: image.scale, orientation: image.imageOrientation)
        
        return image
    }
    
}


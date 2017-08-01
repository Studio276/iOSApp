//
//  Geometry.swift
//  WhatLiftsYou
//
//  Created by Jessie Albarian on 3/8/17.
//  Copyright © 2017 Montague Art, LLC. All rights reserved.
//

import UIKit

/**
 Calculates the distance between two points
 
 - parameters:
 - point1: The first point
 - point2: The second point
 - returns: The distance between point1 and point 2
 */
func distance(point1: CGPoint, point2: CGPoint) -> CGFloat {
    let xDist = point1.x - point2.x
    let yDist = point1.y - point2.y
    let dist = sqrt((xDist*xDist) + (yDist*yDist))
    return dist
}

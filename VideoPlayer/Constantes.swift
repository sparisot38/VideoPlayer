//
//  GlobalVar.swift
//  VideoPlayer
//
//  Created by sparisot on 14/09/2020.
//  Copyright © 2020 Stéphane Parisot. All rights reserved.
//
// Global variables

import UIKit

// Samples for waveforms
public var samples : [Int] = []

// Number of samples
let targetSamples = 300

// Video url
public var url = Bundle.main.url(forResource: "silexvideo", withExtension: "mp4")!

// Some constants that will define our waveform
let barWidth = CGFloat(2)
let barSpacing = CGFloat(1.5)
let topToBottomRatio = CGFloat(2.0 / 3.0)
let verticalSpacing = CGFloat(1.0)

// Container height for waveform
let containerHeight = CGFloat(200)



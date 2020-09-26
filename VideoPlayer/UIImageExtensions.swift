//
//  UIImageExtensions.swift
//  VideoPlayer
//
//  Created by sparisot on 31/08/2020.
//  Copyright © 2020 Stéphane Parisot. All rights reserved.
//

import UIKit

extension UIImage {

    /// heart of the scrubber. This method draws the waveform as a UIImage
    static func waveformImage() -> UIImage {
        let containerWidth = CGFloat(samples.count) * (barSpacing + barWidth)
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: containerWidth, height: containerHeight))
        let image = renderer.image { ctx in
            
            // We need to draw the top bars and the bottom bars separately since they have different fill colors
            // Rather than looping once and drawing twice each loop, drawing hundreds of times
            // We will loop twice and draw only twice
            var count = 0
            // Draw top part of the image. Ratio ToptoBottom is applied
            samples.forEach{ sample in
                
                let x = CGFloat(count) * (barWidth + barSpacing)
                
                // Draw the top "half" first

                let topHeight = CGFloat(sample) * topToBottomRatio
                let topY = (containerHeight * topToBottomRatio) - topHeight
                let topBar = CGRect(x: x, y: topY, width: barWidth, height: topHeight)
                ctx.cgContext.setFillColor(UIColor.white.cgColor)
                ctx.cgContext.addRect(topBar)
                
                count += 1
            }
            ctx.cgContext.drawPath(using: .fill)
            
            // Now for the bottom bars
            count = 0
            samples.forEach{ sample in
                let x = CGFloat(count) * (barWidth + barSpacing)
                
                // Draw the bottom "half"
                let bottomHeight = CGFloat(sample) - (CGFloat(sample) * topToBottomRatio)
                let bottomY = (containerHeight * topToBottomRatio) + verticalSpacing
                let bottomBar = CGRect(x: x, y: bottomY, width: barWidth, height: bottomHeight)
                ctx.cgContext.setFillColor(UIColor(white: 1.0, alpha: 0.9).cgColor)
                ctx.cgContext.addRect(bottomBar)
                
                count += 1
            }
                        
            ctx.cgContext.drawPath(using: .fill)
            
        }
        return image
    }
}

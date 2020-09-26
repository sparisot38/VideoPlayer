//
//  ScrubberDelegate.swift
//  VideoPlayer
//
//  Created by sparisot on 09/09/2020.
//  Copyright © 2020 Stéphane Parisot. All rights reserved.
//

import UIKit
// This defines how this VC communicates with the main VC
protocol ScrubberDelegate {
    /**
     progress is a percent representing amount of content that has been scrolled
     - Parameter progress: value between 0.0 and 1.0 indicating % of waveform scrubbed
     */
    func progressUpdatedTo(progress: CGFloat)
  //  var active: Bool { get set}
}

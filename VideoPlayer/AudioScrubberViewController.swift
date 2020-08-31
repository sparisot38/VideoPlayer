//
//  AudioScrubberViewController.swift
//  VideoPlayer
//
//  Created by sparisot on 29/08/2020.
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
    var active: Bool { get set}
}

@IBDesignable class AudioScrubberController: UIViewController, UIScrollViewDelegate {

    @IBOutlet weak var maskedWaveformView: UIView!
    @IBOutlet weak var maskedViewLeftSide: UIView!
    @IBOutlet weak var maskedViewRightSide: UIView!
    @IBOutlet weak var maskView: UIScrollView!
    @IBOutlet weak var scrollView: UIScrollView!
    
     var waveformView: UIImageView!
        
        // Set this to false to match SoundCloud's functionality
        var inertiaEnabled: Bool = true
        
        var scrubberDelegate: ScrubberDelegate?
        
        // MARK: - UIView Basics
        override func viewDidLoad() {
            super.viewDidLoad()
            self.inertiaEnabled = false
            
            let image = UIImage.waveformImage()
            waveformView = UIImageView(image: image)
            waveformView.frame.size = image.size
            waveformView.translatesAutoresizingMaskIntoConstraints = false
            maskView.addSubview(waveformView)
            
            maskView.contentInset = UIEdgeInsets.init(top: 0, left: self.view.frame.size.width / 2.0, bottom: 0.0, right: self.view.frame.size.width / 2.0)
            maskView.contentSize = image.size
            maskView.frame.size = image.size
            
            scrollView.contentInset = maskView.contentInset
            scrollView.contentSize = maskView.contentSize
            
            maskedViewLeftSide.backgroundColor = UIColor(patternImage: #imageLiteral(resourceName: "WaveformGradient-Left"))
            maskedViewRightSide.backgroundColor = UIColor(patternImage: #imageLiteral(resourceName: "WaveformGradient-Right"))
            maskedWaveformView.mask = maskView
        }

        // We need to get access to the parent VC as our scrubber delegate
        // View containment provides a method to do that
        override func didMove(toParent parent: UIViewController?) {
            self.scrubberDelegate = parent as? ScrubberDelegate
        }

        // MARK: - ScrollView Delegate
        // Disable scrolling inertia
        func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
            if !inertiaEnabled {
                self.scrollView.setContentOffset(scrollView.contentOffset, animated: false)
            }
        }
        
        // We need to programmatically make the offset of the masked waveform match the offset of the main scrollview
        func scrollViewDidScroll(_ scrollView: UIScrollView) {
            let offset = scrollView.contentOffset
            maskView.contentOffset = offset
            
            notifyDelegateOfScroll()
        }
        
        func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
            scrubberDelegate?.active = true
        }
        
        func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
            if !inertiaEnabled || (inertiaEnabled && !decelerate) {
                scrubberDelegate?.active = false
            }
        }
        
        func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
            scrubberDelegate?.active = false
        }
        
        private func notifyDelegateOfScroll() {
            let point = scrollView.contentOffset
            let offsetInPercent = (point.x + scrollView.contentInset.left) / scrollView.contentSize.width
            scrubberDelegate?.progressUpdatedTo(progress: offsetInPercent)
        }
    }

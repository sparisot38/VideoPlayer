//
//  AudioScrubberViewController.swift
//  VideoPlayer
//
//  Created by sparisot on 29/08/2020.
//  Copyright © 2020 Stéphane Parisot. All rights reserved.
//

import UIKit

@IBDesignable class AudioScrubberController: UIViewController, UIScrollViewDelegate, FileLoaderDelegate {
    
    @IBOutlet weak var maskedWaveformView: UIView!
    @IBOutlet weak var maskedViewLeftSide: UIView!
    @IBOutlet weak var maskedViewRightSide: UIView!
    @IBOutlet weak var maskView: UIScrollView!
    @IBOutlet weak var scrollView: UIScrollView!
    
    var waveformView: UIImageView!
    var inertiaEnabled: Bool = true
    var scrubberDelegate: ScrubberDelegate?
    var fileLoader: FileLoader?
    var imageDelegate : ImageViewDelegate?
    static let passingVideoCurrentTime = Notification.Name("passingVideoCurrentTime")
    let image = UIImage.waveformImage()
    var imageSize : CGFloat = 0.0
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(updateScrollingImage(_:)), name: AudioScrubberController.passingVideoCurrentTime, object: nil)

        displayImageAfterLoading()

        fileLoader = FileLoader(url: url)
        fileLoader?.delegate = self
        fileLoader?.loadSample()
        
        
    }
     
    
    // Récupère le % d'avancement de la vidéo (currentTimeInPercent)
    // Synchronise le waveform pour suivre le défilement de la vidéo (maskView.content)
    @objc func updateScrollingImage(_ notification: Notification) {
        if let data = notification.userInfo as? [String: Float]
        {
            for (_, currentVideoTimeInPercent) in data
            {
                let offSetWaveForm = Float(-self.view.frame.size.width / 2.0)
                let xPosition = offSetWaveForm + Float(imageSize) * currentVideoTimeInPercent
                
                // check si xPosition n'est pas égal à Nan lors de l'initialisation. Sinon crash de l'app
                if case xPosition.isNaN = false {
                    maskView.contentOffset.x = CGFloat(xPosition)
                }
            }
        }
    }
    
    func displayImageAfterLoading(){
        let image = UIImage.waveformImage()
        
        imageDelegate?.update(image)
        
        waveformView = UIImageView(image: image)
        waveformView.frame.size = image.size
        waveformView.translatesAutoresizingMaskIntoConstraints = false
        maskView.addSubview(waveformView)
        imageSize = image.size.width
        
        maskView.contentInset = UIEdgeInsets.init(top: 0, left: self.view.frame.size.width / 2.0, bottom: 0, right: self.view.frame.size.width / 2.0)
        
        
        
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
    
    
    // Func qui permettait d'activer l'effet Blur et le décalage du timing comme sur SoundCloud.
    // Pas de besoin de ces fonctions.
    
    //    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
    //        scrubberDelegate?.active = true
    //    }
    
    //    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
    //        if !inertiaEnabled || (inertiaEnabled && !decelerate) {
    //            scrubberDelegate?.active = false
    //        }
    //    }
    
    //    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
    //        scrubberDelegate?.active = false
    //    }
    



    private func notifyDelegateOfScroll() {
        let point = scrollView.contentOffset
        let offsetInPercent = (point.x + scrollView.contentInset.left) / scrollView.contentSize.width
        
        scrubberDelegate?.progressUpdatedTo(progress: offsetInPercent)
    }
    
    
    func didFinishLoading(_ sender:FileLoader) {
        samples = sender.samples
        displayImageAfterLoading()
        //       audioScrubber.displayImageAfterLoading()
        
    }
    
    
}

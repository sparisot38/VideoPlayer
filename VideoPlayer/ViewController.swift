//
//  ViewController.swift
//  VideoPlayer
//
//  Created by sparisot on 18/08/2020.
//  Copyright © 2020 Stéphane Parisot. All rights reserved.


import UIKit
import AVKit
import AVFoundation


class ViewController: UIViewController {
    
    @IBOutlet weak var videoView: UIView!
    @IBOutlet weak var timeSlider: UISlider!
    @IBOutlet weak var currentTimeLabel: UILabel!
    @IBOutlet weak var durationLabel: UILabel!
    @IBOutlet weak var buttonPlay: UIButton!
    @IBOutlet weak var fullWaveformImageView: UIImageView!
    @IBOutlet weak var tapView: UIView!
    @IBOutlet weak var containerView: UIView!
    
    
    /* Player Video */
    var asset : AVAsset!
    var player: AVPlayer!
    var playerItem: AVPlayerItem!
    var playerLayer = AVPlayerLayer()
    var isVideoPlaying = false
    private var playerItemContext = 0
    let requiredAssetKeys = [
        "playable",
        "hasProtectedContent"
    ]
    var rate : Float = 1 /* Video Speed by default =1 */

    
    /* Waveform settings */
    var waveformView: UIImageView!
    var newImage: UIImage! /* image waveform full size*/

    
// UI respond's when the user is scrolling the waveform by
// animating the time label and blurring the background
//    let animationDuration       = 0.25
//    var active: Bool = false {
//        didSet {
//            if active {
//                // set UI to active
//                UIView.animate(withDuration: animationDuration, delay: 0.0, usingSpringWithDamping: 0.4, initialSpringVelocity: 0.2, options: .curveEaseIn, animations: {
//                    self.view.layoutIfNeeded()
//                }, completion: nil)
//            }else {
//                // set UI to inactive
//                UIView.animate(withDuration: animationDuration, delay: 0.0, usingSpringWithDamping: 1.0, initialSpringVelocity: 1.0, options: .curveLinear, animations: {
//                    self.view.layoutIfNeeded()
//                }, completion: nil)
//            }
//        }
//    }
    
    
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        // Définition de la zone permettant d'activer le TapGestureRecognizer pour déclancher ou arrêter la vidéo.
        // ATTENTION Les valeurs de CGREC doivent être calculées dynamiquement en fonction de la taille de l'iphone,ipad
        //       let tapView = UIView(frame: CGRect(x: 0, y: 108, width: 414, height: 483))
        //tapView.backgroundColor = .red
        view.addSubview(tapView)
        
        // Area for tapping = tapView and containerView. Obligé de procéder ainsi car sinon le scroll est désactivé sur container view
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(sender:)))
        tapView.addGestureRecognizer(tap)
        let tap2 = UITapGestureRecognizer(target: self, action: #selector(handleTap(sender:)))
        containerView.addGestureRecognizer(tap2)
        setUpPlayerLayer()
        
    }
    

    
    @objc func handleTap(sender: UITapGestureRecognizer) {
        guard sender.view != nil else {return}
        if sender.state == .ended {
            changeStatusVideoPlay()
        }
        
    }
    
    
    func displayWaveformAfterLoading(){
        fullWaveformImageView.contentMode = .scaleToFill
        fullWaveformImageView.image = newImage
        self.view.addSubview(fullWaveformImageView)
        
    }

 
}

 
    
// MARK: - Scrubber Delegate
// Get progressupdate from AudioScrubberViewController to sync TimeSlider and Player
extension ViewController : ScrubberDelegate {
    
    func progressUpdatedTo(progress: CGFloat) {
        
        let asset = AVAsset(url: url)
        let duration = asset.duration
        let durationTime = CMTimeGetSeconds(duration)
        let timeValue = durationTime * Double(progress)
        timeSlider.value = Float(timeValue)
        let timeValueCMT = CMTimeMake(value: Int64(timeValue)*1000, timescale: 1000)
        player.seek(to: timeValueCMT)
        currentTimeLabel.text = getTimeString(from: timeValueCMT)
    }
    
}
    

//MARK: - VideoPlayer setup
extension ViewController {
 
    func setUpPlayerLayer() {
        
        //1. Create the asset to play
        asset = AVAsset(url: url)
        
        //2. playerItem set-up
        playerItem = AVPlayerItem(asset: asset, automaticallyLoadedAssetKeys: requiredAssetKeys)
        
        //3. Load Player
        player = AVPlayer(url: url)
        
        //4. Set-Up playerLayer
        playerLayer = AVPlayerLayer(player: player)
        videoView.layer.addSublayer(playerLayer)
        
        //5. Set-up Frame
        playerLayer.frame = self.videoView.bounds
        
        //6. Add observer
        addTimeObserver()
        
        // Update labels and sliders
        durationLabel.text = self.getTimeString(from: asset.duration)
        timeSlider.maximumValue = Float(asset.duration.seconds)
        timeSlider.minimumValue = 0.0
        
        
    }
    

    func addTimeObserver() {
        
        let interval = CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        let mainQueue = DispatchQueue.main
        _ = player.addPeriodicTimeObserver(forInterval: interval, queue: mainQueue, using: { [weak self] time in
            guard let currentItem = self?.player.currentItem else {return}
            
            self?.timeSlider.value = Float(currentItem.currentTime().seconds)
            self?.currentTimeLabel.text = self?.getTimeString(from: currentItem.currentTime())
            
            let progressVideoPercent = Float(currentItem.currentTime().seconds / currentItem.duration.seconds)
            NotificationCenter.default.post(name: AudioScrubberController.passingVideoCurrentTime, object: nil, userInfo: ["currentTime": progressVideoPercent])
            
        })
    }

}

// MARK: - IBActions
extension ViewController {
    
    @IBAction func playPressed(_ sender: UIButton) {
        changeStatusVideoPlay()
    }
    
    func changeStatusVideoPlay(){
        if isVideoPlaying {
            player.pause()
            buttonPlay.setTitle("Play", for: .normal)
        }else {
            player.play()
            buttonPlay.setTitle("Pause", for: .normal)
        }
        
        isVideoPlaying = !isVideoPlaying
        
    }
    
    
    @IBAction func sliderValueChanged(_ sender: UISlider) {
        player.seek(to: CMTimeMake(value: Int64(sender.value*1000), timescale: 1000))
    }
    
    
    
    func getTimeString(from time: CMTime) -> String {
        let totalSeconds = CMTimeGetSeconds(time)
        
        let hours = Int(totalSeconds/3600)
        let minutes = Int(totalSeconds/60) % 60
        let seconds = Int(totalSeconds.truncatingRemainder(dividingBy: 60))
        if hours > 0 {
            return String(format: "%i:%02i:%02i", arguments: [hours,minutes,seconds])
        }else {
            return String(format: "%02i:%02i", arguments: [minutes,seconds])
        }
    }
    
    
}

//MARK: - ImageViewDelegate : Get Image from AudioScrubberViewDelegate
extension ViewController : ImageViewDelegate {
    
    //get image from AudioScrubberViewController
    func update(_ image:UIImage) {
        newImage = image
        self.displayWaveformAfterLoading()
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "UIStoryboardSegue" {
            let secondVC: AudioScrubberController = segue.destination as! AudioScrubberController
            secondVC.imageDelegate = self
        }
        
    }
    
}



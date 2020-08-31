//
//  ViewController.swift
//  VideoPlayer
//
//  Created by sparisot on 18/08/2020.
//  Copyright © 2020 Stéphane Parisot. All rights reserved.
//

import UIKit
import AVKit
import AVFoundation


//import FDWaveformView


class ViewController: UIViewController {

    @IBOutlet weak var slider: UISlider!
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var videoView: UIView!
    @IBOutlet weak var playButton: UIButton!

    
    var playerLayer = AVPlayerLayer()
    var player: AVPlayer? {
        return playerLayer.player
    }
    
    let url = Bundle.main.url(forResource: "silexvideo", withExtension: "mp4")!
    var rate : Float = 1
    var isPlaying: Bool {
                   return player?.rate != 0 && player?.error == nil
               }


    

    override func viewDidLoad() {
        super.viewDidLoad()

        setUpPlayerLayer()
        videoView.layer.addSublayer(playerLayer)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(ViewController.playerDidReachEndNotificationHandler(_:)),
            name: NSNotification.Name(rawValue: "AVPlayerItemDidPlayToEndTimeNotification"),
            object: player?.currentItem)
        playButton.setTitle("Pause", for: .normal)

        sliderUpdate()
            
//        waveDrawing()
        
        
//AudioKit Pod
//        let file = try! AKAudioFile(readFileName: "silexvideo.mp4", baseDir: .resources)
//        let fileTable = AKTable(file: file)

        
        
     
        
    }

  
//    override func viewDidAppear(_ animated: Bool) {
//        super.viewDidAppear(animated)
//
//       // partie sélectionnée.
//        UIView.animate(withDuration: 0.3, animations: {
//            let random = Int.random(in: 0..<self.waveform.totalSamples)
//                self.waveform.highlightedSamples = 0 ..< random
//
//        })
                
//    }
    

}

//MARK: - Layer setup
extension ViewController {
    func setUpPlayerLayer() {
        
        //1
        playerLayer.frame = self.videoView.bounds

        //2
        let item = AVPlayerItem(asset: AVAsset(url: url))
        let player = AVPlayer(playerItem: item)

        //3
        player.actionAtItemEnd = .none

        //4
        player.volume = 1.0
        player.rate = 1.0
        
        playerLayer.player = player
        
        }
}

// MARK: - IBActions
extension ViewController {
  @IBAction func playButtonTapped(_ sender: Any) {
    if player?.rate == 0 {
      player?.rate = rate
      updatePlayButtonTitle(isPlaying: true)
    } else {
      player?.pause()
      updatePlayButtonTitle(isPlaying: false)
    }
  }
    

    
   @IBAction func sliderAction(_ sender: Any) {
        player?.seek(to: CMTime(seconds: Double(slider.value), preferredTimescale: 1000))
        self.label.text = String(format:"%.0f",slider.value)

    }

}

// MARK: - Triggered actions
extension ViewController {
  @objc func playerDidReachEndNotificationHandler(_ notification: Notification) {
    // 1
    guard let playerItem = notification.object as? AVPlayerItem else { return }

    // 2
    playerItem.seek(to: .zero, completionHandler: nil)

    // 3
    if player?.actionAtItemEnd == .pause {
      player?.pause()
     updatePlayButtonTitle(isPlaying: false)
    }
  }
    
    
    func sliderUpdate() {
        // Paramétrage du Slider
        slider.maximumValue = Float(player?.currentItem?.asset.duration.seconds ?? 0)
        
        
        player?.addPeriodicTimeObserver(forInterval: CMTime(seconds: 1, preferredTimescale: 1000), queue: DispatchQueue.main, using: { (time) in
            self.label.text = String(format:"%.0f",time.seconds)
            self.slider.value = Float(time.seconds)
        })
    }
    
//    func waveDrawing() {
//        // WaveForm
//
//                // Animate the waveform view when it is rendered
//     //           waveform.delegate = self
//                waveform.alpha = 1.0
//                waveform.audioURL = url
//                waveform.zoomSamples = 0 ..< waveform.totalSamples / 10
//                waveform.doesAllowScrubbing = true
//                waveform.doesAllowStretch = true
//                waveform.doesAllowScroll = true
//                
//                
//            
//                
//        //        waveform.wavesColor = UIColor.blue
//        //        waveform.layer.borderWidth = 1
//        //        waveform.layer.borderColor = UIColor.black.cgColor
//        //        waveform.layer.cornerRadius = 0
//        //        waveform.isHidden = false
//        //        waveform.isUserInteractionEnabled = true
//        //        waveform.doesAllowScroll = true
//        //        waveform.progressColor = .green
//    }

}

// MARK: - Helpers
extension ViewController {
  func updatePlayButtonTitle(isPlaying: Bool) {
    if isPlaying {
      playButton.setTitle("Pause", for: .normal)
    } else {
      playButton.setTitle("Play", for: .normal)
    }
  }
}









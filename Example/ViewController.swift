//
//  ViewController.swift
//  Example
//
//  Created by happts on 2019/9/5.
//  Copyright © 2019 happts. All rights reserved.
//

import UIKit
import WaterMarkMaker
import AVFoundation

class ViewController: UIViewController {

    @IBOutlet weak var playView: UIView!
    @IBOutlet weak var playBtn: UIButton!
    @IBOutlet weak var addWaterMarkBtn: UIButton!
    @IBOutlet weak var replayBtn: UIButton!
    
    var player:AVPlayer! {
        didSet {
            let playLayer = AVPlayerLayer(player: player)
            playLayer.frame = CGRect(origin: .zero, size: playView.frame.size)
            playView.layer.addSublayer(playLayer)
            playLayer.videoGravity = .resizeAspect
        }
    }
    var videoURL:URL!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let testmovPath = Bundle.main.path(forResource: "testmov", ofType: "mp4")
        let testmovURL = URL(fileURLWithPath: testmovPath!)
        videoURL = testmovURL
        player = AVPlayer(url: testmovURL)
    }

    @IBAction func addAction(_ sender: Any) {
        let maker = WaterMarkMaker.shared
        let asset = WaterMarkURLAsset(url: self.videoURL)
        let waterMarks = maker.generateRandomWaterMarks(asset: asset, watermarkImage: UIImage(named: "waterImg")!)
        
        maker.addWaterMark(asset: asset, watermarks: waterMarks)
        
        asset.exporter.export { (result) in
            switch result {
            case .success(let url):
                self.videoURL = url
                self.player = AVPlayer(url: url)
                
                let alert = UIAlertController(title: "success", message: "success", preferredStyle: .alert)
                let okAlertAction = UIAlertAction(title: "ok", style: .default, handler: nil)
                alert.addAction(okAlertAction)
                self.present(alert, animated: true, completion: nil)
            case .failure(let error):
                let alert = UIAlertController(title: "error", message: error.localizedDescription, preferredStyle: .alert)
                let okAlertAction = UIAlertAction(title: "ok", style: .default, handler: nil)
                alert.addAction(okAlertAction)
                self.present(alert, animated: true, completion: nil)
            }
        }
    }
    
    @IBAction func playAction(_ sender: Any) {
        player.play()
    }
    @IBAction func replayAction(_ sender: Any) {
        player.seek(to: CMTime(value: 0, timescale: 1))
    }
    
}


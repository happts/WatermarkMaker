//
//  WaterMarkURLAsset.swift
//  WaterMarkMaker
//
//  Created by happts on 2019/9/26.
//  Copyright © 2019 happts. All rights reserved.
//

import AVFoundation

open class WaterMarkURLAsset:AVURLAsset {
    
    static let videoID:CMPersistentTrackID = 0xBBBB
    static let audioID:CMPersistentTrackID = 0xFFFF
    
    var videoTrack:AVAssetTrack!
    var audioTrack:AVAssetTrack?
    var mixedComposition = AVMutableComposition()
    
    let parentLayer = CALayer()
    let videoLayer = CALayer()
    
    /// videoTrack is required
    /// 必须有图像
    public init(url:URL) {
        super.init(url: url, options: [AVURLAssetPreferPreciseDurationAndTimingKey:true])
        self.audioTrack = self.tracks(withMediaType: .audio).first
        self.videoTrack = self.tracks(withMediaType: .video).first!
        
        initComposition()
        
        parentLayer.frame = CGRect(origin: .zero, size: videoTrack.naturalSize)
        videoLayer.frame = CGRect(origin: .zero, size: videoTrack.naturalSize)
        parentLayer.isGeometryFlipped = true
        parentLayer.addSublayer(videoLayer)
    }
    
    private func initComposition() {
        mixedComposition.addMutableTrack(withMediaType: .video, preferredTrackID: WaterMarkURLAsset.videoID)
        try! mixedComposition.track(withTrackID: WaterMarkURLAsset.videoID)!.insertTimeRange(CMTimeRange(start: .zero, duration: videoTrack.asset!.duration), of: videoTrack, at: .zero)
        mixedComposition.track(withTrackID: WaterMarkURLAsset.videoID)!.preferredTransform = videoTrack.preferredTransform
        
        if audioTrack != nil {
            mixedComposition.addMutableTrack(withMediaType: .audio, preferredTrackID: WaterMarkURLAsset.audioID)
            try! mixedComposition.track(withTrackID: WaterMarkURLAsset.audioID)!.insertTimeRange(CMTimeRange(start: .zero, duration: audioTrack!.asset!.duration), of: audioTrack!, at: .zero)
        }
    }
    
    open func generateVideoComposition() ->AVMutableVideoComposition {
        let videoComp = AVMutableVideoComposition()
        videoComp.renderSize = videoTrack.naturalSize
        videoComp.frameDuration = CMTime(value: 1, timescale: 30)
        videoComp.animationTool = AVVideoCompositionCoreAnimationTool(postProcessingAsVideoLayer: videoLayer, in: videoLayer.superlayer!)
        videoComp.instructions = [
            {
                let instruction = AVMutableVideoCompositionInstruction()
                instruction.timeRange = CMTimeRangeMake(start: .zero, duration: mixedComposition.track(withTrackID: WaterMarkURLAsset.videoID)!.asset!.duration)
                
                let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: mixedComposition.track(withTrackID: WaterMarkURLAsset.videoID)!)
                instruction.layerInstructions = [layerInstruction]
                return instruction
            }()
        ]
        return videoComp
    }
}

extension WaterMarkURLAsset {
    public var exporter:WaterMarkVideoExporter {
        let videoComp = self.generateVideoComposition()
        let exporter = WaterMarkVideoExporter(asset: self.mixedComposition, videoComposition: videoComp)
        return exporter
    }
}

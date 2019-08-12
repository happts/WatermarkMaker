//
//  WaterMarker.swift
//  AddWaterRemark
//
//  Created by happts on 2019/8/6.
//  Copyright © 2019 happts. All rights reserved.
//

import Foundation
import AVFoundation
import UIKit

/// 水印
/// - view: 要添加为水印的UIView
/// - beginTime: 水印出现的时间
/// - duration: 水印持续的时间
/// - animationGroup: 水印带有的动画效果
///
/// animationGroup 为nil时,默认存在水印的出现与消失动画,
///
/// 否则需要自行添加到group中,可通过opacityAnimation添加
struct WaterMark {
    let view:UIView
    let beginTime:CFTimeInterval
    let duration:CFTimeInterval
    
    var animationGroup:CAAnimationGroup? = nil
}

class WaterMarkMaker {
    
    static let videoID:CMPersistentTrackID = 0xBBBB
    static let audioID:CMPersistentTrackID = 0xFFFF
    
    enum Result {
        case success(URL)
        case failure(Error)
    }
    
    enum WaterMarkerError:Error {
        case assetTrackNil
        case exporterNil
        case exportError
    }
    
    
    /*
     生成过程:
     1. 读取原视频assets 的视频轨与音频轨 assetTracks
     2. 生成mixComposition(最终输出素材),将原视频的两条轨添加进去
     3. 生成Layer,parentLayer包含了水印layer和videoLayer, videoLayer一层用于播放视频
     4. 对视频的一些加工指令整合到videoComp
     5. 得到用于输出视频文件的exporter
    */
    /// 生成带有水印的视频
    ///
    /// - Parameters:
    ///   - asset: 原始视频
    ///     - 可以通过URL生成AVURLAsset
    ///     - 传递参数 [AVURLAssetPreferPreciseDurationAndTimingKey:true]
    ///   - watermarks: 要添加的多个水印,水印数组
    ///   - completion: 视频生成完成的回调
    func addWaterMark(asset:AVAsset,watermarks:[WaterMark],completion:@escaping (Result)->Void) {
        do {
            let assetTracks = try getTracks(from: asset)
            let mixComposition = try initComposition(assetTracks: assetTracks)
            
            let parentLayer = CALayer()
            let videoLayer = CALayer()
            parentLayer.frame = CGRect(origin: .zero, size: assetTracks.videoTrack.naturalSize)
            videoLayer.frame = CGRect(origin: .zero, size: assetTracks.videoTrack.naturalSize)
            parentLayer.addSublayer(videoLayer)
            
            for watermark in watermarks {
                let watermarkLayer = generateWaterMarkLayer(watermark: watermark)
                parentLayer.addSublayer(watermarkLayer)
            }
            
            parentLayer.isGeometryFlipped = true
            
            let videoComp = generateVideoComposition(size: assetTracks.videoTrack.naturalSize, mixComposition: mixComposition, videoLayer: videoLayer)
            let exporter = try Exporter(asset: mixComposition, videoComposition: videoComp)
            
            exporter.exportAsynchronously {
                DispatchQueue.main.async {
                    if let outputError = exporter.error {
                        let result = Result.failure(outputError)
                        completion(result)
                        return
                    }else {
                        let result = Result.success(exporter.outputURL!)
                        completion(result)
                        return
                    }
                }
            }
        } catch {
            let result = Result.failure(error)
            completion(result)
            return
        }
    }
    
    ///覆盖整个视频时长的水印,2~6秒变换一次位置,两个位置固定
    @available(*,deprecated)
    func autoAddWaterMark(asset:AVAsset,watermarkImage:UIImage,imageSize:CGSize) throws -> [WaterMark]{
        let seconds = Double(CMTimeGetSeconds(asset.duration))
        print(seconds)
        let size = try getTracks(from: asset).videoTrack.naturalSize
        print(size)
        
        var watermarks:[WaterMark] = []
        
        var current = 0.01
        var flag = Bool.random()
        
        let leftP = CGPoint(x: 12.0/2 ,y: 12.0/2)
        let rightP = CGPoint(x: size.width/2.0 - 12.0/2 - imageSize.width/2, y: 12.0/2)
        
        while current < seconds {
            let duration = Double.random(in: 2...6)
            let imageview = UIImageView(image: watermarkImage)
            imageview.frame = CGRect(origin: flag ? leftP : rightP, size: imageSize)
            imageview.contentMode = .scaleAspectFill
            
            let waterMark = WaterMark(view: imageview, beginTime: current, duration: duration, animationGroup: nil)
            watermarks.append(waterMark)
            
            current += duration
            flag.toggle()
        }
        
        return watermarks
    }
    
    // MARK: 私有方法
    
    private func getTracks(from asset:AVAsset) throws -> (videoTrack:AVAssetTrack,audioTrack:AVAssetTrack){
        guard let audioAssetTrack = asset.tracks(withMediaType: .audio).first ,let videoAssetTrack = asset.tracks(withMediaType: .video).first else {
            throw WaterMarkerError.assetTrackNil
        }
        return (videoAssetTrack,audioAssetTrack)
    }
    
    private func initComposition(assetTracks:(videoTrack:AVAssetTrack,audioTrack:AVAssetTrack)) throws -> AVMutableComposition {
        let mixComposition = initComposition()
        try mixComposition.track(withTrackID: WaterMarkMaker.audioID)!.insertTimeRange(CMTimeRange(start: .zero, duration: assetTracks.audioTrack.asset!.duration), of: assetTracks.audioTrack, at: .zero)
        try mixComposition.track(withTrackID: WaterMarkMaker.videoID)!.insertTimeRange(CMTimeRange(start: .zero, duration: assetTracks.videoTrack.asset!.duration), of: assetTracks.videoTrack, at: .zero)
        mixComposition.track(withTrackID: WaterMarkMaker.videoID)!.preferredTransform = assetTracks.videoTrack.preferredTransform
        return mixComposition
    }
    
    private func initComposition() -> AVMutableComposition {
        let mixComposition = AVMutableComposition()
        mixComposition.addMutableTrack(withMediaType: .video, preferredTrackID: WaterMarkMaker.videoID)
        mixComposition.addMutableTrack(withMediaType: .audio, preferredTrackID: WaterMarkMaker.audioID)
        return mixComposition
    }
    
    private func generateOutputFileURL() -> URL {
        let documentsDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMddHHmmss"
        let outPutFileName = "SnapVideo" + formatter.string(from: Date(timeIntervalSinceNow: 0))
        let myPathDocs = (documentsDirectory as NSString).appendingPathComponent("\(outPutFileName).mp4")
        let outputVideoURL = URL(fileURLWithPath: myPathDocs)
        return outputVideoURL
    }
    
    ///layer长时间透明,只有在对应的动画时间内才出现,所以动画中需要设置opacity
    private func generateWaterMarkLayer(view:UIView,beginTime:CFTimeInterval,duration:CFTimeInterval) -> CALayer{
        let layer = CALayer()
        layer.addSublayer(view.layer)
        layer.frame = view.frame
        layer.opacity = 0
        
        let basicAnimation = opacityAnimation(beginTime: beginTime, duration: duration)
        layer.add(basicAnimation, forKey: nil)
        return layer
    }
    
    private func generateWaterMarkLayer(watermark:WaterMark) -> CALayer {
        
        let basicAnimation = opacityAnimation(beginTime: watermark.beginTime, duration: watermark.duration)

        let layer = CALayer()
        layer.addSublayer(watermark.view.layer)
        layer.frame = watermark.view.frame
        layer.opacity = 0
        
        layer.add(watermark.animationGroup ?? basicAnimation, forKey: nil)
        return layer
    }
    
    private func generateVideoComposition(size:CGSize,mixComposition:AVMutableComposition,videoLayer:CALayer) ->AVMutableVideoComposition {
        let videoComp = AVMutableVideoComposition()
        videoComp.renderSize = size
        
        videoComp.frameDuration = CMTime(value: 1, timescale: 30)
        videoComp.animationTool = AVVideoCompositionCoreAnimationTool(postProcessingAsVideoLayer: videoLayer, in: videoLayer.superlayer!)
        videoComp.instructions = [
            {
                let instruction = AVMutableVideoCompositionInstruction()
                instruction.timeRange = CMTimeRangeMake(start: .zero, duration: mixComposition.track(withTrackID: WaterMarkMaker.videoID)!.asset!.duration)
                
                let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: mixComposition.track(withTrackID: WaterMarkMaker.videoID)!)
                instruction.layerInstructions = [layerInstruction]
                return instruction
            }()
        ]
        return videoComp
    }
    
    private func Exporter(asset:AVAsset,videoComposition:AVVideoComposition) throws ->AVAssetExportSession{
        guard let exporter = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality) else {
            throw WaterMarkerError.exporterNil
        }
        exporter.outputURL = generateOutputFileURL()
        exporter.outputFileType = .mp4
        exporter.shouldOptimizeForNetworkUse = true
        exporter.videoComposition = videoComposition
        return exporter
    }
    
    
    // - MARK: 不再使用
    /// 生成水印视频
    ///
    /// - Parameters:
    ///   - inputURL: 输入视频文件的url
    ///   - watermarkView: 待添加水印的View
    ///   - beginTime: 水印出现时间
    ///   - duration: 水印存在时间
    ///   - completion: 视频文件生成完毕的回调
    ///
    /// watermarkView的frame即为水印在视频出现的位置
    @available(*,deprecated)
    func addWaterMark(inputURL:URL,watermarkView:UIView,beginTime:CFTimeInterval,duration:CFTimeInterval,completion:@escaping (Result)->Void) {
        do {
            let asset = AVURLAsset(url: inputURL, options: [AVURLAssetPreferPreciseDurationAndTimingKey:true])
            let assetTracks = try getTracks(from: asset)
            let mixComposition = initComposition()
            
            try mixComposition.track(withTrackID: WaterMarkMaker.audioID)!.insertTimeRange(CMTimeRange(start: .zero, duration: assetTracks.audioTrack.asset!.duration), of: assetTracks.audioTrack, at: .zero)
            try mixComposition.track(withTrackID: WaterMarkMaker.videoID)!.insertTimeRange(CMTimeRange(start: .zero, duration: assetTracks.videoTrack.asset!.duration), of: assetTracks.videoTrack, at: .zero)
            
            mixComposition.track(withTrackID: WaterMarkMaker.videoID)!.preferredTransform = assetTracks.videoTrack.preferredTransform
            
            let parentLayer = CALayer()
            let videoLayer = CALayer()
            
            parentLayer.frame = CGRect(origin: .zero, size: assetTracks.videoTrack.naturalSize)
            videoLayer.frame = CGRect(origin: .zero, size: assetTracks.videoTrack.naturalSize)
            
            let waterMarkLayer = generateWaterMarkLayer(view: watermarkView, beginTime: beginTime, duration: duration)
            parentLayer.addSublayer(videoLayer)
            parentLayer.addSublayer(waterMarkLayer)
            parentLayer.isGeometryFlipped = true
            
            let videoComp = generateVideoComposition(size: assetTracks.videoTrack.naturalSize, mixComposition: mixComposition, videoLayer: videoLayer)
            let exporter = try Exporter(asset: mixComposition, videoComposition: videoComp)
            
            exporter.exportAsynchronously {
                DispatchQueue.main.async {
                    if let outputError =  exporter.error {
                        let result = Result.failure(outputError)
                        completion(result)
                        return
                    }else {
                        let result = Result.success(exporter.outputURL!)
                        print(exporter.outputURL!)
                        completion(result)
                        return
                    }
                }
            }
            
        } catch {
            let result = Result.failure(error)
            completion(result)
            return
        }
    }
}

extension WaterMarkMaker {
    func opacityAnimation(beginTime:CFTimeInterval,duration:CFTimeInterval) -> CABasicAnimation{
        let basicAnimation = CABasicAnimation(keyPath: "opacity")
        basicAnimation.fromValue = 1
        basicAnimation.toValue = 1
        basicAnimation.beginTime = beginTime
        basicAnimation.duration = duration
        basicAnimation.repeatCount = 1
        basicAnimation.isRemovedOnCompletion = true
        basicAnimation.fillMode = .removed
        return basicAnimation
    }
}

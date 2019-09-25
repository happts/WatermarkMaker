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

/// 水印,无动画效果时为透明
/// - view: 要添加为水印的UIView
/// - beginTime: 水印出现的时间
/// - duration: 水印持续的时间
/// - animationGroup: 水印带有的动画效果
///
/// animationGroup 为nil时,默认存在水印的出现与消失动画,
///
/// 否则需要自行添加到group中,可通过opacityAnimation添加
public struct WaterMark {
    /// view.frame is required
    public let view:UIView
    public let beginTime:CFTimeInterval
    public let duration:CFTimeInterval
    
    public var animationGroup:CAAnimationGroup?
    
    public init(view:UIView,beginTime:CFTimeInterval,duration:CFTimeInterval,animationGroup:CAAnimationGroup? = nil){
        self.view = view
        self.beginTime = beginTime
        self.duration = duration
        self.animationGroup = animationGroup
    }
}

public enum Result {
    case success(URL)
    case failure(Error)
}

/// 生成水印视频
public class WaterMarkMaker {
    
    public static let shared = WaterMarkMaker()
    
    private init(){
        
    }
    
    static let videoID:CMPersistentTrackID = 0xBBBB
    static let audioID:CMPersistentTrackID = 0xFFFF
    
    public enum WaterMarkerError:Error {
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
    public func addWaterMark(asset:AVAsset,watermarks:[WaterMark],completion:@escaping (Result)->Void) {
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
    ///传入视频和水印图片,自动生成填充整个视频的随机时间位置的水印组
    /// 目前只针对16:9视频使用
    public func generateRandomWaterMarks(asset:AVAsset,watermarkImage:UIImage) throws -> [WaterMark]{
        let seconds = Double(CMTimeGetSeconds(asset.duration))
        
        let size = try getTracks(from: asset).videoTrack.naturalSize
        
        var watermarks:[WaterMark] = []
        
        struct Scale {
            let size:(width:CGFloat,height:CGFloat)
            let leftP:(x:CGFloat,y:CGFloat)
            let rightP:(x:CGFloat,y:CGFloat)
        }
        
        let horizonScale = Scale(size: (width: 166.0/1280, height: 64.0/720), leftP: (x: 24.0/1280, y: 24.0/720), rightP: (x: 1-((166+24)/1280.0), y: 24.0/720))
        let verticalScale = Scale(size: (width:166.0/720,height:64.0/1280), leftP: (x:24.0/720,y:24/1280.0), rightP: (x:1-((166+24)/720.0),y:24/1280.0))
        
        var current = 0.01
        var flag = Bool.random()
        var leftP:CGPoint!
        var rightP:CGPoint!
        
        let scale = size.width > size.height ? horizonScale : verticalScale
        let waterMarkSize = CGSize(width: size.width * scale.size.width, height: size.height * scale.size.height)
        leftP = CGPoint(x: size.width * scale.leftP.x * 0.5, y: size.height * scale.leftP.y * 0.5)
        rightP = CGPoint(x: size.width * scale.rightP.x * 0.5, y: size.height * scale.rightP.y * 0.5)
        
        
        while current < seconds {
            let duration = Double.random(in: 2...3)
            
            let imageview = UIImageView(image: watermarkImage)
            imageview.frame = CGRect(origin: flag ? leftP : rightP, size: waterMarkSize)
            imageview.contentMode = .scaleAspectFill
            
            let waterMark = WaterMark(view: imageview, beginTime: current, duration: duration, animationGroup: nil)
            watermarks.append(waterMark)
            
            current += duration
            flag.toggle()
        }
        
        return watermarks
    }
    
    // MARK: 私有方法
    
    private func getTracks(from asset:AVAsset) throws -> (videoTrack:AVAssetTrack,audioTrack:AVAssetTrack?){
        let audioAssetTrack = asset.tracks(withMediaType: .audio).first
        guard let videoAssetTrack = asset.tracks(withMediaType: .video).first else {
            throw WaterMarkerError.assetTrackNil
        }
        return (videoAssetTrack,audioAssetTrack)
    }
    
    private func initComposition(assetTracks:(videoTrack:AVAssetTrack,audioTrack:AVAssetTrack?)) throws -> AVMutableComposition {
        let mixComposition = initComposition()
        
        if let audioTrack = assetTracks.audioTrack {
            try mixComposition.track(withTrackID: WaterMarkMaker.audioID)!.insertTimeRange(CMTimeRange(start: .zero, duration: audioTrack.asset!.duration), of: audioTrack, at: .zero)
        }else {
            mixComposition.removeTrack(mixComposition.tracks(withMediaType: .audio).first!)
        }
        
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
        let outPutFileName = "WaterMarkVideo" + formatter.string(from: Date(timeIntervalSinceNow: 0))
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
}

extension WaterMarkMaker {
    open func opacityAnimation(beginTime:CFTimeInterval,duration:CFTimeInterval) -> CABasicAnimation{
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

//
//  WaterMarker.swift
//  AddWaterRemark
//
//  Created by happts on 2019/8/6.
//  Copyright © 2019 happts. All rights reserved.
//

/*
 生成过程:
 1. 读取原视频assets 的视频轨与音频轨 assetTracks
 2. 生成mixComposition(最终输出素材),将原视频的两条轨添加进去
 3. 生成Layer,parentLayer包含了水印layer和videoLayer, videoLayer一层用于播放视频
 4. 对视频的一些加工指令整合到videoComp
 5. 得到用于输出视频文件的exporter
 */

import Foundation
import AVFoundation
import UIKit

/// 为视频添加水印
public class WaterMarkMaker {
    
    public static let shared = WaterMarkMaker()
    
    private init(){ }
    
    /// 生成带有水印的视频
    ///
    /// - Parameters:
    ///   - asset: 原始视频
    ///   - watermarks: 要添加的多个水印,水印数组
    public func addWaterMark(asset:WaterMarkURLAsset,watermarks:[WaterMark]){
        for watermark in watermarks {
            let layer = generateWaterMarkLayer(watermark: watermark)
            asset.parentLayer.addSublayer(layer)
        }
    }

    private func generateWaterMarkLayer(watermark:WaterMark) -> CALayer {
        watermark.layer.add(watermark.animation, forKey: nil)
        return watermark.layer
    }
}

extension WaterMarkMaker {
    /// 传入视频和水印图片,自动生成填充整个视频的随机时间位置的水印组
    open func generateRandomWaterMarks(asset:WaterMarkURLAsset,watermarkImage:UIImage) -> [WaterMark]{
        let videoSize = asset.videoTrack.naturalSize
        
        var watermarks:[WaterMark] = []
        
        var currentTime = 0.01
        var flag = Bool.random()
        
        let scale:WaterMarkScale = videoSize.width > videoSize.height ? .videoHorizon16to9 : .videoVertical16to9
        
        while currentTime < Double(CMTimeGetSeconds(asset.duration)) {
            let duration = Double.random(in: 2...3)
            
            let imageLayer = scale.generateWaterMarkLayer(image: watermarkImage, videoSize: videoSize, positionName: flag ? "leftTop" : "rightTop")
            
            let waterMark = WaterMark(layer: imageLayer, beginTime: currentTime, duration: duration)
            watermarks.append(waterMark)
            
            currentTime += duration
            flag.toggle()
        }
        
        return watermarks
    }
}

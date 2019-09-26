//
//  WaterMarkScale.swift
//  WaterMarkMaker
//
//  Created by happts on 2019/9/25.
//  Copyright © 2019 happts. All rights reserved.
//

import Foundation

/// Set parameters according to the UI draft
open class WaterMarkScale {
    public var originalVideoSize:CGSize
    public var waterMarkSize:CGSize
    public var positions:[String:CGPoint]
    
    public init(videoSize:CGSize,originalWaterMarkSize:CGSize,positions:[String:CGPoint]) {
        self.originalVideoSize = videoSize
        self.waterMarkSize = originalWaterMarkSize
        self.positions = positions
    }
    
    public func addPosition(name:String,point:CGPoint) {
        positions[name] = point
    }
}

extension WaterMarkScale {
    public func scaledFrame(videoSize:CGSize,positionName:String) ->CGRect {
        return CGRect(origin: scaledPosition(videoSize: videoSize, name: positionName), size: scaledSize(videoSize: videoSize))
    }
    
    public func scaledSize(videoSize:CGSize) -> CGSize {
        return CGSize(width: videoSize.width*widthScalingfactor, height: videoSize.height*heightScalingfactor)
    }
    
    public func scaledPosition(videoSize:CGSize,name:String) -> CGPoint {
        let factor = pointScalingfactor(name: name)
        return CGPoint(x: videoSize.width*factor.xScalingfactor, y: videoSize.height*factor.yScalingfactor)
    }
    
    private var widthScalingfactor:CGFloat { return waterMarkSize.width/originalVideoSize.width }
    private var heightScalingfactor:CGFloat { return waterMarkSize.height/originalVideoSize.height }
    
    private func pointScalingfactor(name:String) -> (xScalingfactor:CGFloat,yScalingfactor:CGFloat){
        let point = positions[name]!
        return (point.x/originalVideoSize.width,point.y/originalVideoSize.height)
    }
}

extension WaterMarkScale {
    open class var videoVertical16to9:WaterMarkScale {
        return WaterMarkScale(videoSize: CGSize(width: 720, height: 1280), originalWaterMarkSize: CGSize(width: 166, height: 64), positions: [
            "leftTop":CGPoint(x: 24, y: 24),
            "rightTop":CGPoint(x: 530, y: 24)
            ])
    }
    
    open class var video9to16:WaterMarkScale {
        return videoVertical16to9
    }
    
    open class var videoHorizon16to9:WaterMarkScale {
        return WaterMarkScale(videoSize: CGSize(width: 1280, height: 720), originalWaterMarkSize: CGSize(width: 166, height: 64), positions: [
            "leftTop":CGPoint(x: 24, y: 24),
            "rightTop":CGPoint(x: 1090, y: 24)
            ])
    }
    
    open class var video16to9:WaterMarkScale {
        return videoHorizon16to9
    }
}

extension WaterMarkScale {
    public func generateWaterMarkLayer(image:UIImage,videoSize:CGSize,positionName:String) ->CALayer {
        let layer = CALayer()
        layer.frame = scaledFrame(videoSize: videoSize, positionName: positionName)
        layer.contents = image.cgImage
        layer.contentsGravity = .resizeAspect
        layer.isGeometryFlipped = true
        return layer
    }
}

//
//  WaterMark.swift
//  WaterMarkMaker
//
//  Created by happts on 2019/9/26.
//  Copyright © 2019 happts. All rights reserved.
//

import Foundation

/// 水印,无动画效果时为透明
/// - view: 要添加为水印的UIView
/// - beginTime: 水印出现的时间
/// - duration: 水印持续的时间
/// - animation: 水印带有的动画效果
///
/// animation 为nil时,默认存在水印的出现与消失动画,
///
public struct WaterMark {
    /// frame is required
    public let layer:CALayer
    public let beginTime:CFTimeInterval
    public let duration:CFTimeInterval
    
    public var animation:CAAnimation!
    
    public init(view:UIView,beginTime:CFTimeInterval,duration:CFTimeInterval,animation:CAAnimation? = nil){
        self.layer = view.layer
        self.layer.opacity = 0 //默认layer长时间透明,只有在对应的动画时间内才出现, 动画中需要设置opacity,让水印layer出现
        self.beginTime = beginTime
        self.duration = duration
        if let anim = animation {
            self.animation = anim
        }else {
            self.animation = basicAnimation
        }
    }
    
    public init(layer:CALayer,beginTime:CFTimeInterval,duration:CFTimeInterval,animation:CAAnimation? = nil){
        self.layer = layer
        self.layer.opacity = 0
        self.beginTime = beginTime
        self.duration = duration
        if let anim = animation {
            self.animation = anim
        }else {
            self.animation = basicAnimation
        }
    }
    
    var basicAnimation:CABasicAnimation {
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

//
//  WaterMarkVideoExporter.swift
//  WaterMarkMaker
//
//  Created by happts on 2019/9/25.
//  Copyright © 2019 happts. All rights reserved.
//

import Foundation
import AVFoundation

public enum WaterMarkVideoExportResult {
    case success(URL)
    case failure(Error)
}

open class WaterMarkVideoExporter:AVAssetExportSession {
    public override init?(asset: AVAsset, presetName: String) {
        super.init(asset: asset, presetName: presetName)
    }
    
    public init(asset:AVAsset,presetName:String = AVAssetExportPresetHighestQuality,videoComposition:AVVideoComposition) {
        super.init(asset: asset, presetName: presetName)!
        self.videoComposition = videoComposition
        self.outputURL = generateOutputFileURL()
        self.outputFileType = .mp4
        self.shouldOptimizeForNetworkUse = true
    }
    
    public func export(completion:@escaping (WaterMarkVideoExportResult)->Void){
        self.exportAsynchronously {
            DispatchQueue.main.async {
                if let outputError = self.error {
                    let result = WaterMarkVideoExportResult.failure(outputError)
                    completion(result)
                    return
                }else {
                    let result = WaterMarkVideoExportResult.success(self.outputURL!)
                    completion(result)
                    return
                }
            }
        }
    }
}

extension WaterMarkVideoExporter {
    open func generateOutputFileURL() -> URL {
        let documentsDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMddHHmmss"
        let outPutFileName = "WaterMarkVideo" + formatter.string(from: Date(timeIntervalSinceNow: 0))
        let myPathDocs = (documentsDirectory as NSString).appendingPathComponent("\(outPutFileName).mp4")
        let outputVideoURL = URL(fileURLWithPath: myPathDocs)
        return outputVideoURL
    }
}

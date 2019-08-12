# WatermarkMaker
 A Swift WatermarkMaker for iOS
 
 简易的视频水印添加工具


## Usage

### QuickStart
```
let water = WaterMarkMaker()

let asset = AVURLAsset(url: videourl, options: [AVURLAssetPreferPreciseDurationAndTimingKey:true])
let autoWM = try! water.autoAddWaterMark(asset: asset, watermarkImage: UIImage(named: "test")!, imageSize: CGSize(width: 80, height: 80))
    
water.addWaterMark(asset: asset, watermarks: autoWM) { (result) in
    switch result {
    case .success(let outputURL):
        print("success")
    case .failure(let error):
        print(error.localizedDescription)
    }
}

```

### how to use

1. init WaterMarkMaker

	`let water = WaterMarkMaker()`
2. init your WaterMarkView (UIView)

	`let view1 = UILabel() //UIImage() etc`
3. init WaterMark
	
	```
	struct WaterMark {
	    let view:UIView
	    let beginTime:CFTimeInterval
	    let duration:CFTimeInterval
	    
	    var animationGroup:CAAnimationGroup? = nil
	}
	
	let watermark1 = WaterMark(view:view1,beginTime:1,duration2)
	```
4. addWaterMark
	
	```
	let asset = AVURLAsset(url: self.url, options: [AVURLAssetPreferPreciseDurationAndTimingKey:true])
	
	water.addWaterMark(asset: asset, watermarks: [watermark1,watermark2]) { (result) in
	    switch result {
	    case .success(let outputURL):
	        print("success")
	    case .failure(let error):
	        print(error.localizedDescription)
	    }
	}
	```        
	
##issues
1. `WaterMark.beginTime` should be greater than 0

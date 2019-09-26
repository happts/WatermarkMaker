# WatermarkMaker
 A Swift WatermarkMaker for iOS

 简易的视频水印添加工具
 
 工程中的Example供效果展示


## Usage

### QuickStart
```
let maker = WaterMarkMaker.shared
let asset = WaterMarkURLAsset(url: self.videoURL)
let waterMarks = maker.generateRandomWaterMarks(asset: asset, watermarkImage: UIImage(named: "waterImg")!)
    
maker.addWaterMark(asset: asset, watermarks: waterMarks)
    
asset.exporter.export { (result) in
    switch result {
	case .success(let outputURL):
        print("success")
    case .failure(let error):
        print(error.localizedDescription)
    }
}
```

### how to use

1. WaterMarkMaker

	`let maker = WaterMarkMaker.shared`
2. init your WaterMark

	`let view1 = UILabel() //UIImage() etc`
	
	`view.frame` is needed
3. generate a WaterMark
	
	```
	struct WaterMark {
    /// frame is required
    let layer: CALayer

    let beginTime: CFTimeInterval

    let duration: CFTimeInterval

    var animation: CAAnimation!

    init(view: UIView, beginTime: CFTimeInterval, duration: CFTimeInterval, animation: CAAnimation? = nil)

    init(layer: CALayer, beginTime: CFTimeInterval, duration: CFTimeInterval, animation: CAAnimation? = nil)
    }
	
	let watermark1 = WaterMark(view:view1,beginTime:1,duration:2)
	```
4. addWaterMark
	
	```
	let asset = WaterMarkURLAsset(url: self.videoURL)	
	maker.addWaterMark(asset: asset, watermarks: [watermark1,watermark2])
	```
5. exportVideo

	```
	asset.exporter.export { (result) in
	    switch result {
	    case .success(let outputURL):
	        print("success")
	    case .failure(let error):
	        print(error.localizedDescription)
	    }
	}
	```
	
## issues
1. `WaterMark.beginTime` should be greater than 0

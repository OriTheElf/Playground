//
//  UIImagePlus.swift
//  ExtensionDemo
//
//  Created by Choi on 2020/7/29.
//  Copyright © 2020 Choi. All rights reserved.
//

import UIKit
import Photos
import SpriteKit

extension UIImage {
    
    /// SwifterSwift: Create UIImage from color and size.
    /// 
    /// - Parameters:
    ///   - color: image fill color.
    ///   - size: image size.
    ///   - scale: 默认为屏幕的scale. 即最终图片的像素尺寸为size的宽高 × scale
    ///   - 注: 在SwifterSwift的实现基础上做了点改造
    convenience init(color: UIColor, size: CGSize, scale: CGFloat = UIScreen.main.scale) {
        let format = UIGraphicsImageRendererFormat()
        format.scale = scale
        guard let image = UIGraphicsImageRenderer(size: size, format: format).image(actions: { context in
            color.setFill()
            context.fill(context.format.bounds)
        }).cgImage else {
            self.init()
            return
        }
        self.init(cgImage: image)
    }
    
    var skTexture: SKTexture {
        SKTexture(image: self)
    }
    
    /// SwifterSwift: Average color for this image.
    var averageColor: UIColor? {
        // https://stackoverflow.com/questions/26330924
        guard let ciImage = ciImage ?? CIImage(image: self) else { return nil }
        
        // CIAreaAverage returns a single-pixel image that contains the average color for a given region of an image.
        let parameters = [kCIInputImageKey: ciImage, kCIInputExtentKey: CIVector(cgRect: ciImage.extent)]
        guard let outputImage = CIFilter(name: "CIAreaAverage", parameters: parameters)?.outputImage else {
            return nil
        }
        
        // After getting the single-pixel image from the filter extract pixel's RGBA8 data
        var bitmap = [UInt8](repeating: 0, count: 4)
        let workingColorSpace: Any = cgImage?.colorSpace ?? NSNull()
        let context = CIContext(options: [.workingColorSpace: workingColorSpace])
        context.render(outputImage,
                       toBitmap: &bitmap,
                       rowBytes: 4,
                       bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
                       format: .RGBA8,
                       colorSpace: nil)
        
        // Convert pixel data to UIColor
        return UIColor(red: CGFloat(bitmap[0]) / 255.0,
                       green: CGFloat(bitmap[1]) / 255.0,
                       blue: CGFloat(bitmap[2]) / 255.0,
                       alpha: CGFloat(bitmap[3]) / 255.0)
    }
    
	/// 给图片着色
	/// - Parameters:
	///   - tintColor: 要改变的颜色
	///   - blendMode: 着色模式
	/// - Returns: 着色后的图片
	func imageWith(tintColor: UIColor, blendMode: CGBlendMode = .overlay) -> UIImage? {
		UIGraphicsBeginImageContextWithOptions(size, false, UIScreen.main.scale)
		defer {
			UIGraphicsEndImageContext()
		}
		// 定义画布
		let canvas = CGRect(origin: .zero, size: size)
		tintColor.setFill()
		UIRectFill(canvas)
		draw(in: canvas, blendMode: blendMode, alpha: 1.0)
		if blendMode != .destinationIn {
			draw(in: canvas, blendMode: .destinationIn, alpha: 1.0)
		}
		return UIGraphicsGetImageFromCurrentImageContext()
		/* 备注:
		因为每次使用此方法绘图时，都使用了CG的绘制方法
		这就意味着每次调用都会是用到CPU的Offscreen drawing
		大量使用的话可能导致性能的问题（主要对于iPhone 3GS或之前的设备，可能同时处理大量这样的绘制调用的能力会有不足）。
		原文地址: https://onevcat.com/2013/04/using-blending-in-ios/
		*/
	}
	
	//将图片缩放成指定尺寸（多余部分自动删除）
	func scaled(to newSize: CGSize) -> UIImage? {
		//计算比例
		let aspectWidth  = newSize.width/size.width
		let aspectHeight = newSize.height/size.height
		let aspectRatio = max(aspectWidth, aspectHeight)
		
		//图片绘制区域
		var canvas = CGRect.zero
		canvas.size.width  = size.width * aspectRatio
		canvas.size.height = size.height * aspectRatio
		canvas.origin.x = (newSize.width - size.width * aspectRatio) / 2.0
		canvas.origin.y = (newSize.height - size.height * aspectRatio) / 2.0
		
		//绘制并获取最终图片
		UIGraphicsBeginImageContext(newSize)
		defer {
			UIGraphicsEndImageContext()
		}
		draw(in: canvas)
		return UIGraphicsGetImageFromCurrentImageContext()
	}
	
	func saveToPhotoLibrary(completionHandler: @escaping (Bool, Error?) -> Void) {
		PHPhotoLibrary.shared().performChanges {
			PHAssetChangeRequest.creationRequestForAsset(from: self)
		} completionHandler: { result, error in
			DispatchQueue.main.async {
				completionHandler(result, error)
			}
		}
	}
	
	func image(with insets: UIEdgeInsets) -> UIImage {
		UIGraphicsBeginImageContextWithOptions(size + insets, false, scale)
		let origin = CGPoint(x: insets.left, y: insets.top)
		draw(at: origin)
		defer {
			UIGraphicsEndImageContext()
		}
		return UIGraphicsGetImageFromCurrentImageContext().or(self)
	}
	
	/// 启动图截图
	static var launchScreenSnapshot: UIImage? {
		guard let infoDict = Bundle.main.infoDictionary else { return .none }
		guard let nameValue = infoDict["UILaunchStoryboardName"] else { return .none }
		guard let name = nameValue as? String else { return .none }
		let storyboard = UIStoryboard(name: name, bundle: .none)
		guard let vc = storyboard.instantiateInitialViewController() else { return .none }
		let screenSize = UIScreen.main.bounds.size
		let screenScale = UIScreen.main.scale
		UIGraphicsBeginImageContextWithOptions(screenSize, false, screenScale)
		guard let context = UIGraphicsGetCurrentContext() else { return .none }
		vc.view.layer.render(in: context)
		return UIGraphicsGetImageFromCurrentImageContext()
	}
	
    var jpegCompressedData: Data? {
        jpegData(compressionQuality: 0.3)
    }
    
	/// 图片二进制类型
	var data: Data? {
		if let data = pngData() {
			return data
		} else if let data = jpegData(compressionQuality: 1) {
			return data
		} else {
			return .none
		}
	}
	
	/// 圆角图片
	var roundImage: UIImage? {
		UIGraphicsBeginImageContextWithOptions(size, false, UIScreen.main.scale)
		defer { UIGraphicsEndImageContext() }
		guard let ctx = UIGraphicsGetCurrentContext() else { return nil }
		let rect = CGRect(origin: .zero, size: size)
		ctx.addEllipse(in: rect)
		ctx.clip()
		draw(in: rect)
		return UIGraphicsGetImageFromCurrentImageContext()
	}
	
	/// 圆角图片(用贝塞尔曲线)创建
	func roundImage(clip roundingCorners: UIRectCorner = .allCorners,
					cornerRadii: CGFloat? = nil) -> UIImage? {
		UIGraphicsBeginImageContextWithOptions(size, false, UIScreen.main.scale)
		defer { UIGraphicsEndImageContext() }
		let rect = CGRect(origin: .zero, size: size)
		let defaultRadii = cornerRadii ?? size.height/2
		let cornerSize = CGSize(width: defaultRadii, height: defaultRadii)
		UIBezierPath(roundedRect: rect,
					 byRoundingCorners: roundingCorners,
					 cornerRadii: cornerSize).addClip()
		draw(in: rect)
		return UIGraphicsGetImageFromCurrentImageContext()
	}
}

//
//  DepthImage.swift
//  ColoredPointCloud
//
//  Created by hvrl_mt on 2022/05/04.
//

import MetalKit
import ARKit

class DepthImage: Image {
    
    var depthTexture: CVMetalTexture?
    var confidenceTexture: CVMetalTexture?
    
    var confidenceCount: Int = 0
    
    override init() {
        super.init()
    }
    
    /// Updates the depth and confidence textures with the currently captured image
    /// - Parameter frame: `ARFrame` instance from which to extract the captured image
    func updateDepthTextures(frame: ARFrame, parameters: Parameters) {
        guard let sceneDepth = frame.sceneDepth,
              let confidenceMap = sceneDepth.confidenceMap else {
            return
        }
        
        let depthMap = sceneDepth.depthMap
        
        CVPixelBufferLockBaseAddress(depthMap, .readOnly)
        if let base = CVPixelBufferGetBaseAddress(depthMap) {
            let width = CVPixelBufferGetWidth(depthMap)
            let height = CVPixelBufferGetHeight(depthMap)
            
            let bindPointer = base.bindMemory(to: Float32.self, capacity: width * height)
            let bufferPointer = UnsafeBufferPointer(start: bindPointer, count: width * height)
            
            let depthArray = Array(bufferPointer)
//            print(depthArray)
            parameters.depthMap.update(width: width, height: height, values: depthArray)
        }
        CVPixelBufferUnlockBaseAddress(depthMap, .readOnly)
        
        depthTexture = createTexture(fromPixelBuffer: depthMap, pixelFormat: .r32Float, planeIndex: 0)
        confidenceTexture = createTexture(fromPixelBuffer: confidenceMap, pixelFormat: .r8Uint, planeIndex: 0)
    }
    
    
    func convertToDepthMapUIImage(frame: ARFrame) -> UIImage? {
        guard let sceneDepth = frame.sceneDepth else { return nil }
        let depthMap = sceneDepth.depthMap
        
        let ciImage = CIImage(cvPixelBuffer: depthMap)
        let cgImage = ciContext.createCGImage(ciImage, from: ciImage.extent)
        
        guard let image = cgImage else { return nil }
        
        // Captured depth map is rotated by -90 [deg]
        let uiImage = UIImage(cgImage: image).rotatedBy(degree: 90, isCropped: false)
        return uiImage
    }
    
    
    func convertToConfidenceMapUIImage(frame: ARFrame) -> UIImage? {
        guard let sceneDepth = frame.sceneDepth,
              let confidenceMap = sceneDepth.confidenceMap else { return nil }
                
        let lockFlags = CVPixelBufferLockFlags(rawValue: 0)
        
        // Attempt to lock the image buffer to gain access to its memory
        CVPixelBufferLockBaseAddress(confidenceMap, lockFlags)
        
        guard let rawBuffer = CVPixelBufferGetBaseAddress(confidenceMap) else { return nil }
        let height = CVPixelBufferGetHeight(confidenceMap)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(confidenceMap)
        let len = bytesPerRow * height
        let uInt8Stride = MemoryLayout<UInt8>.stride
        
        // Convert confidence level (0, 1, 2) to scaled pixel value (0, 128, 255)
        for index in stride(from: 0, through: len, by: uInt8Stride) {
            // Load confidence level
            let confidenceLevel = rawBuffer.load(fromByteOffset: index, as: UInt8.self)
            let scaledConfidenceLevel = Float(confidenceLevel) / Float(ARConfidenceLevel.high.rawValue) * 255
//            print(ceil(scaledConfidenceLevel), type(of: ceil(scaledConfidenceLevel)))
            let pixelValue = UInt8(min(ceil(scaledConfidenceLevel), 255))
            
            // Replace confidence level by scaled pixel value
            rawBuffer.storeBytes(of: pixelValue, toByteOffset: index, as: UInt8.self)
        }
        
        // Release the image buffer
        CVPixelBufferUnlockBaseAddress(confidenceMap, lockFlags)
        
        let ciImage = CIImage(cvPixelBuffer: confidenceMap)
        let cgImage = CIContext().createCGImage(ciImage, from: ciImage.extent)
        guard let image = cgImage else { return nil }
        
        // Captured confidence map is rotated by -90 [deg]
        let uiImage = UIImage(cgImage: image).rotatedBy(degree: 90, isCropped: false)
        return uiImage
    }
}

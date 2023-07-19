//
//  Image.swift
//  ColoredPointCloud
//
//  Created by hvrl_mt on 2022/05/04.
//

import MetalKit

class Image {
    var capturedImageTextureCache: CVMetalTextureCache?
    let ciContext = CIContext(options: nil)
    var count: Int = 0
    
    var delegate: StatusLogDelegate?
    
    init() {
        // Create captured image texture cache
        var textureCache: CVMetalTextureCache?
        CVMetalTextureCacheCreate(nil, nil, Renderer.device, nil, &textureCache)
        capturedImageTextureCache = textureCache
    }
    
    
    /// Creates a `MTLTexture` from the given `CVPixelBuffer` image.
    /// - Parameters:
    ///   - pixelBuffer: `CVPixelBuffer` that contains the image from which to create the texture
    ///   - pixelFormat: The pixel format of the texture
    ///   - planeIndex: `0` for "Y-texture", and `1` for "CbCR-texture"
    /// - Returns: The created texture
    func createTexture(fromPixelBuffer pixelBuffer: CVPixelBuffer, pixelFormat: MTLPixelFormat, planeIndex: Int) -> CVMetalTexture? {
        let width = CVPixelBufferGetWidthOfPlane(pixelBuffer, planeIndex)
        let height = CVPixelBufferGetHeightOfPlane(pixelBuffer, planeIndex)
        
        var texture: CVMetalTexture? = nil
        guard let capturedImageTextureCache = capturedImageTextureCache else {
            return texture
        }

        let status = CVMetalTextureCacheCreateTextureFromImage(nil,
                                                               capturedImageTextureCache,
                                                               pixelBuffer,
                                                               nil,
                                                               pixelFormat,
                                                               width,
                                                               height,
                                                               planeIndex,
                                                               &texture)
        
        guard status == kCVReturnSuccess else {
            return texture
        }
        
        return texture
    }
    
}

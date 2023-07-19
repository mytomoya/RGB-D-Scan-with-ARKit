//
//  CapturedImage.swift
//  ColoredPointCloud
//
//  Created by hvrl_mt on 2022/05/02.
//

import MetalKit
import ARKit

class CapturedImage: Image {
    
    let capturedImagePipelineState: MTLRenderPipelineState
    let capturedImageDepthState: MTLDepthStencilState!
    
    var textureY: CVMetalTexture?
    var textureCbCr: CVMetalTexture?
    
    override init() {
        capturedImagePipelineState = CapturedImage.buildCapturedImagePipelineState()
        capturedImageDepthState = CapturedImage.buildDepthStencilState()
        
        super.init()
    }
    
    // MARK: - Initialization
    
    /// Builds a render pipeline state for rendering captured images.
    /// Sets vertex and fragment functions, a vertex descriptor, and pixel and depth formats.
    /// - Returns: Already-configured render pipeline state
    static func buildCapturedImagePipelineState() -> MTLRenderPipelineState {
        var pipelineState: MTLRenderPipelineState

        let capturedImagePipelineStateDescriptor = MTLRenderPipelineDescriptor()
        capturedImagePipelineStateDescriptor.label = "CapturedImagePipeline"
        
        // Vertex and fragment functions
        let vertexFunction = Renderer.library.makeFunction(name: "capturedImageVertexTransform")
        let fragmentFunction = Renderer.library.makeFunction(name: "capturedImageFragmentShader")
        capturedImagePipelineStateDescriptor.vertexFunction = vertexFunction
        capturedImagePipelineStateDescriptor.fragmentFunction = fragmentFunction
        
        // Create a vertex descriptor for our image plane vertex buffer
        let imagePlaneVertexDescriptor = MTLVertexDescriptor.imagePlaneVertexDescriptor
        capturedImagePipelineStateDescriptor.vertexDescriptor = imagePlaneVertexDescriptor
        
        // Set pixel and depth formats
        capturedImagePipelineStateDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        capturedImagePipelineStateDescriptor.depthAttachmentPixelFormat = .depth32Float
        
        do {
            pipelineState = try Renderer.device.makeRenderPipelineState(descriptor: capturedImagePipelineStateDescriptor)
        } catch let error {
            fatalError("Failed to created captured image pipeline state, error \(error)")
        }
        
        return pipelineState
    }
    
    
    /// Builds a depth stencil state for rendering
    /// - Returns: Already-configured depth stencil state
    static func buildDepthStencilState() -> MTLDepthStencilState? {
        let descriptor = MTLDepthStencilDescriptor()
        
        descriptor.depthCompareFunction = .always
        descriptor.isDepthWriteEnabled = false
        let depthStencilState = Renderer.device.makeDepthStencilState(descriptor: descriptor)
        return depthStencilState
    }

    // MARK: - Texture
    
    /// Updates the textures with the currently captured image
    /// - Parameter frame: `ARFrame` instance from which to extract the captured image
    func updateCapturedImageTextures(frame: ARFrame) {
        let pixelBuffer = frame.capturedImage
        
        // `pixelBuffer` takes the YCbCr format, which has the luma and chroma planes
        guard CVPixelBufferGetPlaneCount(pixelBuffer) >= 2 else { return }
                
        textureY = createTexture(fromPixelBuffer: pixelBuffer, pixelFormat: .r8Unorm, planeIndex: 0)
        textureCbCr = createTexture(fromPixelBuffer: pixelBuffer, pixelFormat: .rg8Unorm, planeIndex: 1)
    }
    
    
    // MARK: - Draw
    
    func draw(renderEncoder: MTLRenderCommandEncoder) {
        guard let textureY = textureY,
              let textureCbCr = textureCbCr else {
            return
        }
        
        // Push a debug group allowing us to identify render commands in the GPU Frame Capture tool
        renderEncoder.pushDebugGroup("DrawCapturedImage")
        
        // Set render command encoder state
        renderEncoder.setRenderPipelineState(capturedImagePipelineState)
        renderEncoder.setDepthStencilState(capturedImageDepthState)
        
        // Set mesh's vertex buffers
        renderEncoder.setVertexBuffer(Renderer.imagePlaneVertexBuffer,
                                      offset: 0,
                                      index: Int(kBufferIndexMeshPositions.rawValue))
        
        // Set any textures read/sampled from our render pipeline
        renderEncoder.setFragmentTexture(CVMetalTextureGetTexture(textureY), index: Int(kTextureIndexY.rawValue))
        renderEncoder.setFragmentTexture(CVMetalTextureGetTexture(textureCbCr), index: Int(kTextureIndexCbCr.rawValue))
        
        // Draw each submesh of our mesh
        renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
        
        renderEncoder.popDebugGroup()
    }
}

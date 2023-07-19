//
//  Particle.swift
//  ColoredPointCloud
//
//  Created by hvrl_mt on 2022/05/09.
//

import MetalKit

// Maximum number of points we store in the point cloud
let nMaxPointCount = 10_000_000
let kAlignedParticleUniformsSize: Int = ((MemoryLayout<ParticleUniforms>.size * nMaxPointCount) & ~0xFF) + 0x100

class Particle {
    let particlePipelineState: MTLRenderPipelineState
    let particleDepthState: MTLDepthStencilState?
    
    // Particle Uniforms
    var uniformBuffer: MTLBuffer!
        
    var currentPointCount = 0
    var currentPointIndex = 0
    
    
    init() {
        particlePipelineState = Particle.buildParticlePipelineState()
        particleDepthState = Particle.buildDepthStencilState()
        
        // Setup buffers
        let particleUniformBufferSize = MemoryLayout<ParticleUniforms>.stride * nMaxPointCount
        uniformBuffer = Renderer.device.makeBuffer(length: particleUniformBufferSize,
                                                           options: .storageModeShared)
        uniformBuffer.label = "ParticleUniformBuffer"
    }
    
    // MARK: - Initialization
    
    /// Builds a depth stencil state for rendering
    /// - Returns: Already-configured depth stencil state
    static func buildDepthStencilState() -> MTLDepthStencilState? {
        let descriptor = MTLDepthStencilDescriptor()
        
        descriptor.depthCompareFunction = .less
        descriptor.isDepthWriteEnabled = true
        let depthStencilState = Renderer.device.makeDepthStencilState(descriptor: descriptor)
        return depthStencilState
    }
    
    /// Builds a render pipeline state for rendering particles.
    /// Sets vertex and fragment functions, a vertex descriptor, and pixel and depth formats.
    /// - Returns: Already-configured render pipeline state
    static func buildParticlePipelineState() -> MTLRenderPipelineState {
        var pipelineState: MTLRenderPipelineState
        
        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.label = "ParticlePipeline"
        
        // Vertex and fragment functions
        let vertexFunction = Renderer.library.makeFunction(name: "particleVertex")
        let fragmentFunction = Renderer.library.makeFunction(name: "particleFragment")
        descriptor.vertexFunction = vertexFunction
        descriptor.fragmentFunction = fragmentFunction
        
        // Set pixel and depth formats
        descriptor.depthAttachmentPixelFormat = .depth32Float
        descriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        descriptor.colorAttachments[0].isBlendingEnabled = true
        descriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        descriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        
        do {
            pipelineState = try Renderer.device.makeRenderPipelineState(descriptor: descriptor)
        } catch let error {
            fatalError(error.localizedDescription)
        }
        return pipelineState
    }
    
    
    // MARK: - Draw
    
    func draw(renderEncoder: MTLRenderCommandEncoder, pointCloud: PointCloud) {
        
        // Push a debug group allowing us to identify render commands in the GPU Frame Capture tool
        renderEncoder.pushDebugGroup("Particle Draw")
        
        renderEncoder.setDepthStencilState(particleDepthState)
        renderEncoder.setRenderPipelineState(particlePipelineState)
        
        renderEncoder.setVertexBuffer(pointCloud.uniformBuffer,
                                      offset: pointCloud.uniformBufferOffset,
                                      index: Int(kBufferIndexPointCloudUniforms.rawValue))
        renderEncoder.setVertexBuffer(uniformBuffer,
                                      offset: 0,
                                      index: Int(kBufferIndexParticleUniforms.rawValue))

        renderEncoder.drawPrimitives(type: .point, vertexStart: 0, vertexCount: currentPointCount)
        
//        let address = uniformBuffer.contents().advanced(by: currentPointIndex)
//        let uniforms = address.assumingMemoryBound(to: ParticleUniforms.self)
//
//        let position = uniforms.pointee.position
//        let color = uniforms.pointee.color
//        let confidence = uniforms.pointee.confidence
//
//        print("position: \(position)")
//        print("color: \(color)")
//        print("confidence: \(confidence)")
        
        renderEncoder.popDebugGroup()
    }
}

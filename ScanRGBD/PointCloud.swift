//
//  PointClouds.swift
//  ColoredPointCloud
//
//  Created by hvrl_mt on 2022/05/09.
//

import MetalKit
import ARKit


let kAlignedPointCloudUniformsSize: Int = (MemoryLayout<PointCloudUniforms>.size & ~0xFF) + 0x100

class PointCloud {
    // Number of sample points on the grid
    let numGridPoints: Float = 10_000
    
    var unprojectionPipelineState: MTLRenderPipelineState
    var depthStencilState: MTLDepthStencilState?
    
    // Point Cloud Uniforms
    var uniformBuffer: MTLBuffer!
    /// Offset within `uniformBuffer` to set for the current frame
    var uniformBufferOffset: Int = 0
    /// Addresses to write shared uniforms to each frame
    var uniformBufferAddress: UnsafeMutableRawPointer!
    
    // Grid Points Buffer
    var gridPointsBuffer: MTLBuffer? = nil
    var gridPoints: [Float2] = []
    
    var deviceTransformMatrix: matrix_float4x4 {
        // Rotation angle
        let angle = Float(90) * .degreesToRadian
        
        // Rotate by 90 deg around Z-axis (.portrait)
        let matrix = float4x4(
            [ cos(angle), sin(angle), 0, 0],
            [-sin(angle), cos(angle), 0, 0],
            [          0,          0, 1, 0],
            [          0,          0, 0, 1]
        )
        return matrix
    }
        
    init() {
        unprojectionPipelineState = PointCloud.buildUnprojectionPipelineState()
        depthStencilState = PointCloud.buildDepthStencilState()
        
        // Setup buffers
        let pointCloudUniformBufferSize = kAlignedPointCloudUniformsSize * kMaxBuffersInFlight
        uniformBuffer = Renderer.device.makeBuffer(length: pointCloudUniformBufferSize,
                                                   options: .storageModeShared)
        uniformBuffer.label = "PointCloudUniformBuffer"
    }
    
    /// Creates grid points on camera image
    /// - Returns: An array of grid points
    func makeGridPoints(cameraResolution: Float2) -> [Float2] {
        let gridArea = cameraResolution.x * cameraResolution.y
        let spacing = sqrt(gridArea / numGridPoints)
        
        // Interchange x and y for `portrait`
        let numGridPointsAlongX = Int(round(cameraResolution.y / spacing))
        let numGridPointsAlongY = Int(round(cameraResolution.x / spacing))
        
//        print(cameraResolution)
        
        var points: [Float2] = []
        for gridY in 0..<numGridPointsAlongY {
            let alternatingOffsetX = Float(gridY % 2) * spacing / 2
            for gridX in 0..<numGridPointsAlongX {
                let cameraPoint = Float2(alternatingOffsetX + (Float(gridX) + 0.5) * spacing,
                                         (Float(gridY) + 0.5) * spacing)
                points.append(cameraPoint)
//                print(cameraPoint)
            }
        }
        
        return points
    }
    
    
    func buildGridPointsBuffer(gridPoints: [Float2]) -> MTLBuffer {
        guard let gridPointsBuffer = Renderer.device.makeBuffer(bytes: gridPoints,
                                                                length: MemoryLayout<Float2>.stride * gridPoints.count,
                                                                options: .storageModeShared)
        else {
            fatalError("Failed to create MTLBuffer")
        }
        
        return gridPointsBuffer
    }
    
    
    /// Builds a render pipeline state for computing particles' positions.
    /// Sets vertex function, a vertex descriptor, and pixel and depth formats.
    /// - Returns: Already-configured render pipeline state
    static func buildUnprojectionPipelineState() -> MTLRenderPipelineState {
        var pipelineState: MTLRenderPipelineState
        
        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.label = "UnprojectionPipeline"
        
        // Vertex and fragment functions
        let vertexFunction = Renderer.library.makeFunction(name: "unprojectVertex")
        descriptor.vertexFunction = vertexFunction
        descriptor.isRasterizationEnabled = false
        
        // Set pixel and depth formats
        descriptor.depthAttachmentPixelFormat = .depth32Float
        descriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        
        do {
            pipelineState = try Renderer.device.makeRenderPipelineState(descriptor: descriptor)
        } catch let error {
            fatalError(error.localizedDescription)
        }
        return pipelineState
    }
    
    /// Builds a depth stencil state for rendering
    /// - Returns: Already-configured depth stencil state
    static func buildDepthStencilState() -> MTLDepthStencilState? {
        let descriptor = MTLDepthStencilDescriptor()
        
//        descriptor.depthCompareFunction = .less
//        descriptor.isDepthWriteEnabled = true
        let depthStencilState = Renderer.device.makeDepthStencilState(descriptor: descriptor)
        return depthStencilState
    }
    
    
    // MARK: - Update
    func update(camera: ARCamera, currentPointIndex: Int) {
        let uniforms = uniformBufferAddress.assumingMemoryBound(to: PointCloudUniforms.self)
        
        let viewMatrix = camera.viewMatrix(for: .portrait)
        let viewMatrixInversed = viewMatrix.inverse
        let projectionMatrix = camera.projectionMatrix(for: .portrait,
                                                       viewportSize: Renderer.viewportSize,
                                                       zNear: 0.001,
                                                       zFar: 0)
        let cameraIntrinsicsInversed = camera.intrinsics.inverse
        
        uniforms.pointee.nMaxPointCount = Int32(nMaxPointCount)
        uniforms.pointee.pointCloudCurrentIndex = Int32(currentPointIndex)
        
        uniforms.pointee.viewMatrix = viewMatrix
        uniforms.pointee.projectionMatrix = projectionMatrix
        uniforms.pointee.viewMatrixInversed = viewMatrixInversed
        uniforms.pointee.deviceTransformMatrix = deviceTransformMatrix
        uniforms.pointee.cameraIntrinsicsInversed = cameraIntrinsicsInversed
        
        let width = Float(camera.imageResolution.width)
        let height = Float(camera.imageResolution.height)
        uniforms.pointee.cameraResolution = Float2(width, height)
        
        updateGridPoints(camera: camera)
    }
    
    
    func updateGridPoints(camera: ARCamera) {
        guard gridPointsBuffer == nil else {
            return
        }
        
        let resolution = Float2(Float(camera.imageResolution.height),
                                Float(camera.imageResolution.width))
        
        gridPoints = makeGridPoints(cameraResolution: resolution)
        gridPointsBuffer = buildGridPointsBuffer(gridPoints: gridPoints)
    }
    
}

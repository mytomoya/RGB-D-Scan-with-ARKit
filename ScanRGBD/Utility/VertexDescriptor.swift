//
//  VertexDescriptor.swift
//  ColoredPointCloud
//
//  Created by hvrl_mt on 2022/04/30.
//

import Metal
import ModelIO
import MetalKit

extension MTLVertexDescriptor {
    static var imagePlaneVertexDescriptor: MTLVertexDescriptor = {
        let vertexDescriptor = MTLVertexDescriptor()
        var offset = 0
        
        // Positions
        vertexDescriptor.attributes[0].format = .float2
        vertexDescriptor.attributes[0].offset = offset
        vertexDescriptor.attributes[0].bufferIndex = Int(kBufferIndexMeshPositions.rawValue)
        
        offset += MemoryLayout<Float2>.stride

        // Texture coordinates
        vertexDescriptor.attributes[1].format = .float2
        vertexDescriptor.attributes[1].offset = offset
        vertexDescriptor.attributes[1].bufferIndex = Int(kBufferIndexMeshPositions.rawValue)

        offset += MemoryLayout<Float2>.stride

        // Buffer Layout
        vertexDescriptor.layouts[0].stride = offset

        return vertexDescriptor
    }()
    
    /// Metal vertex descriptor specifying how vertices will by laid out for input into our anchor geometry render pipeline and how we'll layout our Model IO vertices
    static var geometryVertexDescriptor: MTLVertexDescriptor = {
        let vertexDescriptor = MTLVertexDescriptor()
        var offset = 0
        
        // Positions
        vertexDescriptor.attributes[0].format = .float3
        vertexDescriptor.attributes[0].offset = offset
        vertexDescriptor.attributes[0].bufferIndex = Int(kBufferIndexMeshPositions.rawValue)
        
        offset += MemoryLayout<Float3>.stride
        
        // Position Buffer Layout
        // TODO: Isn't it really 12 = packed_float3? -
//        vertexDescriptor.layouts[0].stride = offset
        vertexDescriptor.layouts[0].stride = 12
        
        return vertexDescriptor
    }()
    
    
    /// Create a Model IO vertexDescriptor so that we format/layout our model IO mesh vertices to fit our Metal render pipeline's vertex descriptor layout
    func getGeometryMDLVertexDescriptor() -> MDLVertexDescriptor {
        let vertexDescriptor = MTKModelIOVertexDescriptorFromMetal(self)
        
        // Indicate how each Metal vertex descriptor attribute maps to each ModelIO attribute
        (vertexDescriptor.attributes[Int(kVertexAttributePosition.rawValue)] as! MDLVertexAttribute).name = MDLVertexAttributePosition
        
        return vertexDescriptor
    }
}

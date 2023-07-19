//
//  Common.h
//  ColoredPointCloud
//
//  Created by hvrl_mt on 2022/04/30.
//

#ifndef Common_h
#define Common_h

#include <simd/simd.h>

// Buffer index values
typedef enum {
    kBufferIndexMeshPositions       = 0,
    kBufferIndexMeshGenerics        = 1,
    kBufferIndexInstanceUniforms    = 2,
    kBufferIndexSharedUniforms      = 3,
    kBufferIndexGridPoints          = 4,
    kBufferIndexParticleUniforms    = 5,
    kBufferIndexPointCloudUniforms  = 6,
} BufferIndices;

// Texture index values
typedef enum {
    kTextureIndexColor      = 0,
    kTextureIndexY          = 1,
    kTextureIndexCbCr       = 2,
    kTextureIndexDepth      = 3,
    kTextureIndexConfidence = 4,
} TextureIndices;

// Attribute index values
typedef enum {
    kVertexAttributePosition  = 0,
    kVertexAttributeTexcoord  = 1,
    kVertexAttributeNormal    = 2
} VertexAttributes;

// Camera Uniforms
typedef struct {
    matrix_float4x4 projectionMatrix;
    matrix_float4x4 viewMatrix;
} Uniforms;

// Instance Uniforms
typedef struct {
    matrix_float4x4 modelMatrix;
} InstanceUniforms;

// Point Cloud Uniforms
typedef struct {    
    int nMaxPointCount;
    int pointCloudCurrentIndex;
    
    matrix_float4x4 projectionMatrix;
    matrix_float4x4 viewMatrix;
    matrix_float4x4 viewMatrixInversed;
    matrix_float4x4 deviceTransformMatrix;
    matrix_float3x3 cameraIntrinsicsInversed;
    
    simd_float2 cameraResolution;
} PointCloudUniforms;

// Particle Uniforms
typedef struct {
    simd_float3 position;
    simd_float3 color;
    float confidence;
} ParticleUniforms;

#endif /* Common_h */

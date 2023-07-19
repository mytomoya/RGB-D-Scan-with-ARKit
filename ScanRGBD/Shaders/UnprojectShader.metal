//
//  UnprojectShader.metal
//  ColoredPointCloud
//
//  Created by hvrl_mt on 2022/05/11.
//

#include <metal_stdlib>
#import "Common.h"

using namespace metal;

// When converting image coordinate -> NDC, Y and Z axes should be flipped
constant float4x4 flipYZ = float4x4(
    float4(1,  0,  0, 0),
    float4(0, -1,  0, 0),
    float4(0,  0, -1, 0),
    float4(0,  0,  0, 1)
);

// Transform matrix to convert full-range YCbCr values to an sRGB format
constant float4x4 ycbcrToRGBTransform = float4x4(
    float4(+1.0000f, +1.0000f, +1.0000f, +0.0000f),
    float4(+0.0000f, -0.3441f, +1.7720f, +0.0000f),
    float4(+1.4020f, -0.7141f, +0.0000f, +0.0000f),
    float4(-0.7010f, +0.5291f, -0.8860f, +1.0000f)
);



struct VertexOut {
    float4 position [[position]];
    float point_size [[point_size]];
    float4 color;
};


/// Compute the world coordinate from a camera coordinate
float4 getWorldCoordinate(float2 gridPoint,
                          float depth,
                          constant PointCloudUniforms &uniforms) {
    float3 positionInCameraSpace = uniforms.cameraIntrinsicsInversed * float3(gridPoint, 1) * depth;
    float4 correctedPositionInCameraSpace = flipYZ * uniforms.deviceTransformMatrix * float4(positionInCameraSpace, 1);
    float4 positionInWorldSpace = uniforms.viewMatrixInversed * correctedPositionInCameraSpace;
    
    return positionInWorldSpace / positionInWorldSpace.w;
}


vertex void unprojectVertex(uint id [[vertex_id]],
                            constant PointCloudUniforms &pointCloudUniforms [[ buffer(kBufferIndexPointCloudUniforms) ]],
                            device ParticleUniforms *particleUniforms [[ buffer(kBufferIndexParticleUniforms) ]],
                            constant float2 *gridPoints [[ buffer(kBufferIndexGridPoints) ]],
                            texture2d<float, access::sample> capturedImageTextureY [[ texture(kTextureIndexY) ]],
                            texture2d<float, access::sample> capturedImageTextureCbCr [[ texture(kTextureIndexCbCr) ]],
                            texture2d<float, access::sample> depthTexture [[ texture(kTextureIndexDepth) ]],
                            texture2d<unsigned int, access::sample> confidenceTexture [[ texture(kTextureIndexConfidence) ]]) {
    
    float2 gridPoint = gridPoints[id];
    float2 texCoord = gridPoint / pointCloudUniforms.cameraResolution;
    
    // MARK: - Texture Sampling
    
    constexpr sampler colorSampler(mip_filter::linear,
                                   mag_filter::linear,
                                   min_filter::linear);

    // Sample Y and CbCr textures to get the YCbCr color at the given texture coordinate
    float4 ycbcr = float4(capturedImageTextureY.sample(colorSampler, texCoord).r,
                          capturedImageTextureCbCr.sample(colorSampler, texCoord).rg,
                          1.0);
    // Sample the depth map to get the depth value
    float depth = depthTexture.sample(colorSampler, texCoord).r;
    // Sample the confidence map to get the confidence value
    float confidence = confidenceTexture.sample(colorSampler, texCoord).r;
    
    float3 sampledColor = (ycbcrToRGBTransform * ycbcr).rgb;
    
    // With a 2D point plus depth, we can now get its 3D position
    float4 position = getWorldCoordinate(gridPoint, depth, pointCloudUniforms);
    
    int currentPointIndex = (pointCloudUniforms.pointCloudCurrentIndex + id) % pointCloudUniforms.nMaxPointCount;

    // Write the data to the buffer
    particleUniforms[currentPointIndex].position = position.xyz;
    particleUniforms[currentPointIndex].color = sampledColor;
    particleUniforms[currentPointIndex].confidence = confidence;

}

//
//  ParticleShader.metal
//  ColoredPointCloud
//
//  Created by hvrl_mt on 2022/05/09.
//

#include <metal_stdlib>
#import "Common.h"

using namespace metal;


struct VertexOut {
    float4 position [[position]];
    float point_size [[point_size]];
    float4 color;
};


vertex VertexOut particleVertex(uint id [[vertex_id]],
                                constant PointCloudUniforms &pointCloudUniforms [[buffer(kBufferIndexPointCloudUniforms)]],
                                constant ParticleUniforms *particleUniforms [[buffer(kBufferIndexParticleUniforms)]]) {
    // get point data
    ParticleUniforms particleData = particleUniforms[id];
    simd_float3 position = particleData.position;
    simd_float3 color = particleData.color;
    float confidence = particleData.confidence;
    bool visibility = confidence >= 2.0;
    
    // animate and project the point
    matrix_float4x4 projectionViewMatrix = pointCloudUniforms.projectionMatrix * pointCloudUniforms.viewMatrix;
    float4 projectedPosition = projectionViewMatrix * float4(position, 1.0);
    float pointSize = max(30.0 / max(1.0, projectedPosition.z), 2.0);
    projectedPosition /= projectedPosition.w;
    
    VertexOut out;
    
    out.position = projectedPosition;
    out.point_size = pointSize;
    out.color = float4(color, visibility);
    
    return out;
}

fragment float4 particleFragment(VertexOut in [[stage_in]],
                                 const float2 coords [[point_coord]]) {
    // we draw within a circle
    float distSquared = length_squared(coords - float2(0.5));
    if (in.color.a == 0 || distSquared > 0.25) {
        discard_fragment();
    }
    
    return in.color;
}

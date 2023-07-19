//
//  CapturedImageShaders.metal
//  ColoredPointCloud
//
//  Created by hvrl_mt on 2022/05/09.
//

#include <metal_stdlib>
#import "Common.h"

using namespace metal;

struct VertexIn {
    float2 position [[ attribute(kVertexAttributePosition) ]];
    float2 texCoord [[ attribute(kVertexAttributeTexcoord) ]];
};

struct VertexOut {
    float4 position [[position]];
    float2 texCoord;
};


// Captured image vertex function
vertex VertexOut capturedImageVertexTransform(VertexIn in [[stage_in]]) {
    VertexOut out;
    
    // Pass through the image vertex's position
    out.position = float4(in.position, 0.0, 1.0);
    
    // Pass through the texture coordinate
    out.texCoord = in.texCoord;
    
    return out;
}

// Captured image fragment function
fragment float4 capturedImageFragmentShader(VertexOut in [[stage_in]],
                                            texture2d<float, access::sample> capturedImageTextureY [[ texture(kTextureIndexY) ]],
                                            texture2d<float, access::sample> capturedImageTextureCbCr [[ texture(kTextureIndexCbCr) ]]) {
    
    constexpr sampler colorSampler(mip_filter::linear,
                                   mag_filter::linear,
                                   min_filter::linear);
    
    // Transform matrix to convert full-range YCbCr values to an sRGB format
    const float4x4 ycbcrToRGBTransform = float4x4(
        float4(+1.0000f, +1.0000f, +1.0000f, +0.0000f),
        float4(+0.0000f, -0.3441f, +1.7720f, +0.0000f),
        float4(+1.4020f, -0.7141f, +0.0000f, +0.0000f),
        float4(-0.7010f, +0.5291f, -0.8860f, +1.0000f)
    );
    
    // Sample Y and CbCr textures to get the YCbCr color at the given texture coordinate
    float4 ycbcr = float4(capturedImageTextureY.sample(colorSampler, in.texCoord).r,
                          capturedImageTextureCbCr.sample(colorSampler, in.texCoord).rg,
                          1.0);
    
    // Return converted RGB color
    return ycbcrToRGBTransform * ycbcr;
}

//
//  shaders.metal
//  MetalLearn
//
//  Created by chengxiaoyu on 2021/6/28.
//

#include <metal_stdlib>
#import "shaders.h"

using namespace metal;

struct RasterizerData {
    /// position的修饰符表示这个是顶点
    float4 clipSpacePosition [[position]];
    /// 纹理坐标，会做插值处理
    float2 textureCoordinate;
};

/// 定点着色器 返回值是给片元着色器的结构体
/// - vertex_id是顶点shader每次处理的index，用于定位当前的顶点
/// - buffer表明是缓存数据，0是索引
vertex RasterizerData vertexShader(uint vertexID [[ vertex_id]],constant LYVertex *vertexArray [[ buffer(0) ]]) {
    RasterizerData out;
    out.clipSpacePosition = vertexArray[vertexID].position;
    out.textureCoordinate = vertexArray[vertexID].textureCoordinate;
    return out;
}
/// 片源着色器
/// - stage_in表示这个数据来自光栅化。（光栅化是顶点处理之后的步骤，业务层无法修改）
/// - texture表明是纹理数据，0是索引
fragment float4 samplingShader(RasterizerData input [[stage_in]],
               texture2d<half> colorTexture [[ texture(0) ]])
{
    constexpr sampler textureSampler (mag_filter::linear,
                                      min_filter::linear); // sampler是采样器
    
    half4 colorSample = colorTexture.sample(textureSampler, input.textureCoordinate); // 得到纹理对应位置的颜色
    
    return float4(colorSample);
}

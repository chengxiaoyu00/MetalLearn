//
//  shaders.h
//  MetalLearn
//
//  Created by chengxiaoyu on 2021/6/28.
//

#ifndef shaders_h
#define shaders_h
#ifdef __METAL_VERSION__
#define NS_ENUM(_type, _name) enum _name : _type _name; enum _name : _type
#define NSInteger metal::int32_t
#else
#import <Foundation/Foundation.h>
#endif

#include <simd/simd.h>

typedef struct
{
    vector_float4 position;
    vector_float2 textureCoordinate;
} LYVertex;


#endif /* shaders_h */

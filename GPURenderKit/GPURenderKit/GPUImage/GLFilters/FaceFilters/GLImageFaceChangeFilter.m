//
//  GLImageFaceChangeFilter.m
//  GPURenderKitDemo
//
//  Created by 刘海东 on 2019/4/16.
//  Copyright © 2019 刘海东. All rights reserved.
//


/**

 这里面用到的算法参考文章地址 "http://www.shenyanhao.com/2015/09/眼睛放大美颜算法/"
 
 */

#import "GLImageFaceChangeFilter.h"

#define FACE_POINTS_COUNT 106


NSString *const kGLImageFaceChangeFragmentShaderString = SHADER_STRING
(
 precision mediump float;
 
 varying highp vec2 textureCoordinate;
 uniform sampler2D inputImageTexture;
 
 /** 瘦脸i调节 */
 uniform float thin_face_param;
 /** 大眼调节 */
 uniform float eye_param;
 uniform vec2 resolution;
 uniform int haveFaceBool;
 
 uniform mediump vec2 locArray[106];
 
 
 highp vec2 warpPositionToUse1(vec2 currentPoint, vec2 contourPointA,  vec2 contourPointB, float radius, float delta, float aspectRatio)
{
    highp vec2 positionToUse = currentPoint;
    
    vec2 currentPointToUse = vec2(currentPoint.x, currentPoint.y * aspectRatio + 0.5 - 0.5 * aspectRatio);
    vec2 contourPointAToUse = vec2(contourPointA.x, contourPointA.y * aspectRatio + 0.5 - 0.5 * aspectRatio);
    highp float r = distance(currentPointToUse, contourPointAToUse);
    
    if(r < radius)
    {
        vec2 dir = normalize(contourPointB - contourPointA);
        float dist = radius * radius - r * r;
        float alpha = dist / (dist + (r-delta) * (r-delta));
        alpha = alpha * alpha;
        
        positionToUse = positionToUse - alpha * delta * dir;
    }
    
    return positionToUse;
}
 
 
 //脸部调节
 vec2 adjust_thinFace(vec2 coord, float eye_dist, vec2 dir_up, vec2 dir_right, float aspect_ratio, float intensity)
{
    vec2 positionToUse = coord;
    int arraySize = 3;
    vec2 leftContourPoints[3];
    vec2 rightContourPoints[3];
    
    float deltaArray[3];
    
    leftContourPoints[0] = locArray[4] - dir_right * eye_dist*0.13;
    leftContourPoints[1] = locArray[9] - dir_right * eye_dist*0.33;
    leftContourPoints[2] = locArray[13]- dir_right * eye_dist*0.33;
    
    
    rightContourPoints[0] = locArray[28] + dir_right * eye_dist*0.13;
    rightContourPoints[1] = locArray[23] + dir_right * eye_dist*0.33;
    rightContourPoints[2] = locArray[19] + dir_right * eye_dist*0.33;
    
    float x = 3.14159 / 30.0;
    float scaleFactor = eye_dist * 2.0;
    float radius = 0.4 * scaleFactor;
    
    
    deltaArray[0] = sin(x) * intensity * 0.150 * scaleFactor;
    deltaArray[1] = sin(x*2.0) * intensity * 0.150 * scaleFactor;
    deltaArray[2] = sin(x*2.0) * intensity * 0.150 * scaleFactor;
    
    
    for(int i = 0; i < arraySize; i++)
    {
        positionToUse = warpPositionToUse1(positionToUse, leftContourPoints[i], rightContourPoints[i], radius, deltaArray[i], aspect_ratio);
        positionToUse = warpPositionToUse1(positionToUse, rightContourPoints[i], leftContourPoints[i], radius, deltaArray[i], aspect_ratio);
    }
    
    return positionToUse;
}
 
 //大眼
 vec2 adjust_eye(vec2 coord, float eye_dist, vec2 dir_up, vec2 dir_right, float aspect_ratio, float intensity)
{
    float eyeEnlarge = intensity * 0.24;
    
    float res_ratio = resolution.x/resolution.y;
    
    vec2 newCoord = vec2(coord.x*res_ratio,coord.y);
    
    vec2 eyea = vec2(locArray[74].x * res_ratio, locArray[74].y);
    vec2 eyeb = vec2(locArray[77].x * res_ratio, locArray[77].y);
    
    vec2 eye_far = vec2(locArray[52].x * res_ratio, locArray[52].y);
    vec2 eye_near = vec2(locArray[55].x * res_ratio, locArray[55].y);
    
    float weight = 0.0;
    float eye_width = distance(eye_far, eye_near);
    
    // left eye
    float eyeRadius = eye_width;
    float dis_eye1 = distance(newCoord, eyea);
    if (dis_eye1 < 0.01) {
        
        weight = pow((dis_eye1+0.01) / eyeRadius, eyeEnlarge);
        newCoord = eyea + (newCoord - eyea)*weight;
        
    } else if (dis_eye1 <= eyeRadius) {
        weight = pow(dis_eye1 / eyeRadius, eyeEnlarge);
        newCoord = eyea + (newCoord - eyea)*weight;
    }
    
    // right eye
    float dis_eye2 = distance(newCoord, eyeb);
    if (dis_eye2 < 0.01) {
        
        weight = pow((dis_eye2+0.01) / eyeRadius, eyeEnlarge);
        newCoord = eyeb + (newCoord - eyeb)*weight;
        
    } else if (dis_eye2 <= eyeRadius) {
        weight = pow(dis_eye2 / eyeRadius, eyeEnlarge);
        newCoord = eyeb + (newCoord - eyeb)*weight;
    }
    
    newCoord = vec2(newCoord.x/res_ratio, newCoord.y);
    return newCoord;
}
 
 
 void main()
 {
     
     vec2 newCoord = textureCoordinate;
     
     // 眼距
     highp float eye_dist = distance(locArray[74], locArray[77]);
     // 屏幕高宽比
     highp float aspect_ratio = resolution.y / resolution.x;
     
     // 面部方向
     vec2 dir_up     = normalize(locArray[43] - locArray[16]);
     vec2 dir_right  = normalize(locArray[77] - locArray[74]);
     
     if (haveFaceBool == 1)
     {
         //瘦脸调节
         
         newCoord = adjust_thinFace(newCoord, eye_dist, dir_up, dir_right, aspect_ratio, thin_face_param);
         //眼部调节
         newCoord = adjust_eye(newCoord, eye_dist, dir_up, dir_right, aspect_ratio, eye_param);
     }
     
     vec3 newColor = texture2D(inputImageTexture, newCoord).rgb;
     gl_FragColor = vec4(newColor, 1.0);
 }
 );

@interface GLImageFaceChangeFilter ()
@property (nonatomic, assign) CGSize frameBufferSize;
@end


@implementation GLImageFaceChangeFilter

- (instancetype)init
{
    self = [super initWithFragmentShaderFromString:kGLImageFaceChangeFragmentShaderString];
    if (self) {
        
        faceArrayUniform = [filterProgram uniformIndex:@"locArray"];
        iResolutionUniform = [filterProgram uniformIndex:@"resolution"];
        haveFaceUniform = [filterProgram uniformIndex:@"haveFaceBool"];
    }
    return self;
}

- (void)setIsHaveFace:(BOOL)isHaveFace{
    _isHaveFace = isHaveFace;
    int value = isHaveFace == YES ? 1:0;
    [self setInteger:value forUniform:haveFaceUniform program:filterProgram];
}


- (void)setThinFaceParam:(float)thinFaceParam
{
    _thinFaceParam = thinFaceParam;
    [self setFloat:thinFaceParam forUniformName:@"thin_face_param"];
}

- (void)setEyeParam:(float)eyeParam{
    _eyeParam = eyeParam;
    [self setFloat:eyeParam forUniformName:@"eye_param"];
}

- (void)setFacePointsArray:(NSArray *)pointArrays{
    
    if (pointArrays.count==0) {
        return;
    }
    
    static GLfloat facePoints[FACE_POINTS_COUNT * 2] = {0};
    
    float width = _frameBufferSize.width;
    float height = _frameBufferSize.height;
    
    for (int index = 0; index < FACE_POINTS_COUNT; index++)
    {
        CGPoint point = [pointArrays[index] CGPointValue];
        facePoints[2 * index + 0] = point.y / width;
        facePoints[2 * index + 1] = point.x / height;
    }
    
    [self setFloatVec2Array:facePoints length:FACE_POINTS_COUNT*2 forUniform:faceArrayUniform program:filterProgram];
}


- (void)setupFilterForSize:(CGSize)filterFrameSize
{
    _frameBufferSize = filterFrameSize;
    [self setSize:filterFrameSize forUniform:iResolutionUniform program:filterProgram];
}


@end

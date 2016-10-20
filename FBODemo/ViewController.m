//
//  ViewController.m
//  FBODemo
//
//  Created by cfq on 16/9/23.
//  Copyright © 2016年 cfq. All rights reserved.
//


/**
 *  先渲染里面的锥体，得到结果作为纹理，进行二次绘制
 *  思路：
 *  1、定义两个着色器，mBaseEffect用于渲染到屏幕和自定义帧缓存，mExtraEffect用于渲染纹理。
 *  2、渲染mBaseEffect到自定义帧缓存，设置mExtraEffect纹理为自定义帧缓存
 *
 *
 */


#import "ViewController.h"

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UISwitch *mExtraSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *mBaseSwitch;

@property (nonatomic, strong) EAGLContext *mContext;
// 着色器
@property (nonatomic, strong) GLKBaseEffect *mBaseEffect;
@property (nonatomic, strong) GLKBaseEffect *mExtraEffect;

@property (nonatomic, assign) int mCount;

@property (nonatomic, assign) GLint mDefaultFBO;
@property (nonatomic, assign) GLuint mExtraFBO;
@property (nonatomic, assign) GLuint mExtraDepthBuffer;
@property (nonatomic, assign) GLuint mExtraTexture;
@property (nonatomic, assign) GLuint mBaseAttr;
@property (nonatomic, assign) GLuint buffer;
@property (nonatomic, assign) GLuint index;

@property (nonatomic, assign) long mBaseRotate;
@property (nonatomic, assign) long mExtraRotate;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    //创建上下文
    self.mContext = [[EAGLContext alloc] initWithAPI:(kEAGLRenderingAPIOpenGLES2)];
    //配置上下文 OpenGL ES的绘制都是输出到帧缓存，GLKView的帧缓存会显示到屏幕。
    GLKView *view = (GLKView *)self.view;
    view.context = self.mContext;
    view.drawableColorFormat = GLKViewDrawableColorFormatRGBA8888;
    view.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    
    [EAGLContext setCurrentContext:self.mContext];
    
    glEnable(GL_DEPTH_TEST);
    
    //新的图形
    [self renderNew];
//    [self update];
}

- (void)renderNew {
    //顶点数据
    GLfloat attrArr[] =
    {
    //  ------位置---------      -----颜色-------        ---纹理坐标--
        -0.5f,  0.5f, 0.0f,     0.0f, 0.0f, 0.5f,       0.0f, 1.0f,//左上
         0.5f,  0.5f, 0.0f,     0.0f, 0.5f, 0.0f,       1.0f, 1.0f,//右上
        -0.5f, -0.5f, 0.0f,     0.5f, 0.0f, 1.0f,       0.0f, 0.0f,//左下
         0.5f, -0.5f, 0.0f,     0.0f, 0.0f, 0.5f,       1.0f, 0.0f,//右下
         0.0f,  0.0f, 1.0f,     1.0f, 1.0f, 1.0f,       0.5f, 0.5f,//顶点
        
    };
    //顶点索引
    GLuint indices[] =
    {
        0, 3, 2,
        0, 1, 3,
        0, 2, 4,
        0, 4, 1,
        2, 3, 4,
        1, 4, 3,
    };
    self.mCount = sizeof(indices) / sizeof(GLuint);
    
    GLfloat baseAttr[] =
    {
        -1.0f, -1.0f,  1.0f,             1.0f, 1.0f,
         1.0f, -1.0f,  1.0f,             0.0f, 1.0f,
        -1.0f, -1.0f, -1.0f,             1.0f, 0.0f,
         1.0f, -1.0f, -1.0f,             0.0f, 0.0f,
    };
    
    // self.preferredFramesPerSecond
    
    glGenBuffers(1, &_mBaseAttr);
    glBindBuffer(GL_ARRAY_BUFFER, _mBaseAttr);
    glBufferData(GL_ARRAY_BUFFER, sizeof(baseAttr), baseAttr, GL_STATIC_DRAW);
    
    glGenBuffers(1, &_buffer);
    glBindBuffer(GL_ARRAY_BUFFER, _buffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(attrArr), attrArr, GL_STATIC_DRAW);
    
    glGenBuffers(1, &_index);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _index);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(indices), indices, GL_STATIC_DRAW);
    
    
//    glEnableVertexAttribArray(GLKVertexAttribPosition);
//    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 8, (GLfloat *)NULL);

//    //可以去掉注释
//    glEnableVertexAttribArray(GLKVertexAttribColor);
//    glVertexAttribPointer(GLKVertexAttribColor, 3, GL_FLOAT, GL_FALSE, 4 * 8, (GLfloat *)NULL + 3);
    
//    glEnableVertexAttribArray(GLKVertexAttribTexCoord0);
//    glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 8, (GLfloat *)NULL + 6);
    
    // 获取纹理图片
    NSString* filePath = [[NSBundle mainBundle] pathForResource:@"for_test" ofType:@"png"];
    NSDictionary* options = [NSDictionary dictionaryWithObjectsAndKeys:@(1), GLKTextureLoaderOriginBottomLeft, nil];
    
    GLKTextureInfo* textureInfo = [GLKTextureLoader textureWithContentsOfFile:filePath options:options error:nil];
    
    //创建mExtraEffect、mBaseEffect着色器
    self.mExtraEffect = [[GLKBaseEffect alloc] init];
    self.mBaseEffect = [[GLKBaseEffect alloc] init];
    
    self.mExtraEffect.texture2d0.enabled = GL_TRUE;
    self.mBaseEffect.texture2d0.enabled = GL_TRUE;
    
    self.mExtraEffect.texture2d0.name = textureInfo.name;
    //    self.mBaseEffect.texture2d0.name = textureInfo.name;
    NSLog(@"panda texture %d", textureInfo.name);
 
    [self preparePointOfViewWithAspectRatio:
     CGRectGetWidth(self.view.bounds) / CGRectGetHeight(self.view.bounds)];
    int width, height;
    width = self.view.bounds.size.width * self.view.contentScaleFactor;
    height = self.view.bounds.size.height * self.view.contentScaleFactor;
    [self extraInitWithWidth:width height:height]; //特别注意这里的大小
    
    self.mBaseRotate = self.mExtraRotate = 0;
}

//MVP矩阵
- (void)preparePointOfViewWithAspectRatio:(GLfloat)aspectRatio
{
    
    self.mExtraEffect.transform.projectionMatrix = self.mBaseEffect.transform.projectionMatrix =

    /**
     *  透视投影变换
     *
     *  @param fovyRadians#> 视角 description#>
     *  @param aspect#>      长宽比 description#>
     *  @param nearZ#>       近平面距离 description#>
     *  @param farZ#>        远平面距离 description#>
     *
     *  @return
     */
    GLKMatrix4MakePerspective(
                              GLKMathDegreesToRadians(85.0f),
                              aspectRatio,
                              0.1f,
                              20.0f);
    
    self.mExtraEffect.transform.modelviewMatrix = self.mBaseEffect.transform.modelviewMatrix =
    //创建一个modelviewMatrix矩阵 此方法表示eye在（eyeX，eyeY，eyeZ）的坐标，望向（centerX，centerY，centerZ），同时eye坐标系的y轴正方向为（upX，upY，upZ）
    GLKMatrix4MakeLookAt(
                         0.0, 0.0, 3.0,   // Eye position
                         0.0, 0.0, 0.0,   // Look-at position
                         0.0, 1.0, 0.0);  // Up direction
    
}

/**
 *  初始化一个帧缓存
 *
 *  @param width
 *  @param height
 */
- (void)extraInitWithWidth:(GLint)width height:(GLint)height {
   //获取当前活动视口参数的查询函数，在交互式应用中，我们可以使用该函数获得光标所在视口的参数
    glGetIntegerv(GL_FRAMEBUFFER_BINDING, &_mDefaultFBO);
    //新的纹理
    glGenTextures(1, &_mExtraTexture);
    //新建帧缓存
    glGenFramebuffers(1, &_mExtraFBO);
    //新建渲染缓存
    glGenRenderbuffers(1, &_mExtraDepthBuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, self.mExtraFBO);
    //绑定帧缓存
    glBindTexture(GL_TEXTURE_2D, self.mExtraTexture);
    
    //分配纹理内存，把之前创建的纹理挂载到帧缓存的颜色输出
    /**
     *  生成纹理, 当调用glTexImage2D，当前绑定的纹理对象就会被附加上纹理图像
     *
     *  @param target  指定纹理目标(环境)
     *  @param level   为我们打算创建的纹理指定多级渐远纹理的层级 如果你希望单独手工设置每个多级渐远纹理的层级的话。这里我们填0基本级
     *  @param internalformat 告诉OpenGL，我们希望把纹理储存为何种格式。
     *  @param width 设置最终的纹理的宽度
     *  @param height 设置最终的纹理的高度
     *  @param border 一直被设为0
     *  @param format 定义了源图的格式
     *  @param type  定义了源图的数据类型
     *  @param pixel 图像数据
     *
     *  @return
     */
      glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, NULL);
    
    //设置纹理格式
    /**
     *  单独设置每个坐标轴s、t
     *
     *  @param target 指定了纹理目标 使用的是2D纹理，因此纹理目标是GL_TEXTURE_2D
     *  @param pname  我们希望去设置哪个纹理轴, 设置的是WRAP选项，并且指定S和T轴
     *  @param param 传递放置方式
     *
     *  @return 
     */
    //GL_CLAMP_TO_EDGE: 纹理坐标会在0到1之间，超出的部分会重复纹理坐标的边缘，就是边缘被拉伸
    //纹理环绕方式
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    //纹理过滤
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    
    //切换帧缓存为纹理对象 把之前创建的纹理挂载到帧缓存颜色输出
    /**
     *  glFramebufferTexture2D 函数：
     target：我们所创建的帧缓冲类型的目标（绘制、读取或两者都有）。
     attachment：我们所附加的附件的类型。现在我们附加的是一个颜色附件。需要注意，最后的那个0是暗示我们可以附加1个以上颜色的附件。
     textarget：你希望附加的纹理类型。
     texture：附加的实际纹理。
     level：Mipmap level。我们设置为0。
     */
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, self.mExtraTexture, 0);
    
    //渲染缓存
    glBindRenderbuffer(GL_RENDERBUFFER, self.mExtraDepthBuffer);
    
    //分配渲染内存
    glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT16, width, height);
    //切换帧缓存为渲染缓存
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, self.mExtraDepthBuffer);
    
    GLenum status;
    status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
    switch (status) {
        case GL_FRAMEBUFFER_COMPLETE:
            NSLog(@"fbo complete width %d height %d", width, height);
            break;
        
        case GL_FRAMEBUFFER_UNSUPPORTED:
            NSLog(@"fbo unsupported");
            break;
        
        default:
            NSLog(@"Framebuffer Error");
            break;
    }

//    glBindFramebuffer(GL_FRAMEBUFFER, self.mDefaultFBO);
    //当生成纹理对象后，解绑纹理对象
    glBindTexture(GL_TEXTURE_2D, 0);

}


- (void)update
{
    GLKMatrix4 modelViewMatrix;
    if (self.mBaseSwitch.on) {
        ++self.mBaseRotate;
        modelViewMatrix = GLKMatrix4Identity;
        modelViewMatrix = GLKMatrix4Translate(modelViewMatrix, 0, 0, -3);
        modelViewMatrix = GLKMatrix4Rotate(modelViewMatrix, GLKMathDegreesToRadians(self.mBaseRotate), 1, 1, 1);
        self.mBaseEffect.transform.modelviewMatrix = modelViewMatrix;
    }
    
    if (self.mExtraSwitch.on) {
        self.mExtraRotate += 2;
        modelViewMatrix = GLKMatrix4Identity;
        modelViewMatrix = GLKMatrix4Translate(modelViewMatrix, 0, 0, -3);
        modelViewMatrix = GLKMatrix4Rotate(modelViewMatrix, GLKMathDegreesToRadians(self.mExtraRotate), 1, 1, 1);
        self.mExtraEffect.transform.modelviewMatrix = modelViewMatrix;
    }
    
}

//渲染
- (void)renderFBO {
    //绑定帧缓存
    glBindFramebuffer(GL_FRAMEBUFFER, self.mExtraFBO);
    //如果视口和主缓存的不同，需要根据当前的大小调整，同时在下面的绘制时需要调整glviewport
    //    glViewport(0, -680, const_length * 2, const_length * 5.5);
    //清理上次绘制的颜色和缓冲区
    glClearColor(1.0f, 1.0f, 0.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    //绘制图形
    [self.mExtraEffect prepareToDraw];
    glDrawElements(GL_TRIANGLES, self.mCount, GL_UNSIGNED_INT, 0);
//    glBindFramebuffer(GL_FRAMEBUFFER, self.mDefaultFBO);
    
    //将其设置为mBaseEffect的纹理
    self.mBaseEffect.texture2d0.name = self.mExtraTexture;
}

#pragma mark GLKViewDelegate
- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect {
    [self renderFBO];
    //注：在开始绘制mBaseEffect到屏幕的图形之前，切记添加
    [((GLKView *) self.view) bindDrawable];
    
    //glViewport() 见上面
    glClearColor(0.3, 0.3, 0.3, 1);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    //由mBaseAttr获取baseAttr数组绘制图形
    glBindBuffer(GL_ARRAY_BUFFER, self.mBaseAttr);
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 5, (GLfloat *)NULL);
    
    glBindBuffer(GL_ARRAY_BUFFER, self.mBaseAttr);
    glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 5, (GLfloat *)NULL + 3);
    glDisableVertexAttribArray(GLKVertexAttribColor);
    [self.mBaseEffect prepareToDraw];
    // GL_TRIANGLE_STRIP: 将顶点传递给opengl渲染管道线（pipeline）进行进一步处理的方式（创建几何图形）创建一个三角形至少需要三个顶点，每一个新增的顶点都形成一个新的三角形。三角形将根据顶点序号的奇偶自行创建：偶数环绕规则：T = [n-1, n-2, n] 奇数环绕规则：T = [n-2, n-1, n]
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);

    //由buffer获取baseAttr数组绘制图形，这个必须写，绘制的纹理也是按照这个数组绘制的,
    glBindBuffer(GL_ARRAY_BUFFER, self.buffer);
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 8, (GLfloat *)NULL);
    glEnableVertexAttribArray(GLKVertexAttribColor);
    glVertexAttribPointer(GLKVertexAttribColor, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 8, (GLfloat *)NULL + 3);
    glEnableVertexAttribArray(GLKVertexAttribTexCoord0);
    glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 8, (GLfloat *)NULL + 6);
    //    [self.mExtraEffect prepareToDraw];
    //    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _index);
    //    glDrawElements(GL_TRIANGLES, self.mCount, GL_UNSIGNED_INT, 0);
}

- (BOOL)shouldAutorotateToInterfaceOrientation:
(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation !=
            UIInterfaceOrientationPortraitUpsideDown);
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end

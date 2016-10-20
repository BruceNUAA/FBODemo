# 纹理环绕方式(Texture Wrapping)
  环绕方式	
# GL_REPEAT
  纹理的默认行为，重复纹理图像

#GL_MIRRORED_REPEAT	
  和GL_REPEAT一样，除了重复的图片是镜像放置的

#GL_CLAMP_TO_EDGE	
  纹理坐标会在0到1之间，超出的部分会重复纹理坐标的边缘，就是边缘被拉伸

#GL_CLAMP_TO_BORDER	
   超出的部分是用户指定的边缘的颜色
[当纹理坐标超出默认范围时，每个值都有不同的视觉效果输出]

# 纹理过滤(Texture Filtering)
  GL_NEAREST和GL_LINEAR  

#GL_NEAREST(Nearest Neighbor Filtering，最邻近过滤) 
 是一种OpenGL默认的纹理过滤方式。当设置为GL_NEAREST的时候，OpenGL选择最接近纹理坐标中
 心点的那个像素。

#GL_LINEAR((Bi)linear Filtering，线性过滤)
 它会从纹理坐标的临近纹理像素进行计算，返回一个多个纹理像素的近似值。一个纹理像素距离纹理坐
 标越近，那么这个纹理像素对最终的采样颜色的影响越大。

#纹理过滤可以为放大（magnifying ）和缩小（minifying）设置不同的选项
 这样你可以在纹理被缩小的时候使用最临近过滤，被放大时使用线性过滤。 
 [我们必须通过glTexParameter为放大和缩小指定过滤方式。]
glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);

# 多级渐远纹理(Mipmaps)
  如果我们在一个有着上千物体的大房间，每个物体上都有纹理。距离观察者远的与距离近的物体的纹
理的解析度是相同的。由于远处的物体可能只产生很少的片段，OpenGL从高解析度纹理中为这些片段获
取正确的颜色值就很困难。这是因为它不得不拾为一个纹理跨度很大的片段取纹理颜色。在小物体上这
会产生人工感，更不用说在小物体上使用高解析度纹理浪费内存的问题了。
  OpenGL使用一种叫做 多级渐远纹理(Mipmap) 的概念解决这个问题，大概来说就是一系列纹理，
每个后面的一个纹理是前一个的二分之一。多级渐远纹理背后的思想很简单：距离观察者更远的距离的
一段确定的阈值，OpenGL会把最适合这个距离的物体的不同的多级渐远纹理纹理应用其上。由于距离
远，解析度不高也不会被使用者注意到。同时，多级渐远纹理另一加分之处是，执行效率不错。
  OpenGL有一个glGenerateMipmaps函数，它可以在我们创建完一个纹理后帮我们做所有的多级渐
远纹理创建工作。后面的纹理教程中你会看到如何使用它。
  OpenGL渲染的时候，两个不同级别的多级渐远纹理之间会产生不真实感的生硬的边界。就像普通的
纹理过滤一样，也可以在两个不同多级渐远纹理级别之间使用NEAREST和LINEAR过滤。指定不同多级
渐远纹理级别之间的过滤方式可以使用下面四种选项代替原来的过滤方式：

#GL_NEAREST_MIPMAP_NEAREST	
 接收最近的多级渐远纹理来匹配像素大小，并使用最临近插值进行纹理采样

#GL_LINEAR_MIPMAP_NEAREST	
 接收最近的多级渐远纹理级别，并使用线性插值采样

#GL_NEAREST_MIPMAP_LINEAR	
 在两个多级渐远纹理之间进行线性插值，通过最邻近插值采样

#GL_LINEAR_MIPMAP_LINEAR	
 在两个相邻的多级渐远纹理进行线性插值，并通过线性插值进行采样

glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);
glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);

[常见的错误是，为多级渐远纹理过滤选项设置放大过滤。这样没有任何效果，因为多级渐远纹理主要用
在纹理被缩小的情况下的：纹理放大不会使用多级渐远纹理，为多级渐远纹理设置放大过滤选项会产生
一个GL_INVALID_ENUM错误。]



# 帧缓存

帧缓存： 接收渲染结果的缓冲区叫做帧缓存。在OpenGL的渲染管道中，几何数据和纹理通过一系列的
        变换和测试后，变成渲染到屏幕上的二位像素。渲染目标就是帧缓存区。

    每一个iOS原生控件都有一个对应的CoreAnimation层。CoreAnimation合成器使用OpenGL 
ES来尽可能高效地控制GPU、混合层和切换帧缓存。

# 核心思路(帧缓存像素颜色的输出结果在GL_COLOR_ATTATCHMENT开头的缓存区)
1、用一个纹理缓存来作为OpenGL ES的第一次输出的缓存区，这样我们可以得到一个纹理Texture0。
2、用Texture0作为第二次绘制的纹理，得到最后的结果

# 把纹理对象关联到帧缓存
1、新建纹理
2、设置纹理格式
3、分配纹理内存
4、新建帧缓存
5、切换帧缓存为纹理对象
GLuint colorTexture;
# 1
glGenTextures(1, &colorTexture);
glBindTexture(GL_TEXTURE_2D, colorTexture);

# 2
glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S,
GL_CLAMP_TO_EDGE);
glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T,
GL_CLAMP_TO_EDGE);
glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER,
GL_LINEAR);
glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER,
GL_LINEAR_MIPMAP_LINEAR);

# 3
glTexImage2D(GL_TEXTURE_2D,0,GL_RGBA,fboWidth,fboHeight,0,GL_RGBA,GL_UNSIGNED_BYTE,NULL);

#4
glGenFramebuffers(1, &fboName);
glBindFramebuffer(GL_FRAMEBUFFER, fboName);

#5
glFramebufferTexture2D(GL_FRAMEBUFFER,
GL_COLOR_ATTACHMENT0,
GL_TEXTURE_2D, colorTexture, 0);

# 渲染缓存关联到帧缓存
1、新建渲染缓存
2、分配渲染缓存
3、新建帧缓存
4、切换帧缓存为渲染缓存

#1
glGenRenderbuffers(1, &colorRenderbuffer);
glBindRenderbuffer(GL_RENDERBUFFER, colorRenderbuffer);

#2
glRenderbufferStorage(GL_RENDERBUFFER, GL_RGBA8_OES, viewport[2],viewport[3]);

#3
glGenFramebuffers(1, &framebuffer);
glBindFramebuffer(GL_FRAMEBUFFER, framebuffer);

#4
glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, colorRenderbuffer);


[OpenGL ES的渲染结果会放到帧缓存区，如何与视图的显示联系起来？]
答案: CAEGLayer

# CAEGLayer
OpenGL ES会有连接到层，与层分享数据的帧缓存，至少包括一个像素颜色渲染缓存。
CAEAGLLyaer是CoreAnimation提供的标准层类之一，与OpenGL ES的帧缓存共享它的像素颜色
库。与一个Core Animation共享内存的像素颜色渲染缓存在层调整大小时会自动调整大小。其他缓
存，例如深度缓存，不会自动调整大小。可以在layoutSubviews方法里面删除现存的深度缓存，并创
建一个新的与像素颜色渲染缓存的新尺寸相匹配的深度缓存。



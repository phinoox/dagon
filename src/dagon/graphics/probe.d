/*
Copyright (c) 2018 Timur Gafarov

Boost Software License - Version 1.0 - August 17th, 2003
Permission is hereby granted, free of charge, to any person or organization
obtaining a copy of the software and accompanying documentation covered by
this license (the "Software") to use, reproduce, display, distribute,
execute, and transmit the Software, and to prepare derivative works of the
Software, and to permit third-parties to whom the Software is furnished to
do so, all subject to the following:

The copyright notices in the Software and this entire statement, including
the above license grant, this restriction and the following disclaimer,
must be included in all copies of the Software, in whole or in part, and
all derivative works of the Software, unless such copies or derivative
works are solely in the form of machine-executable object code generated by
a source language processor.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE, TITLE AND NON-INFRINGEMENT. IN NO EVENT
SHALL THE COPYRIGHT HOLDERS OR ANYONE DISTRIBUTING THE SOFTWARE BE LIABLE
FOR ANY DAMAGES OR OTHER LIABILITY, WHETHER IN CONTRACT, TORT OR OTHERWISE,
ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
DEALINGS IN THE SOFTWARE.
*/

module dagon.graphics.probe;

import std.stdio;
import dlib.core.memory;
import dlib.image.color;
import dlib.math.vector;
import dlib.math.matrix;
import dlib.math.transformation;
import dlib.math.utils;
import dagon.core.libs;
import dagon.core.ownership;
import dagon.graphics.framebuffer;
import dagon.graphics.gbuffer;
import dagon.graphics.rc;

enum CubeFace
{
    NegativeX = GL_TEXTURE_CUBE_MAP_NEGATIVE_X,
    PositiveX = GL_TEXTURE_CUBE_MAP_POSITIVE_X,
    NegativeY = GL_TEXTURE_CUBE_MAP_NEGATIVE_Y,
    PositiveY = GL_TEXTURE_CUBE_MAP_POSITIVE_Y,
    PositiveZ = GL_TEXTURE_CUBE_MAP_POSITIVE_Z,
    NegativeZ = GL_TEXTURE_CUBE_MAP_NEGATIVE_Z
}

Matrix4x4f cubeFaceRotationMatrix(CubeFace cf, Vector3f pos)
{
    Matrix4x4f m;
    switch(cf)
    {
        case CubeFace.PositiveX:
            m = translationMatrix(pos) * rotationMatrix(1, degtorad(90.0f)) * rotationMatrix(2, degtorad(180.0f)); 
            break;
        case CubeFace.NegativeX:
            m = translationMatrix(pos) * rotationMatrix(1, degtorad(-90.0f)) * rotationMatrix(2, degtorad(180.0f)); 
            break;
        case CubeFace.PositiveY:
            m = translationMatrix(pos) * rotationMatrix(1, degtorad(0.0f)) * rotationMatrix(0, degtorad(-90.0f)); 
            break;
        case CubeFace.NegativeY:
            m = translationMatrix(pos) * rotationMatrix(1, degtorad(0.0f)) * rotationMatrix(0, degtorad(90.0f)); 
            break;
        case CubeFace.PositiveZ:
            m = translationMatrix(pos) * rotationMatrix(1, degtorad(180.0f)) * rotationMatrix(2, degtorad(180.0f)); 
            break;
        case CubeFace.NegativeZ:
            m = translationMatrix(pos) * rotationMatrix(1, degtorad(0.0f)) * rotationMatrix(2, degtorad(180.0f)); 
            break;
        default:
            m = Matrix4x4f.identity; break;
    }
    return m;
}

class EnvironmentProbeRenderTarget: RenderTarget
{
    GBuffer gbuffer;
    GLuint fbo;
    GLuint depthTexture = 0;

    this(uint res, Owner o)
    {
        super(res, res, o);

        gbuffer = New!GBuffer(res, res, this);

        glActiveTexture(GL_TEXTURE0);

        glGenTextures(1, &depthTexture);
        glBindTexture(GL_TEXTURE_2D, depthTexture);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        glTexImage2D(GL_TEXTURE_2D, 0, GL_DEPTH24_STENCIL8, res, res, 0, GL_DEPTH_STENCIL, GL_UNSIGNED_INT_24_8, null);
        glBindTexture(GL_TEXTURE_2D, 0);

        glGenFramebuffers(1, &fbo);
        glBindFramebuffer(GL_FRAMEBUFFER, fbo);
        glFramebufferTexture2D(GL_FRAMEBUFFER, GL_DEPTH_STENCIL_ATTACHMENT, GL_TEXTURE_2D, depthTexture, 0);
        GLenum[1] bufs = [GL_COLOR_ATTACHMENT0];
        glDrawBuffers(1, bufs.ptr);

        glBindFramebuffer(GL_FRAMEBUFFER, 0);
    }

    ~this()
    {
        if (glIsTexture(depthTexture))
            glDeleteTextures(1, &depthTexture);

        glBindFramebuffer(GL_FRAMEBUFFER, 0);
        glDeleteFramebuffers(1, &fbo);
    }

    override void bind()
    {
        glBindFramebuffer(GL_FRAMEBUFFER, fbo);
    }

    override void unbind()
    {
        glBindFramebuffer(GL_FRAMEBUFFER, 0);
    }

    override void clear(Color4f clearColor)
    {
        glClearColor(clearColor.r, clearColor.g, clearColor.b, 0.0f);
        glClear(GL_DEPTH_BUFFER_BIT);
        Color4f zero = Color4f(0, 0, 0, 0);
        glClearBufferfv(GL_COLOR, 0, zero.arrayof.ptr);
    }

    void setProbe(EnvironmentProbe probe, CubeFace face)
    {
        glBindFramebuffer(GL_FRAMEBUFFER, fbo);
        glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, face, probe.texture, 0);
        glBindFramebuffer(GL_FRAMEBUFFER, 0);
    }

    void prepareRC(EnvironmentProbe probe, CubeFace face, RenderingContext* rc)
    {
        rc.invViewMatrix = cubeFaceRotationMatrix(face, probe.position);
        rc.viewMatrix = rc.invViewMatrix.inverse;

        rc.modelViewMatrix = rc.viewMatrix;
        rc.normalMatrix = rc.invViewMatrix.transposed;
        rc.cameraPosition = probe.position;
        Matrix4x4f mvp = rc.projectionMatrix * rc.viewMatrix;
        rc.frustum.fromMVP(mvp);
        
        rc.prevCameraPosition = probe.position;
        rc.prevViewMatrix = rc.viewMatrix;

        rc.viewRotationMatrix = matrix3x3to4x4(matrix4x4to3x3(rc.viewMatrix));
        rc.invViewRotationMatrix = matrix3x3to4x4(matrix4x4to3x3(rc.invViewMatrix));
    }
}

class EnvironmentProbe: Owner
{
    GLuint texture = 0;
    GLuint fbo;

    uint resolution;
    Vector3f position;

    this(uint res, Vector3f position, Owner o)
    {
        super(o);
        resolution = res;
        this.position = position;

        glActiveTexture(GL_TEXTURE0);

        glGenTextures(1, &texture);
        glBindTexture(GL_TEXTURE_CUBE_MAP, texture);

        glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);
        glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_WRAP_R, GL_CLAMP_TO_EDGE);

        glTexImage2D(GL_TEXTURE_CUBE_MAP_NEGATIVE_X, 0, GL_RGBA16F, resolution, resolution, 0, GL_RGBA, GL_FLOAT, null);
        glTexImage2D(GL_TEXTURE_CUBE_MAP_POSITIVE_X, 0, GL_RGBA16F, resolution, resolution, 0, GL_RGBA, GL_FLOAT, null);
        glTexImage2D(GL_TEXTURE_CUBE_MAP_NEGATIVE_Y, 0, GL_RGBA16F, resolution, resolution, 0, GL_RGBA, GL_FLOAT, null);
        glTexImage2D(GL_TEXTURE_CUBE_MAP_POSITIVE_Y, 0, GL_RGBA16F, resolution, resolution, 0, GL_RGBA, GL_FLOAT, null);
        glTexImage2D(GL_TEXTURE_CUBE_MAP_NEGATIVE_Z, 0, GL_RGBA16F, resolution, resolution, 0, GL_RGBA, GL_FLOAT, null);
        glTexImage2D(GL_TEXTURE_CUBE_MAP_POSITIVE_Z, 0, GL_RGBA16F, resolution, resolution, 0, GL_RGBA, GL_FLOAT, null);

        glBindTexture(GL_TEXTURE_CUBE_MAP, 0);
    }
    
    void generateMipmaps()
    {
        glBindTexture(GL_TEXTURE_CUBE_MAP, texture);
        glGenerateMipmap(GL_TEXTURE_CUBE_MAP);
        glBindTexture(GL_TEXTURE_CUBE_MAP, 0);
    }

    ~this()
    {
        if (glIsTexture(texture))
            glDeleteTextures(1, &texture);
    }
}

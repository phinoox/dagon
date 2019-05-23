/*
Copyright (c) 2019 Timur Gafarov

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

module dagon.render.shaders.sunlight;

import std.stdio;
import std.math;

import dlib.core.memory;
import dlib.core.ownership;
import dlib.math.vector;
import dlib.math.matrix;
import dlib.math.transformation;
import dlib.math.interpolation;
import dlib.image.color;

import dagon.core.bindings;
import dagon.graphics.shader;
import dagon.graphics.state;
import dagon.graphics.csm;

class SunLightShader: Shader
{
    string vs = import("SunLight.vert.glsl");
    string fs = import("SunLight.frag.glsl");
    
    Matrix4x4f defaultShadowMatrix;
    GLuint defaultShadowTexture;

    this(Owner owner)
    {
        auto myProgram = New!ShaderProgram(vs, fs, this);
        super(myProgram, owner);
        defaultShadowMatrix = Matrix4x4f.identity;
        
        glGenTextures(1, &defaultShadowTexture);
        glActiveTexture(GL_TEXTURE0);
        glBindTexture(GL_TEXTURE_2D_ARRAY, defaultShadowTexture);
        glTexImage3D(GL_TEXTURE_2D_ARRAY, 0, GL_DEPTH_COMPONENT24, 1, 1, 3, 0, GL_DEPTH_COMPONENT, GL_FLOAT, null);
        glTexParameteri(GL_TEXTURE_2D_ARRAY, GL_TEXTURE_COMPARE_MODE, GL_COMPARE_REF_TO_TEXTURE);
	    glTexParameteri(GL_TEXTURE_2D_ARRAY, GL_TEXTURE_COMPARE_FUNC, GL_LEQUAL);
        glBindTexture(GL_TEXTURE_2D_ARRAY, 0);
    }
    
    ~this()
    {
        if (glIsFramebuffer(defaultShadowTexture))
            glDeleteFramebuffers(1, &defaultShadowTexture);
    }

    override void bind(State* state)
    {
        setParameter("viewMatrix", state.viewMatrix);
        setParameter("invViewMatrix", state.invViewMatrix);
        setParameter("projectionMatrix", state.projectionMatrix);
        setParameter("invProjectionMatrix", state.invProjectionMatrix);
        setParameter("resolution", state.resolution);
        setParameter("zNear", state.zNear);
        setParameter("zFar", state.zFar);
        
        // Environment
        if (state.environment)
        {
            setParameter("fogColor", state.environment.fogColor);
            setParameter("fogStart", state.environment.fogStart);
            setParameter("fogEnd", state.environment.fogEnd);
        }
        else
        {
            setParameter("fogColor", Color4f(0.5f, 0.5f, 0.5f, 1.0f));
            setParameter("fogStart", 0.0f);
            setParameter("fogEnd", 1000.0f);
        }
        
        // Light
        Vector4f lightDirHg;
        Color4f lightColor;
        float lightEnergy = 1.0f;
        if (state.light)
        {        
            lightDirHg = Vector4f(state.light.directionAbsolute);
            lightDirHg.w = 0.0;
            lightColor = state.light.color;
            lightEnergy = state.light.energy;
        }
        else
        {
            lightDirHg = Vector4f(0.0f, 0.0f, 1.0f, 0.0f);
            lightColor = Color4f(1.0f, 1.0f, 1.0f, 1.0f);
        }
        Vector3f lightDir = (lightDirHg * state.viewMatrix).xyz;
        setParameter("lightDirection", lightDir);
        setParameter("lightColor", lightColor);
        setParameter("lightEnergy", lightEnergy);
        // TODO: light color and energy
        
        // Texture 0 - color buffer
        glActiveTexture(GL_TEXTURE0);
        glBindTexture(GL_TEXTURE_2D, state.colorTexture);
        setParameter("colorBuffer", 0);
        
        // Texture 1 - depth buffer
        glActiveTexture(GL_TEXTURE1);
        glBindTexture(GL_TEXTURE_2D, state.depthTexture);
        setParameter("depthBuffer", 1);
        
        // Texture 2 - normal buffer
        glActiveTexture(GL_TEXTURE2);
        glBindTexture(GL_TEXTURE_2D, state.normalTexture);
        setParameter("normalBuffer", 2);
        
        // Texture 3 - pbr buffer
        glActiveTexture(GL_TEXTURE3);
        glBindTexture(GL_TEXTURE_2D, state.pbrTexture);
        setParameter("pbrBuffer", 3);
        
        // Texture 4 - shadow map
        if (state.light)
        {
            if (state.light.shadowEnabled)
            {
                CascadedShadowMap csm = cast(CascadedShadowMap)state.light.shadowMap;
                
                glActiveTexture(GL_TEXTURE4);
                glBindTexture(GL_TEXTURE_2D_ARRAY, csm.depthTexture);
                setParameter("shadowTextureArray", 4);
                setParameter("shadowResolution", cast(float)csm.resolution);
                setParameter("shadowMatrix1", csm.area1.shadowMatrix);
                setParameter("shadowMatrix2", csm.area2.shadowMatrix);
                setParameter("shadowMatrix3", csm.area3.shadowMatrix);
                setParameterSubroutine("shadowMap", ShaderType.Fragment, "shadowMapCascaded");
            }
            else
            {
                glActiveTexture(GL_TEXTURE4);
                glBindTexture(GL_TEXTURE_2D_ARRAY, defaultShadowTexture);
                setParameter("shadowTextureArray", 4);
                setParameter("shadowMatrix1", defaultShadowMatrix);
                setParameter("shadowMatrix2", defaultShadowMatrix);
                setParameter("shadowMatrix3", defaultShadowMatrix);
                setParameterSubroutine("shadowMap", ShaderType.Fragment, "shadowMapNone");
            }
        }
        
        glActiveTexture(GL_TEXTURE0);

        super.bind(state);
    }

    override void unbind(State* state)
    {
        super.unbind(state);
        
        glActiveTexture(GL_TEXTURE0);
        glBindTexture(GL_TEXTURE_2D, 0);

        glActiveTexture(GL_TEXTURE1);
        glBindTexture(GL_TEXTURE_2D, 0);

        glActiveTexture(GL_TEXTURE2);
        glBindTexture(GL_TEXTURE_2D, 0);
        
        glActiveTexture(GL_TEXTURE3);
        glBindTexture(GL_TEXTURE_2D, 0);
        
        glActiveTexture(GL_TEXTURE4);
        glBindTexture(GL_TEXTURE_2D_ARRAY, 0);
        
        glActiveTexture(GL_TEXTURE0);
    }
}

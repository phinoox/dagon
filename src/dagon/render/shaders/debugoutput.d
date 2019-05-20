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

module dagon.render.shaders.debugoutput;

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

class DebugOutputShader: Shader
{
    string vs = import("DebugOutput.vs");
    string fs = import("DebugOutput.fs");
    
    int outputMode = 3;

    this(Owner owner)
    {
        auto myProgram = New!ShaderProgram(vs, fs, this);
        super(myProgram, owner);
    }

    override void bind(State* state)
    {
        setParameter("projectionMatrix", state.projectionMatrix);
        
        setParameter("viewMatrix", state.viewMatrix);
        setParameter("invViewMatrix", state.invViewMatrix);
        setParameter("invProjectionMatrix", state.invProjectionMatrix);
        setParameter("resolution", state.resolution);
        setParameter("zNear", state.zNear);
        setParameter("zFar", state.zFar);
        
        setParameter("outputMode", outputMode);
        
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
        
        glActiveTexture(GL_TEXTURE0);

        super.bind(state);
    }

    override void unbind(State* state)
    {
        super.unbind(state);
        
        // TODO: unbind textures
    }
}

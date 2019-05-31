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

module dagon.postproc.shaders.tonemap;

import std.stdio;

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
import dagon.render.deferred;

enum Tonemapper
{
    None = 0,
    Reinhard = 1,
    Hable = 2,
    ACES = 3
}

class TonemapShader: Shader
{
    string vs = import("Tonemap.vert.glsl");
    string fs = import("Tonemap.frag.glsl");
    
    bool enabled = true;
    Tonemapper tonemapper = Tonemapper.ACES;
    float exposure = 1.0f;

    this(Owner owner)
    {
        auto myProgram = New!ShaderProgram(vs, fs, this);
        super(myProgram, owner);
        
        debug writeln("TonemapShader: program ", program.program);
    }

    override void bind(GraphicsState* state)
    {
        setParameter("viewSize", state.resolution);
        setParameter("enabled", enabled);
        
        setParameter("tonemapper", cast(int)tonemapper);
        setParameter("exposure", exposure);
        
        // Texture 0 - color buffer
        glActiveTexture(GL_TEXTURE0);
        glBindTexture(GL_TEXTURE_2D, state.colorTexture);
        setParameter("colorBuffer", 0);
        
        // Texture 1 - depth buffer
        glActiveTexture(GL_TEXTURE1);
        glBindTexture(GL_TEXTURE_2D, state.depthTexture);
        setParameter("depthBuffer", 1);
        
        glActiveTexture(GL_TEXTURE0);

        super.bind(state);
    }

    override void unbind(GraphicsState* state)
    {
        super.unbind(state);
        
        glActiveTexture(GL_TEXTURE0);
        glBindTexture(GL_TEXTURE_2D, 0);
        
        glActiveTexture(GL_TEXTURE1);
        glBindTexture(GL_TEXTURE_2D, 0);
        
        glActiveTexture(GL_TEXTURE0);
    }
}

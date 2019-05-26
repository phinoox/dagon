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

module dagon.render.deferred.geometrystage;

import std.stdio;

import dlib.core.memory;
import dlib.core.ownership;

import dagon.core.bindings;
import dagon.graphics.entity;
import dagon.render.pipeline;
import dagon.render.stage;
import dagon.render.gbuffer;
import dagon.render.shaders.geometry;

class DeferredGeometryStage: RenderStage
{
    GBuffer gbuffer;
    GeometryShader geometryShader;
    
    this(RenderPipeline pipeline, EntityGroup group = null)
    {
        super(pipeline, group);
        geometryShader = New!GeometryShader(this);        
        state.overrideShader = geometryShader;
    }
    
    override void onResize(int w, int h)
    {
        if (gbuffer && view)
        {
            gbuffer.resize(view.width, view.height);
        }
    }
    
    override void render()
    {
        if (!gbuffer && view)
        {
            gbuffer = New!GBuffer(view.width, view.height, this);
        }
        
        if (group)
        {
            gbuffer.bind();
            
            glScissor(0, 0, gbuffer.width, gbuffer.height);
            glViewport(0, 0, gbuffer.width, gbuffer.height);
             
            glClearColor(0.0, 0.0, 0.0, 0.0);
            glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
            
            foreach(entity; group)
            if (entity.visible)
            {
                state.modelViewMatrix = state.viewMatrix * entity.absoluteTransformation;
                state.normalMatrix = state.modelViewMatrix.inverse.transposed;
               
                if (entity.material)
                    entity.material.bind(&state);
                else
                    defaultMaterial.bind(&state);
                
                if (entity.drawable)
                    entity.drawable.render(&state);
                    
                if (entity.material)
                    entity.material.unbind(&state);
                else
                    defaultMaterial.unbind(&state);
            }
            
            gbuffer.unbind();
        }
    }
}

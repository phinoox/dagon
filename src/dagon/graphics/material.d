/*
Copyright (c) 2017-2019 Timur Gafarov

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

module dagon.graphics.material;

import std.math;
import std.algorithm;

import dlib.core.memory;
import dlib.core.ownership;
import dlib.math.vector;
import dlib.image.color;
import dlib.image.image;
import dlib.image.unmanaged;
import dlib.container.dict;

import dagon.core.bindings;
import dagon.graphics.texture;
import dagon.graphics.state;
import dagon.graphics.shader;

enum
{
    CBlack = Color4f(0.0f, 0.0f, 0.0f, 1.0f),
    CWhite = Color4f(1.0f, 1.0f, 1.0f, 1.0f),
    CRed = Color4f(1.0f, 0.0f, 0.0f, 1.0f),
    COrange = Color4f(1.0f, 0.5f, 0.0f, 1.0f),
    CYellow = Color4f(1.0f, 1.0f, 0.0f, 1.0f),
    CGreen = Color4f(0.0f, 1.0f, 0.0f, 1.0f),
    CCyan = Color4f(0.0f, 1.0f, 1.0f, 1.0f),
    CBlue = Color4f(0.0f, 0.0f, 1.0f, 1.0f),
    CPurple = Color4f(0.5f, 0.0f, 1.0f, 1.0f),
    CMagenta = Color4f(1.0f, 0.0f, 1.0f, 1.0f)
}

enum int None = 0;

enum int ShadowFilterNone = 0;
enum int ShadowFilterPCF = 1;

enum int ParallaxNone = 0;
enum int ParallaxSimple = 1;
enum int ParallaxOcclusionMapping = 2;

enum int Opaque = 0;
enum int Transparent = 1;
enum int Additive = 2;

enum MaterialInputType
{
    Undefined,
    Bool,
    Integer,
    Float,
    Vec2,
    Vec3,
    Vec4
}

struct MaterialInput
{
    MaterialInputType type;
    union
    {
        bool asBool;
        int asInteger;
        float asFloat;
        Vector2f asVector2f;
        Vector3f asVector3f;
        Vector4f asVector4f;
    }
    Texture texture;

    float getNumericValue()
    {
        float res;
        if (type == MaterialInputType.Bool ||
            type == MaterialInputType.Integer)
        {
            res = asInteger;
        }
        else if (type == MaterialInputType.Float)
        {
            res = asFloat;
        }
        return res;
    }

    Color4f sample(float u, float v)
    {
        if (texture !is null)
            return texture.sample(u, v);
        else if (type == MaterialInputType.Vec4)
            return Color4f(asVector4f);
        else if (type == MaterialInputType.Vec3)
            return Color4f(asVector3f.x, asVector3f.y, asVector3f.z, 1.0f);
        else if (type == MaterialInputType.Vec2)
            return Color4f(asVector2f.x, asVector2f.y, 1.0f, 1.0f);
        else if (type == MaterialInputType.Float)
            return Color4f(asFloat, 1.0f, 1.0f, 1.0f);
        else if (type == MaterialInputType.Bool ||
                 type == MaterialInputType.Integer)
            return Color4f(cast(float)asInteger, 1.0f, 1.0f, 1.0f);
        else
            return Color4f(0.0f, 0.0f, 0.0f, 0.0f);
    }
}

MaterialInput materialInput(float v)
{
    MaterialInput mi;
    mi.asFloat = v;
    mi.type = MaterialInputType.Float;
    return mi;
}

class Material: Owner
{
    Dict!(MaterialInput, string) inputs;
    Shader shader;
    bool customShader = false;

    this(Shader shader, Owner o)
    {
        super(o);

        inputs = New!(Dict!(MaterialInput, string));
        setStandardInputs();
        this.shader = shader;
    }

    ~this()
    {
        Delete(inputs);
    }

    void setStandardInputs()
    {
        setInput("diffuse", Color4f(0.8f, 0.8f, 0.8f, 1.0f));
        setInput("specular", Color4f(1.0f, 1.0f, 1.0f, 1.0f));
        setInput("shadeless", false);
        setInput("emission", Color4f(0.0f, 0.0f, 0.0f, 1.0f));
        setInput("energy", 1.0f);
        setInput("transparency", 1.0f);
        setInput("roughness", 0.5f);
        setInput("metallic", 0.0f);
        setInput("normal", Vector3f(0.0f, 0.0f, 1.0f));
        setInput("height", 0.0f);
        setInput("parallax", ParallaxNone);
        setInput("parallaxScale", 0.03f);
        setInput("parallaxBias", -0.01f);
        setInput("shadowsEnabled", true);
        setInput("shadowFilter", ShadowFilterPCF);
        setInput("fogEnabled", true);
        setInput("blending", Opaque);
        setInput("culling", true);
        setInput("colorWrite", true);
        setInput("depthWrite", true);
        setInput("particleColor", Color4f(1.0f, 1.0f, 1.0f, 1.0f));
        setInput("particleSphericalNormal", false);
        setInput("textureScale", Vector2f(1.0f, 1.0f));
        setInput("outputColor", true);
        setInput("outputNormal", true);
        setInput("outputPBR", true);
        setInput("outputEmission", true);
        setInput("diffuse2", Color4f(0.8f, 0.8f, 0.8f, 1.0f));
        setInput("diffuse3", Color4f(0.8f, 0.8f, 0.8f, 1.0f));
        setInput("diffuse4", Color4f(0.8f, 0.8f, 0.8f, 1.0f));
        
        setInput("normal2", Vector3f(0.0f, 0.0f, 1.0f));
        setInput("normal3", Vector3f(0.0f, 0.0f, 1.0f));
        setInput("normal4", Vector3f(0.0f, 0.0f, 1.0f));
        
        setInput("height2", 0.0f);
        setInput("height3", 0.0f);
        setInput("height4", 0.0f);
        
        setInput("roughness2", 0.5f);
        setInput("roughness3", 0.5f);
        setInput("roughness4", 0.5f);
        
        setInput("metallic2", 0.0f);
        setInput("metallic3", 0.0f);
        setInput("metallic4", 0.0f);
        
        setInput("textureScale2", Vector2f(1.0f, 1.0f));
        setInput("textureScale3", Vector2f(1.0f, 1.0f));
        setInput("textureScale4", Vector2f(1.0f, 1.0f));
        
        setInput("splatmap1", Color4f(1.0f, 1.0f, 1.0f, 1.0f));
        setInput("splatmap2", Color4f(0.0f, 0.0f, 0.0f, 0.0f));
        setInput("splatmap3", Color4f(0.0f, 0.0f, 0.0f, 0.0f));
        setInput("splatmap4", Color4f(0.0f, 0.0f, 0.0f, 0.0f));
    }

    final auto opDispatch(string name)() @property
    {
        return (name in inputs);
    }

    final void opDispatch(string name, T)(T value) @property
    {
        setInput(name, value);
    }

    final MaterialInput* setInput(T)(string name, T value)
    {
        MaterialInput input;
        static if (is(T == bool))
        {
            input.type = MaterialInputType.Bool;
            input.asBool = value;
        }
        else static if (is(T == int))
        {
            input.type = MaterialInputType.Integer;
            input.asInteger = value;
        }
        else static if (is(T == float) || is(T == double))
        {
            input.type = MaterialInputType.Float;
            input.asFloat = value;
        }
        else static if (is(T == Vector2f))
        {
            input.type = MaterialInputType.Vec2;
            input.asVector2f = value;
        }
        else static if (is(T == Vector3f))
        {
            input.type = MaterialInputType.Vec3;
            input.asVector3f = value;
        }
        else static if (is(T == Vector4f))
        {
            input.type = MaterialInputType.Vec4;
            input.asVector4f = value;
        }
        else static if (is(T == Color4f))
        {
            input.type = MaterialInputType.Vec4;
            input.asVector4f = value;
        }
        else static if (is(T == Texture))
        {
            input.texture = value;
            if (value.format == GL_RED)
                input.type = MaterialInputType.Float;
            else if (value.format == GL_RG)
                input.type = MaterialInputType.Vec2;
            else if (value.format == GL_RGB)
                input.type = MaterialInputType.Vec3;
            else if (value.format == GL_RGBA)
                input.type = MaterialInputType.Vec4;
        }
        else
        {
            input.type = MaterialInputType.Undefined;
        }

        inputs[name] = input;
        return (name in inputs);
    }

    final bool boolProp(string prop)
    {
        auto p = prop in inputs;
        bool res = false;
        if (p.type == MaterialInputType.Bool ||
            p.type == MaterialInputType.Integer)
        {
            res = p.asBool;
        }
        return res;
    }

    final int intProp(string prop)
    {
        auto p = prop in inputs;
        int res = 0;
        if (p.type == MaterialInputType.Bool ||
            p.type == MaterialInputType.Integer)
        {
            res = p.asInteger;
        }
        else if (p.type == MaterialInputType.Float)
        {
            res = cast(int)p.asFloat;
        }
        return res;
    }

    final Texture makeTexture(Color4f rgb, Texture alpha)
    {
        SuperImage rgbaImg = New!UnmanagedImageRGBA8(alpha.width, alpha.height);

        foreach(y; 0..alpha.height)
        foreach(x; 0..alpha.width)
        {
            Color4f col = rgb;
            col.a = alpha.image[x, y].r;
            rgbaImg[x, y] = col;
        }

        auto tex = New!Texture(rgbaImg, this);
        return tex;
    }

    final Texture makeTexture(Texture rgb, float alpha)
    {
        SuperImage rgbaImg = New!UnmanagedImageRGBA8(rgb.width, rgb.height);

        foreach(y; 0..rgb.height)
        foreach(x; 0..rgb.width)
        {
            Color4f col = rgb.image[x, y];
            col.a = alpha;
            rgbaImg[x, y] = col;
        }

        auto tex = New!Texture(rgbaImg, this);
        return tex;
    }

    final Texture makeTexture(Texture rgb, Texture alpha)
    {
        uint width = max(rgb.width, alpha.width);
        uint height = max(rgb.height, alpha.height);

        SuperImage rgbaImg = New!UnmanagedImageRGBA8(width, height);

        foreach(y; 0..rgbaImg.height)
        foreach(x; 0..rgbaImg.width)
        {
            float u = cast(float)x / cast(float)width;
            float v = cast(float)y / cast(float)height;

            Color4f col = rgb.sample(u, v);
            col.a = alpha.sample(u, v).r;

            rgbaImg[x, y] = col;
        }

        auto tex = New!Texture(rgbaImg, this);
        return tex;
    }

    final Texture makeTexture(MaterialInput r, MaterialInput g, MaterialInput b, MaterialInput a)
    {
        uint width = 8;
        uint height = 8;

        if (r.texture !is null)
        {
            width = max(width, r.texture.width);
            height = max(height, r.texture.height);
        }

        if (g.texture !is null)
        {
            width = max(width, g.texture.width);
            height = max(height, g.texture.height);
        }

        if (b.texture !is null)
        {
            width = max(width, b.texture.width);
            height = max(height, b.texture.height);
        }

        if (a.texture !is null)
        {
            width = max(width, a.texture.width);
            height = max(height, a.texture.height);
        }

        SuperImage img = New!UnmanagedImageRGBA8(width, height);

        foreach(y; 0..img.height)
        foreach(x; 0..img.width)
        {
            Color4f col = Color4f(0, 0, 0, 0);

            float u = cast(float)x / cast(float)img.width;
            float v = cast(float)y / cast(float)img.height;

            col.r = r.sample(u, v).r;
            col.g = g.sample(u, v).r;
            col.b = b.sample(u, v).r;
            col.a = a.sample(u, v).r;

            img[x, y] = col;
        }

        auto tex = New!Texture(img, this);
        return tex;
    }

    bool isTransparent()
    {
        auto iblending = "blending" in inputs;
        int b = iblending.asInteger;
        return (b == Transparent || b == Additive);
    }

    bool usesCustomShader()
    {
        return customShader;
    }

    void bind(GraphicsState* state)
    {
        auto iblending = "blending" in inputs;
        auto iculling = "culling" in inputs;
        auto icolorWrite = "colorWrite" in inputs;
        auto idepthWrite = "depthWrite" in inputs;

        if (iblending.asInteger == Transparent)
        {
            glEnablei(GL_BLEND, 0);
            glEnablei(GL_BLEND, 1);
            glEnablei(GL_BLEND, 2);
            glBlendFuncSeparatei(0, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA, GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
            glBlendFuncSeparatei(1, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA, GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
            glBlendFuncSeparatei(2, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA, GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
        }
        else if (iblending.asInteger == Additive)
        {
            glEnablei(GL_BLEND, 0);
            glEnablei(GL_BLEND, 1);
            glEnablei(GL_BLEND, 2);
            glBlendFunci(0, GL_SRC_ALPHA, GL_ONE);
            glBlendFunci(1, GL_SRC_ALPHA, GL_ONE);
            glBlendFunci(2, GL_SRC_ALPHA, GL_ONE);
        }

        if (iculling.asBool && state.culling)
        {
            glEnable(GL_CULL_FACE);
        }
        else
        {
            glDisable(GL_CULL_FACE);
        }

        if (!icolorWrite.asBool || !state.colorMask)
        {
            glColorMask(GL_FALSE, GL_FALSE, GL_FALSE, GL_FALSE);
        }

        if (!idepthWrite.asBool || !state.depthMask)
        {
            glDepthMask(GL_FALSE);
        }

        GraphicsState stateLocal = *state;
        stateLocal.material = this;

        if (state.overrideShader)
        {
            state.overrideShader.bind(&stateLocal);
        }
        else if (shader)
        {
            shader.bind(&stateLocal);
        }
    }

    void unbind(GraphicsState* state)
    {
        auto icolorWrite = "colorWrite" in inputs;
        auto idepthWrite = "depthWrite" in inputs;

        GraphicsState stateLocal = *state;
        stateLocal.material = this;

        if (state.overrideShader)
        {
            state.overrideShader.unbind(&stateLocal);
        }
        else if (shader)
        {
            shader.unbind(&stateLocal);
        }

        glDepthMask(GL_TRUE);
        glColorMask(GL_TRUE, GL_TRUE, GL_TRUE, GL_TRUE);

        glDisable(GL_CULL_FACE);

        glDisablei(GL_BLEND, 0);
        glDisablei(GL_BLEND, 1);
        glDisablei(GL_BLEND, 2);
    }
}

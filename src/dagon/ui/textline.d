/*
Copyright (c) 2017 Timur Gafarov

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

module dagon.ui.textline;

import derelict.opengl;
import derelict.freetype.ft;

import dlib.core.memory;
import dlib.math.vector;
import dlib.image.color;

import dagon.core.interfaces;
import dagon.core.ownership;
import dagon.ui.font;

enum Alignment
{
    Left,
    Right,
    Center
}

class TextLine: Owner, Drawable
{
    Font font;
    float scaling;
    Alignment alignment;
    Color4f color;
    string text;
    float width;
    float height;

    this(Font font, string text, Owner o)
    {
        super(o);
        this.font = font;
        this.text = text;
        this.scaling = 1.0f;
        this.width = font.width(text);
        this.height = font.height;
        this.alignment = Alignment.Left;
        this.color = Color4f(0, 0, 0);
    }

    override void update(double dt)
    {
    }

    override void render(RenderingContext* rc)
    {
        glEnable(GL_BLEND);
        glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
        font.render(rc, color, text);
        glDisable(GL_BLEND);
    }

    void setFont(Font font)
    {
        this.font = font;
        this.width = font.width(text);
        this.height = font.height;
    }

    void setText(string t)
    {
        this.text = t;
        this.width = font.width(t);
    }
}


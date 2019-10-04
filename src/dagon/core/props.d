/*
Copyright (c) 2016-2019 Timur Gafarov 

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

module dagon.core.props;

import std.stdio;
import std.ascii;
import std.conv;
import dlib.core.memory;
import dlib.core.ownership;
import dlib.container.array;
import dlib.container.dict;
import dlib.text.utils;
import dlib.math.vector;
import dlib.image.color;
import dlib.text.lexer;

enum DPropType
{
    Undefined,
    Number,
    Vector,
    String
}

struct DProperty
{
    DPropType type;
    string name;
    string data;

    string toString()
    {
        return data;
    }

    double toDouble()
    {
        return to!double(data);
    }

    float toFloat()
    {
        return to!float(data);
    }

    int toInt()
    {
        return to!int(data);
    }
    
    int toUInt()
    {
        return to!uint(data);
    }

    bool toBool()
    {
        return cast(bool)cast(int)(to!float(data));
    }

    Vector3f toVector3f()
    {
        return Vector3f(data);
    }

    Vector4f toVector4f()
    {
        return Vector4f(data);
    }

    Color4f toColor4f()
    {
        return Color4f(Vector4f(data));
    }
}

class Properties: Owner
{
    Dict!(DProperty, string) props;
    
    this(Owner o)
    {
        super(o);
        props = dict!(DProperty, string);
    }
    
    bool parse(string input)
    {
        return parseProperties(input, this);
    }
    
    DProperty opIndex(string name)
    {
        if (name in props)
            return props[name];
        else
            return DProperty(DPropType.Undefined, "");
    }

    void set(DPropType type, string name, string value)
    {
        auto p = name in props;
        if (p)
        {
            Delete(p.name);
            Delete(p.data);
            auto nameCopy = copyStr(name);
            auto valueCopy = copyStr(value);
            props[nameCopy] = DProperty(type, nameCopy, valueCopy);
        }
        else
        {
            auto nameCopy = copyStr(name);
            auto valueCopy = copyStr(value);
            props[nameCopy] = DProperty(type, nameCopy, valueCopy);
        }
    }

    DProperty opDispatch(string s)()
    {
        if (s in props)
            return props[s];
        else
            return DProperty(DPropType.Undefined, "");
    }
    
    DProperty* opBinaryRight(string op)(string k) if (op == "in")
    {
        return (k in props);
    }

    void remove(string name)
    {
        if (name in props)
        {
            auto n = props[name].name;
            Delete(props[name].data);
            props.remove(name);
            Delete(n);
        }
    }
    
    int opApply(int delegate(string, ref DProperty) dg)
    {
        foreach(k, v; props)
        {
            dg(k, v);
        }

        return 0;
    }
    
    ~this()
    {
        foreach(k, v; props)
        {
            Delete(v.data);
            Delete(v.name);
        }
        Delete(props);
    }
}

bool isWhiteStr(string s)
{
    bool res;
    foreach(c; s)
    {
        res = false;
        foreach(w; std.ascii.whitespace)
        {
            if (c == w)
                res = true;
        }
        
        if (c == '\n' || c == '\r')
            res = true;
    }
    return res;
}

bool isValidIdentifier(string s)
{
    return (isAlpha(s[0]) || s[0] == '_');
}

string copyStr(T)(T[] s)
{
    auto res = New!(char[])(s.length);
    foreach(i, c; s)
        res[i] = c;
    return cast(string)res;
}

bool parseProperties(string input, Properties props)
{
    enum Expect
    {
        PropName,
        Colon,
        Semicolon,
        Value,
        String,
        Vector,
        Number
    }

    bool res = true;
    auto lexer = New!Lexer(input, [":", ";", "\"", "[", "]", ","]);
    
    lexer.ignoreNewlines = true;
    
    Expect expect = Expect.PropName;
    string propName;
    DynamicArray!char propValue;
    DPropType propType;
    
    while(true)
    {
        auto lexeme = lexer.getLexeme();
        if (lexeme.length == 0) 
        {
            if (expect != Expect.PropName)
            {
                writefln("Error: unexpected end of string");
                res = false;
            }
            break;
        }
        
        if (isWhiteStr(lexeme) && expect != Expect.String)
            continue;
        
        if (expect == Expect.PropName)
        {
            if (!isValidIdentifier(lexeme))
            {
                writefln("Error: illegal identifier name \"%s\"", lexeme);
                res = false;
                break;
            }
            
            propName = lexeme;
            expect = Expect.Colon;
        }
        else if (expect == Expect.Colon)
        {
            if (lexeme != ":")
            {
                writefln("Error: expected \":\", got \"%s\"", lexeme);
                res = false;
                break;
            }
            
            expect = Expect.Value;
        }
        else if (expect == Expect.Semicolon)
        {
            if (lexeme != ";")
            {
                writefln("Error: expected \";\", got \"%s\"", lexeme);
                res = false;
                break;
            }
            
            props.set(propType, propName, cast(string)propValue.data);
            
            expect = Expect.PropName;
            propName = "";
            propValue.free();
        }
        else if (expect == Expect.Value)
        {
            if (lexeme == "\"")
            {
                propType = DPropType.String;
                expect = Expect.String;
            }
            else if (lexeme == "[")
            {
                propType = DPropType.Vector;
                expect = Expect.Vector;
                propValue.append(lexeme);
            }
            else
            {
                propType = DPropType.Number;
                propValue.append(lexeme);
                expect = Expect.Semicolon;
            }
        }
        else if (expect == Expect.String)
        {
            if (lexeme == "\"")
                expect = Expect.Semicolon;
            else
                propValue.append(lexeme);
        }
        else if (expect == Expect.Vector)
        {
            if (lexeme == "]")
                expect = Expect.Semicolon;

            propValue.append(lexeme);
        }
    }
    
    propValue.free();
    Delete(lexer);

    return res;
}

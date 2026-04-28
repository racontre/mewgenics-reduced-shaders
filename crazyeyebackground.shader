#version 150
#include "std_in.shader"

uniform sampler2D eyes1;
uniform sampler2D eyes2;
uniform sampler2D eyes3;

uniform float timer;
const float timescale = .2;

uniform vec3 eye_weights;

struct vertex {
    vec4 color;
    vec4 texcoord;
    vec2 screencoord;
};


#if COMPILING_VERTEX_PROGRAM
    out vertex v;

    void vert(){
        v.color = color;
        v.texcoord = texcoord;
        gl_Position = mvp * vec4(position.xy, 0.0, 1.0);
        v.texcoord.xy = (gl_Position.xy+vec2(1, 1))*.5;
        //v.screencoord = (gl_Position.xy+vec2(1, 1))*.5; //sample calculation if using odd shapes or ignoring texture coordinates
    } 
#elif COMPILING_FRAGMENT_PROGRAM
    in vertex v;
    out vec4 frag_color;

    float mip_level(in vec2 texcoord, in vec2 texsize) {
        vec2 ddx = dFdx(texcoord*texsize);
        vec2 ddy = dFdy(texcoord*texsize);
        float miplevel = 0.5 * log2(max(dot(ddx, ddx), dot(ddy, ddy))) - 0.5; //-.5 is the mipmap bias
        return miplevel;
    }

    int rmod (int a, int b){
        return (a%b+b)%b;
    }
    int frmod (float a, float b){
        return int(a - floor(a/b)*b);
    }

    vec4 offset_tex(sampler2D sampler, vec2 uv, vec2 radial_hint) {
        float mip = mip_level(radial_hint.yy, textureSize(sampler, 0));

        uv.y += floor(uv.x)*3/5;
        if(frmod((floor(uv.x)), 3) == 0) uv.y -= timer*timescale*.66666;
        if(frmod((floor(uv.x)), 3) == 1) uv.y -= timer*timescale*.33333;

        return textureLod(sampler, uv, mip);
    }

    void frag(){
        float waviness = sin(timer*timescale);
        vec2 rv = (v.texcoord.xy - vec2(.5, .8)) * vec2(16, 9) / 9;
        float fade = length(rv)*length(rv)*24;
        fade = clamp(fade, 0, 1);

        vec2 radial = vec2(atan(rv.y, rv.x), length(rv));
        vec2 original_radial = radial;
        radial.x /= 3.1415926535897932384626433832795*2;
        radial.x += sin(radial.y*20)*.002*waviness / radial.y;
        radial.x += radial.y * -.4;

 
        //projection
        radial.y = -sqrt(radial.y);
        //radial.y = .5 / (radial.y+.2);

        radial.y -= timer*timescale * .2;
        radial.x += timer*timescale * .02;

        frag_color = 
              offset_tex(eyes1, radial.xy * vec2(15, 2), radial * vec2(15, 2)) * eye_weights.x
            + offset_tex(eyes2, radial.xy * vec2(15, 2), radial * vec2(15, 2)) * eye_weights.y
            + offset_tex(eyes3, radial.xy * vec2(15, 2), radial * vec2(15, 2)) * eye_weights.z
        ;

        frag_color.rgb *= fade;
    }
#endif

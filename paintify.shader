#version 150
#include "std_in.shader"

uniform sampler2D framebuf;
uniform sampler2D brush;
uniform sampler2D overlay;

struct vertex {
    vec4 color;
    vec4 texcoord;
};


#if COMPILING_VERTEX_PROGRAM
    out vertex v;

    void vert(){
        v.color = color;
        v.texcoord = texcoord;
        gl_Position = mvp * vec4(position.xy, 0.0, 1.0);
    } 

#elif COMPILING_FRAGMENT_PROGRAM
    in vertex v;
    out vec4 frag_color;

    void frag(){
        vec2 ratio = vec2(16, 9);

        float brushcolorx = texture(brush, v.texcoord.xy * ratio * .5).r;
        float brushcolory = texture(brush, v.texcoord.xy * ratio * .5 + vec2(.5, .5)).r;

        vec4 maincolor = texture(framebuf, v.texcoord.xy + vec2(brushcolorx-.5, brushcolory-.5) / (ratio/16) * .0005);
        vec4 overlaycolor = texture(overlay, v.texcoord.xy * ratio * .25);

        frag_color = maincolor * mix(vec4(1,1,1,1), overlaycolor, .5);
    }

#endif

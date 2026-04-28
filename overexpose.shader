#version 150
#include "std_in.shader"

uniform sampler2D framebuf;
uniform vec3 exposure;

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
        vec4 col = texture(framebuf, v.texcoord.xy);
        col.rgb *= exposure;

        frag_color = col;
    }

#endif

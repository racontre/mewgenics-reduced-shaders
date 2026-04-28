#version 150
#include "std_in.shader"

uniform sampler2D framebuf;
uniform sampler2D distortion;

struct vertex
{
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
	return;
        vec4 distort = texture(distortion, v.texcoord.xy);
        vec4 buf = texture(framebuf, v.texcoord.xy + distort.xy);

        //frag_color = vec4(distort.rgb*.5+vec3(0.5, 0.5, 0.5),1);
        frag_color = vec4(buf.rgb,1);
    }

#endif

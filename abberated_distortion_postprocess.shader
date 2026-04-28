#version 150
#include "std_in.shader"

// loaded in the throbbing domain. Fills the entire screen with something

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
	//frag_color = vec4(0.0, 1.0, 1.0, 1.0);
	return;
        vec4 distort = texture(distortion, v.texcoord.xy);
        float abberation = clamp(distort.z, 0.0, 1.0) * .1;

        float bufr = texture(framebuf, v.texcoord.xy - distort.xy*(1.0-abberation*2.0)).r;
        float bufg = texture(framebuf, v.texcoord.xy - distort.xy*(1.0-abberation*1.0)).g;
        float bufb = texture(framebuf, v.texcoord.xy - distort.xy*(1.0-abberation*0.0)).b;

        //frag_color = vec4(distort.rgb*.5*255.0+vec3(0.5, 0.5, 0.5),1);
        //frag_color.b = .5;
        frag_color = vec4(bufr, bufg, bufb, 1);
    }

#endif

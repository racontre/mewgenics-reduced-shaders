#version 150
#include "swf_lib.shader"

uniform vec4 ring_info;

#if COMPILING_VERTEX_PROGRAM

    void vert(){
        v.color = color;
        v.texcoord = texcoord;
        v.color_xform = color_xform;
        gl_Position = mvp * vec4(position.xy, 0.0, 1.0);
    }
    
#elif COMPILING_FRAGMENT_PROGRAM

    void frag(){
        float radius = ring_info.x;
		float width = ring_info.y;
		float strength = ring_info.z;
        float abberation = ring_info.w;

        vec2 vec = v.texcoord.xy;
        float l = (length(vec) - radius) / width;
        float power = exp(1.0-l*l);
        vec = normalize(vec)*power * strength * power;
        vec.y *= .5;

        frag_color = vec4(vec.x, vec.y, abberation, 1.0) * v.color * v.color_xform[0] + v.color_xform[1];
    }
    
#endif

#version 150
#include "std_in.shader"

uniform float vignette_strength_relative;

struct vertex {
    vec4 color;
    vec4 texcoord;
};


#if COMPILING_VERTEX_PROGRAM
    out vertex v;
    out float vignette_strength;

    void vert(){
        v.color = color;
        v.texcoord = texcoord;

        gl_Position = mvp * vec4(position.xy, 0.0, 1.0);

        vignette_strength = (1.0-vignette_strength_relative) * .8;
    } 

#elif COMPILING_FRAGMENT_PROGRAM
    in vertex v;
    in float vignette_strength;
    out vec4 frag_color;

    void frag(){
        vec2 center_vector = (v.texcoord.xy - vec2(.5,.5))*vec2(1.0, 1.0);
        float center_distance = length(center_vector)*2; //0 at center, 1 at edge, sqrt(2) at corner
        float vignetting = 1.5-center_distance;
        vignetting = mix(1, vignetting, vignette_strength);
        vignetting = clamp(vignetting, 0, 1);

        frag_color = vec4(vignetting, vignetting, vignetting , 1);
    }

#endif

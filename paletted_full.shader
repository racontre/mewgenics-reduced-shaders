#version 150
#include "swf_lib.shader"

uniform sampler2D palettemap;
uniform int palette;

#if COMPILING_VERTEX_PROGRAM

    void vert(){
        defaultvertfunc();
    }
    
#elif COMPILING_FRAGMENT_PROGRAM

    void frag(){

        vec4 outcolor = compute_color_full(v);
        vec4 palettechoice = texelFetch(palettemap, ivec2((outcolor.r*15.0+.5), palette), 0);
        if(!(abs(outcolor.x - outcolor.y) < .001 && abs(outcolor.x - outcolor.z) < .001)) {
            palettechoice = outcolor;
        }

        frag_color = vec4(palettechoice.xyz, outcolor.w) * v.color_xform[0] + v.color_xform[1];
        bias_depth();
        
    }
    
#endif

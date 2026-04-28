#version 150
#include "swf_lib.shader"

#if COMPILING_VERTEX_PROGRAM

    void vert(){
        defaultvertfunc();
    }
    
#elif COMPILING_FRAGMENT_PROGRAM

    void frag(){
	return;
        vec4 outcolor = compute_color_full(v);
        outcolor.a = outcolor.a * v.color_xform[0].a + v.color_xform[1].a;
        outcolor.rg = (outcolor.rg - .5) * 2 * outcolor.b * outcolor.a;
        outcolor.b = 1;
        outcolor.a = 1;
        frag_color = outcolor;
        bias_depth();
    }
    
#endif

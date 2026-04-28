#version 150
#include "swf_lib.shader"

// This shader is used to draw fonts and ui elements, such as ability icons.
// Seemingly no significant performance impact.

#if COMPILING_VERTEX_PROGRAM

    void vert(){
        v.color = color * color_xform[0] + color_xform[1];
        gl_Position = mvp * vec4(position.xy, 0.0, 1.0);
        v.depth_bias = depth_bias;
    }
    
#elif COMPILING_FRAGMENT_PROGRAM

    void frag(){
        frag_color = v.color;
//	frag_color = vec4(1.0, 0.0, 0.0, 1.0);
        bias_depth();
    }
    
#endif
